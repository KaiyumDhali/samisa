<?php

namespace App\Services;

use App\Models\MonthlySalary;
use App\Models\Overtime;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class OvertimeService
{
    public const HEAD_NAME = 'Over Time';
    public const DEFAULT_RATE_FORMULA = '{Basic Salary}/208*2';

    /** Current settings (falls back to defaults if the table is empty). */
    public function settings(): object
    {
        $row = DB::table('overtime_settings')->orderByDesc('id')->first();
        return $row ?: (object) [
            'mode' => 'auto_review',
            'min_minutes' => 30,
            'round_minutes' => 15,
            'max_hours_per_day' => 2,
            'holiday_max_hours' => 8,
            'count_holiday_work' => 1,
        ];
    }

    /** A month is locked once its salary is approved. */
    public function isLocked(string $month): bool
    {
        return MonthlySalary::where('salary_month', $month)->where('status', 1)->exists();
    }

    /** Hourly overtime rate from the "Over Time" payroll formula. */
    public function ratePerHour(float $gross): float
    {
        $headId = DB::table('payroll_heads')->where('name', self::HEAD_NAME)->where('status', 1)->value('id');
        $formula = $headId
            ? DB::table('payroll_formulas')->where('payroll_head', $headId)->where('status', 1)->value('formula')
            : null;

        $calc = new PayrollCalculator();
        try {
            return $calc->evaluateFormula($formula ?: self::DEFAULT_RATE_FORMULA, $gross);
        } catch (\Throwable $e) {
            return $calc->evaluateFormula(self::DEFAULT_RATE_FORMULA, $gross);
        }
    }

    public function rateForEmployee(int $employeeId): float
    {
        $gross = (float) DB::table('emp_postings')->where('employee_id', $employeeId)->orderByDesc('id')->value('gross_salary');
        return $this->ratePerHour($gross);
    }

    /**
     * Build overtime rows from attendance for one month.
     * Only employees with over_time = 1 (Active) are processed.
     * Manual rows, approved rows and rejected rows are never overwritten.
     */
    public function generate(string $month, ?int $onlyEmployeeId = null, int $userId = 0): array
    {
        $s = $this->settings();
        if ($s->mode === 'manual') {
            throw new \RuntimeException('Overtime mode is "Manual only". Change the mode in Settings to generate from attendance.');
        }
        if ($this->isLocked($month)) {
            throw new \RuntimeException('Salary for this month is already approved. Overtime cannot be changed.');
        }

        $start = Carbon::parse($month . '-01')->startOfDay();
        $end = $start->copy()->endOfMonth();
        $officeEnd = DB::table('work_times')->orderByDesc('id')->value('end_time') ?: '17:00:00';

        $weekend = DB::table('weekend_days')->pluck('weekend_day')
            ->map(fn ($d) => strtolower(trim($d)))->all();
        $holidays = $this->holidayDates($start, $end);

        $employees = DB::table('employees')
            ->where('status', 1)
            ->where('over_time', 1)
            ->when($onlyEmployeeId, fn ($q) => $q->where('id', $onlyEmployeeId))
            ->where(function ($q) use ($start) {
                $q->whereNull('quite_date')->orWhere('quite_date', '>=', $start->toDateString());
            })
            ->get(['id', 'employee_code']);

        $status = $s->mode === 'auto_approve' ? 'approved' : 'draft';
        $minMinutes = (int) $s->min_minutes;
        $round = max(1, (int) $s->round_minutes);

        $result = [
            'employees' => $employees->count(),
            'created' => 0,
            'updated' => 0,
            'skipped_existing' => 0,
            'missing_punch' => 0,
            'removed' => 0,
        ];

        foreach ($employees as $e) {
            if (empty($e->employee_code)) {
                continue;
            }

            $days = DB::table('attendances')
                ->where('employee_code', (int) $e->employee_code)
                ->whereBetween('date_only_record', [$start->toDateString(), $end->toDateString()])
                ->groupBy('date_only_record')
                ->select(
                    'date_only_record',
                    DB::raw('MIN(date_time_record) as first_punch'),
                    DB::raw('MAX(date_time_record) as last_punch'),
                    DB::raw('COUNT(*) as punches')
                )
                ->get();

            $keep = [];

            foreach ($days as $d) {
                $date = Carbon::parse($d->date_only_record)->toDateString();
                $first = Carbon::parse($d->first_punch);
                $last = Carbon::parse($d->last_punch);
                $isOff = isset($holidays[$date]) || in_array(strtolower(Carbon::parse($date)->format('l')), $weekend);

                // A single punch means the out time is missing: cannot calculate.
                if ((int) $d->punches < 2) {
                    if ($isOff) {
                        $result['missing_punch']++;
                    }
                    continue;
                }

                if ($isOff) {
                    if (!$s->count_holiday_work) {
                        continue;
                    }
                    $minutes = $first->diffInMinutes($last);
                    $cap = (float) $s->holiday_max_hours * 60;
                } else {
                    // minutes worked after office end time (negative if left early)
                    $minutes = Carbon::parse($date . ' ' . $officeEnd)->diffInMinutes($last, false);
                    $cap = (float) $s->max_hours_per_day * 60;
                }

                if ($minutes < $minMinutes || $minutes <= 0) {
                    continue;
                }

                $minutes = floor(min($minutes, $cap) / $round) * $round;
                if ($minutes <= 0) {
                    continue;
                }
                $hours = round($minutes / 60, 2);

                $existing = Overtime::where('employee_id', $e->id)->where('work_date', $date)->first();

                if ($existing) {
                    if ($existing->source === 'auto' && $existing->status === 'draft') {
                        $existing->update([
                            'hours' => $hours,
                            'punch_in' => $first->format('H:i:s'),
                            'punch_out' => $last->format('H:i:s'),
                            'status' => $status,
                            'approved_by' => $status === 'approved' ? ($userId ?: null) : null,
                            'approved_at' => $status === 'approved' ? now() : null,
                        ]);
                        $keep[] = $date;
                        $result['updated']++;
                    } else {
                        $result['skipped_existing']++;
                    }
                    continue;
                }

                Overtime::create([
                    'employee_id' => $e->id,
                    'overtime_month' => $month,
                    'work_date' => $date,
                    'source' => 'auto',
                    'status' => $status,
                    'punch_in' => $first->format('H:i:s'),
                    'punch_out' => $last->format('H:i:s'),
                    'approved_by' => $status === 'approved' ? ($userId ?: null) : null,
                    'approved_at' => $status === 'approved' ? now() : null,
                    'title' => $isOff ? 'Auto: weekend/holiday work' : 'Auto: after office hours',
                    'number_of_days' => 1,
                    'hours' => $hours,
                    'rate' => null,
                    'created_by' => $userId,
                ]);
                $keep[] = $date;
                $result['created']++;
            }

            // Remove old auto drafts that no longer match attendance
            $stale = Overtime::where('employee_id', $e->id)
                ->where('overtime_month', $month)
                ->where('source', 'auto')
                ->where('status', 'draft');
            if (!empty($keep)) {
                $stale->whereNotIn('work_date', $keep);
            }
            $result['removed'] += $stale->delete();
        }

        return $result;
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
}