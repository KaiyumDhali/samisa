<?php

namespace App\Services;

use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Ekjon employee-er ekta mash-er salary hishab kore.
 *
 *  - Basic            : emp_postings.gross_salary (latest)
 *  - Payroll heads    : payrolls + payroll_formulas ({Basic Salary} placeholder)
 *  - Attendance       : attendances (machine punch), weekend_days, holidays, approved leave
 *  - Absent deduction : gross / days-in-month * absent days
 *  - Joining/quit     : jei din job-e chhilo na, sei dinguloy proportionate kata
 *  - Loan             : loans (amount / mash sonkha) installment
 *
 * Late-er jonno taka kata hoy na; late_leave_policies onujayi leave balance theke kata hoy.
 */
class PayrollCalculator
{
    public const ATTENDANCE_BONUS_HEAD = 'Attendance Bonus';
    public const OVERTIME_HEAD = 'Over Time';

    // Overtime rate khali thakle: (gross / OVERTIME_MONTH_DAYS / OVERTIME_DAY_HOURS) x OVERTIME_MULTIPLIER
    public const OVERTIME_MONTH_DAYS  = 30;
    public const OVERTIME_DAY_HOURS   = 8;
    public const OVERTIME_MULTIPLIER  = 2;

    public function calculate(int $employeeId, string $month): array
    {
        $monthStart = Carbon::parse($month . '-01')->startOfDay();
        $monthEnd   = $monthStart->copy()->endOfMonth()->startOfDay();
        $daysInMonth = $monthStart->daysInMonth;

        $employee = DB::table('employees')->where('id', $employeeId)->first();
        $posting  = DB::table('emp_postings')->where('employee_id', $employeeId)->orderByDesc('id')->first();
        $gross    = (float) ($posting->gross_salary ?? 0);

        // Job period (joining / quit)
        $periodStart = $monthStart->copy();
        if (!empty($posting->joining_date) && Carbon::parse($posting->joining_date)->gt($periodStart)) {
            $periodStart = Carbon::parse($posting->joining_date)->startOfDay();
        }
        $periodEnd = $monthEnd->copy();
        if (!empty($employee->quite_date) && Carbon::parse($employee->quite_date)->lt($periodEnd)) {
            $periodEnd = Carbon::parse($employee->quite_date)->startOfDay();
        }
        $employedDays = $periodEnd->gte($periodStart) ? $periodStart->diffInDays($periodEnd) + 1 : 0;

        // Weekend / holiday / attendance / leave
        $weekendNames = DB::table('weekend_days')->pluck('weekend_day')
            ->map(fn ($d) => strtolower(trim($d)))->all();

        $holidays = $this->holidayDates($monthStart, $monthEnd);

        $presentDates = [];
        if (!empty($employee->employee_code)) {
            $presentDates = DB::table('attendances')
                ->where('employee_code', (int) $employee->employee_code)
                ->whereBetween('date_only_record', [$monthStart->toDateString(), $monthEnd->toDateString()])
                ->distinct()->pluck('date_only_record')
                ->map(fn ($d) => Carbon::parse($d)->toDateString())->flip()->all();
        }

        $leaveDates = $this->approvedLeaveDates($employeeId, $monthStart, $monthEnd);
                // Approved Out of Office days count as present; HR "Mark as Absent" days count as absent
        [$ooDates, $absDates] = $this->attendanceExceptionDates($employeeId, $monthStart, $monthEnd);
        foreach ($absDates as $d => $_) {
            if (!isset($ooDates[$d])) {
                unset($presentDates[$d], $leaveDates[$d]);
            }
        }
        $presentDates = $presentDates + $ooDates;

        $r = $this->classifyDays(
            $periodStart, $periodEnd, $weekendNames, $holidays, $presentDates, $leaveDates
        );

        $perDay = $daysInMonth > 0 ? $gross / $daysInMonth : 0;

        // Payroll heads (income / deduction)
        $rows = [];
        $totalIncome = 0.0;
        $totalDeduction = 0.0;

        $headIds = DB::table('payrolls')->where('employee_id', $employeeId)
            ->whereDate('effective_date', '<=', $monthEnd->toDateString())
            ->pluck('payroll_head_id')->unique();

        foreach ($headIds as $headId) {
            $head = DB::table('payroll_heads')->where('id', $headId)->where('status', 1)->first();
            $formula = DB::table('payroll_formulas')->where('payroll_head', $headId)->where('status', 1)->first();
            if (!$head || !$formula) {
                continue;
            }
            // Over Time: formula (% of basic) noy, overtime entry theke hishab hoy (niche)
            if ($head->name === self::OVERTIME_HEAD) {
                continue;
            }
            // Attendance bonus: ekdin-o absent thakle pabe na
            if ($head->name === self::ATTENDANCE_BONUS_HEAD && $r['absent_days'] > 0) {
                continue;
            }
            $amount = $this->evaluateFormula($formula->formula, $gross);
            if ($amount <= 0) {
                continue;
            }
            $rows[] = ['head_id' => $head->id, 'head_name' => $head->name, 'head_type' => $head->type, 'amount' => $amount];
            $head->type === 'Income' ? $totalIncome += $amount : $totalDeduction += $amount;
        }

        // Overtime (overtimes table, mash onujayi)
        $overtimeAmount = $this->overtimeAmount($employeeId, $month, $gross);
        if ($overtimeAmount > 0) {
            $rows[] = ['head_id' => 0, 'head_name' => self::OVERTIME_HEAD, 'head_type' => 'Income', 'amount' => $overtimeAmount];
            $totalIncome += $overtimeAmount;
        }

        // Absent deduction
        $absentDeduction = round($perDay * $r['absent_days'], 2);
        if ($absentDeduction > 0) {
            $rows[] = ['head_id' => 0, 'head_name' => 'Absent Deduction', 'head_type' => 'Deduction', 'amount' => $absentDeduction];
            $totalDeduction += $absentDeduction;
        }

        // Joining / quit mash-er age-pore-er din
        $notEmployedDays = $daysInMonth - $employedDays;
        $prorationDeduction = round($perDay * $notEmployedDays, 2);
        if ($prorationDeduction > 0) {
            $rows[] = ['head_id' => 0, 'head_name' => 'Not Employed Days', 'head_type' => 'Deduction', 'amount' => $prorationDeduction];
            $totalDeduction += $prorationDeduction;
        }

        // Loan installment
        $loanInstallment = $this->loanInstallment($employeeId, $monthStart, $monthEnd);
        if ($loanInstallment > 0) {
            $rows[] = ['head_id' => 0, 'head_name' => 'Loan Installment', 'head_type' => 'Deduction', 'amount' => $loanInstallment];
            $totalDeduction += $loanInstallment;
        }

        $net = round($gross + $totalIncome - $totalDeduction, 2);

        return [
            'basic_salary'   => $gross,
            'income'         => round($totalIncome, 2),
            'deduction'      => round($totalDeduction, 2),
            'net_payble'     => max($net, 0),
            'working_days'   => $r['working_days'],
            'present_days'   => $r['present_days'],
            'leave_days'     => $r['leave_days'],
            'absent_days'    => $r['absent_days'],
            'rows'           => $rows,
            'warnings'       => $net < 0 ? ['Net salary negative, 0 kora holo'] : [],
        ];
    }

    /**
     * Pure function (DB chhara) — testable.
     * Shudhu working din (weekend/holiday bade) gonona hoy.
     */
    public function classifyDays(Carbon $start, Carbon $end, array $weekendNames, array $holidays, array $presentDates, array $leaveDates): array
    {
        $working = $present = $leave = $absent = 0;
        if ($end->lt($start)) {
            return ['working_days' => 0, 'present_days' => 0, 'leave_days' => 0, 'absent_days' => 0];
        }
        for ($d = $start->copy(); $d->lte($end); $d->addDay()) {
            $key = $d->toDateString();
            if (in_array(strtolower($d->format('l')), $weekendNames, true) || isset($holidays[$key])) {
                continue;
            }
            $working++;
            if (isset($presentDates[$key])) {
                $present++;
            } elseif (isset($leaveDates[$key])) {
                $leave++;
            } else {
                $absent++;
            }
        }
        return ['working_days' => $working, 'present_days' => $present, 'leave_days' => $leave, 'absent_days' => $absent];
    }

    /** Shudhu number + - * / ( ) allowed; kono code chalano jabe na. */
    public function evaluateFormula(string $formula, float $basic): float
    {
        $expr = str_replace('{Basic Salary}', (string) $basic, $formula);
        if (!preg_match('/^[0-9\.\+\-\*\/\(\)\s]+$/', $expr)) {
            throw new \InvalidArgumentException("Invalid payroll formula: {$formula}");
        }
        return round((float) eval('return ' . $expr . ';'), 2);
    }

    private function holidayDates(Carbon $from, Carbon $to): array
    {
        $out = [];
        $rows = DB::table('holidays')
            ->whereDate('date', '<=', $to->toDateString())
            ->whereDate('end_date', '>=', $from->toDateString())->get();
        foreach ($rows as $h) {
            $s = Carbon::parse($h->date)->max($from);
            $e = Carbon::parse($h->end_date)->min($to);
            for ($d = $s->copy(); $d->lte($e); $d->addDay()) {
                $out[$d->toDateString()] = true;
            }
        }
        return $out;
    }


        /** Dates marked Out of Office (present) or Absent by HR in the exceptions table. */
    private function attendanceExceptionDates(int $employeeId, Carbon $from, Carbon $to): array
    {
        $oo = [];
        $abs = [];
        $rows = DB::table('employee_delayin_earlyouts')
            ->where('employee_id', $employeeId)
            ->whereBetween('date', [$from->toDateString(), $to->toDateString()])
            ->whereIn('status', ['out_of_office', 'absences'])
            ->get(['date', 'status']);

        foreach ($rows as $r) {
            $key = Carbon::parse($r->date)->toDateString();
            if ($r->status === 'out_of_office') {
                $oo[$key] = true;
            } else {
                $abs[$key] = true;
            }
        }
        return [$oo, $abs];
    }

    /** Approved (final_status=1) leave; "Monthly Late Leave" bad (ota present-er din-er upor katа hoy). */
    private function approvedLeaveDates(int $employeeId, Carbon $from, Carbon $to): array
    {
        $out = [];
        $rows = DB::table('employee_leave_entries')
            ->where('employee_id', $employeeId)
            ->where('final_status', 1)
            ->whereNotNull('leave_start_date')
            ->where(function ($q) {
                $q->whereNull('remarks')->orWhere('remarks', '!=', 'Monthly Late Leave');
            })->get();
        foreach ($rows as $l) {
            if (empty($l->leave_start_date)) {
                continue;
            }
            $s = Carbon::parse($l->leave_start_date)->startOfDay();
            $e = Carbon::parse($l->leave_end_date ?: $l->leave_start_date)->startOfDay();
            if ($e->lt($from) || $s->gt($to)) {
                continue;
            }
            for ($d = $s->max($from)->copy(); $d->lte($e->min($to)); $d->addDay()) {
                $out[$d->toDateString()] = true;
            }
        }
        return $out;
    }

    /**
     * Overtime = sum(number_of_days x hours x rate). rate na thakle gross theke auto rate.
     */
   private function overtimeAmount(int $employeeId, string $month, float $gross): float
    {
        $autoRate = (new OvertimeService())->ratePerHour($gross);

        $rows = DB::table('overtimes')
            ->where('employee_id', $employeeId)
            ->where('overtime_month', $month)
            ->where(function ($q) {
                $q->whereNull('status')->orWhere('status', 'approved');
            })
            ->get();

        $sum = 0.0;
        foreach ($rows as $o) {
            $rate = (float) $o->rate > 0 ? (float) $o->rate : $autoRate;
            $sum += (float) $o->number_of_days * (float) $o->hours * $rate;
        }
        return round($sum, 2);
    }

    /** loans.amount ke start..end mash sonkha diye bhag (percentage ignore kora hoyeche). */
    private function loanInstallment(int $employeeId, Carbon $from, Carbon $to): float
    {
        $sum = 0.0;
        $loans = DB::table('loans')->where('employee_id', $employeeId)
            ->whereDate('start_date', '<=', $to->toDateString())
            ->whereDate('end_date', '>=', $from->toDateString())->get();
        foreach ($loans as $l) {
            $s = Carbon::parse($l->start_date)->startOfMonth();
            $e = Carbon::parse($l->end_date)->startOfMonth();
            $months = max(1, $s->diffInMonths($e) + 1);
            $sum += (float) $l->amount / $months;
        }
        return round($sum, 2);
    }
}