<?php

namespace App\Http\Controllers\Payroll;

use App\Http\Controllers\Controller;
use App\Models\Overtime;
use App\Models\OvertimeSetting;
use App\Services\OvertimeService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

/**
 * Overtime management
 *   - Eligible employees (employees.over_time = 1)
 *   - Auto generation from attendance (draft -> HR approves) or manual entry
 *   - Only "approved" rows are paid (see PayrollCalculator::overtimeAmount)
 */
class OvertimeController extends Controller
{
    private OvertimeService $service;

    public function __construct()
    {
        $this->service = new OvertimeService();
        $this->middleware('permission:read monthly salary|write monthly salary|create monthly salary', ['only' => ['index']]);
        $this->middleware('permission:create monthly salary', ['only' => ['store', 'generate']]);
        $this->middleware('permission:write monthly salary', ['only' => ['update', 'destroy', 'bulkStatus', 'settings', 'eligibility']]);
    }

    public function index(Request $request)
    {
        $month = $this->cleanMonth($request->get('month'), now()->subMonth()->format('Y-m'));
        $settings = $this->service->settings();
        $locked = $this->service->isLocked($month);

        $overtimes = Overtime::with('employee:id,employee_name,employee_code')
            ->where('overtime_month', $month)
            ->orderBy('work_date')->orderBy('employee_id')->get();

        // hourly rate per employee, used for the amount preview
        $rates = [];
        foreach ($overtimes->pluck('employee_id')->unique() as $empId) {
            $rates[$empId] = $this->service->rateForEmployee((int) $empId);
        }

        $draftCount = 0;
        $approvedHours = 0;
        $approvedAmount = 0;
        foreach ($overtimes as $o) {
            $rate = (float) $o->rate > 0 ? (float) $o->rate : ($rates[$o->employee_id] ?? 0);
            $hours = (float) $o->number_of_days * (float) $o->hours;
            $o->calc_rate = $rate;
            $o->calc_hours = $hours;
            $o->calc_amount = round($hours * $rate, 2);
            if ($o->status === 'draft') {
                $draftCount++;
            }
            if ($o->status === 'approved') {
                $approvedHours += $hours;
                $approvedAmount += $o->calc_amount;
            }
        }

        $allEmployees = DB::table('employees')->where('status', 1)->orderBy('order')
            ->get(['id', 'employee_code', 'employee_name', 'over_time']);
        $eligible = $allEmployees->where('over_time', 1)->values();

        return view('pages.payroll.overtime.index', compact(
            'overtimes', 'month', 'locked', 'settings', 'draftCount',
            'approvedHours', 'approvedAmount', 'allEmployees', 'eligible'
        ));
    }

    /** Manual entry (one row per day). */
    public function store(Request $request)
    {
        $v = $request->validate([
            'employee_id' => 'required|integer|exists:employees,id',
            'work_date'   => 'required|date',
            'title'       => 'nullable|max:100',
            'hours'       => 'required|numeric|min:0.25|max:24',
            'rate'        => 'nullable|numeric|min:0',
        ]);

        $month = Carbon::parse($v['work_date'])->format('Y-m');

        if ($this->service->isLocked($month)) {
            return $this->back($month, 'Salary for this month is already approved. Overtime cannot be added.', 'danger');
        }

        $active = DB::table('employees')->where('id', $v['employee_id'])->where('over_time', 1)->exists();
        if (!$active) {
            return $this->back($month, 'Overtime is not active for this employee. Activate it in the "Eligible Employees" tab first.', 'danger');
        }

        $exists = Overtime::where('employee_id', $v['employee_id'])->where('work_date', $v['work_date'])->exists();
        if ($exists) {
            return $this->back($month, 'An overtime entry already exists for this employee on that date. Edit it instead.', 'danger');
        }

        Overtime::create([
            'employee_id'    => $v['employee_id'],
            'overtime_month' => $month,
            'work_date'      => $v['work_date'],
            'source'         => 'manual',
            'status'         => 'approved',
            'approved_by'    => Auth::id(),
            'approved_at'    => now(),
            'title'          => $v['title'] ?: 'Manual overtime',
            'number_of_days' => 1,
            'hours'          => $v['hours'],
            'rate'           => $v['rate'] ?? null,
            'created_by'     => Auth::id(),
        ]);

        return $this->back($month, 'Overtime added. If salary was already generated, please Regenerate it.', 'success');
    }

    /** Edit hours / rate of a row. */
    public function update(Request $request, Overtime $overtime)
    {
        $v = $request->validate([
            'title' => 'nullable|max:100',
            'hours' => 'required|numeric|min:0.25|max:24',
            'rate'  => 'nullable|numeric|min:0',
        ]);

        if ($this->service->isLocked((string) $overtime->overtime_month)) {
            return $this->back($overtime->overtime_month, 'Salary for this month is already approved. Overtime cannot be changed.', 'danger');
        }

        $data = ['hours' => $v['hours'], 'rate' => $v['rate'] ?? null];
        if (!empty($v['title'])) {
            $data['title'] = $v['title'];
        }
        $overtime->update($data);

        return $this->back($overtime->overtime_month, 'Overtime updated.', 'success');
    }

    public function destroy(Overtime $overtime)
    {
        $month = $overtime->overtime_month;
        if ($this->service->isLocked((string) $month)) {
            return $this->back($month, 'Salary for this month is already approved. Overtime cannot be deleted.', 'danger');
        }
        $overtime->delete();
        return $this->back($month, 'Overtime deleted.', 'success');
    }

    /** Build draft overtime from attendance. */
    public function generate(Request $request)
    {
        $month = $this->cleanMonth($request->input('month'), now()->subMonth()->format('Y-m'));

        try {
            $r = $this->service->generate($month, null, (int) Auth::id());
        } catch (\RuntimeException $e) {
            return $this->back($month, $e->getMessage(), 'danger');
        }

        $msg = "Generated from attendance for {$r['employees']} active employee(s): "
            . "{$r['created']} new, {$r['updated']} updated, {$r['removed']} removed, "
            . "{$r['skipped_existing']} skipped (already approved/rejected/manual).";
        if ($r['missing_punch'] > 0) {
            $msg .= " {$r['missing_punch']} weekend/holiday day(s) have only one punch (out time missing). Please add those manually if needed.";
        }
        if ($r['employees'] === 0) {
            $msg = 'No active employees found. Activate overtime for employees in the "Eligible Employees" tab first.';
        }

        return $this->back($month, $msg, $r['employees'] === 0 ? 'warning' : 'success');
    }

    /** Approve / reject / reset (selected rows or all drafts). */
    public function bulkStatus(Request $request)
    {
        $request->validate([
            'action' => 'required|in:approve,approve_all,reject,reset',
            'month'  => ['required', 'regex:/^\d{4}-\d{2}$/'],
            'ids'    => 'nullable|array',
            'ids.*'  => 'integer',
        ]);

        $month = $request->input('month');
        $action = $request->input('action');

        if ($this->service->isLocked($month)) {
            return $this->back($month, 'Salary for this month is already approved. Overtime cannot be changed.', 'danger');
        }

        $q = Overtime::where('overtime_month', $month);
        if ($action === 'approve_all') {
            $q->where('status', 'draft');
        } else {
            $ids = $request->input('ids', []);
            if (empty($ids)) {
                return $this->back($month, 'Please select at least one row.', 'warning');
            }
            $q->whereIn('id', $ids);
        }

        if (in_array($action, ['approve', 'approve_all'])) {
            $data = ['status' => 'approved', 'approved_by' => Auth::id(), 'approved_at' => now()];
        } elseif ($action === 'reject') {
            $data = ['status' => 'rejected', 'approved_by' => Auth::id(), 'approved_at' => now()];
        } else {
            $data = ['status' => 'draft', 'approved_by' => null, 'approved_at' => null];
        }

        $count = $q->update($data);

        return $this->back($month, "{$count} row(s) updated. If salary was already generated, please Regenerate it.", 'success');
    }

    /** Save the overtime settings. */
    public function settings(Request $request)
    {
        $v = $request->validate([
            'mode'              => 'required|in:manual,auto_review,auto_approve',
            'min_minutes'       => 'required|integer|min:0|max:240',
            'round_minutes'     => 'required|integer|min:1|max:60',
            'max_hours_per_day' => 'required|numeric|min:0.25|max:10',
            'holiday_max_hours' => 'required|numeric|min:0.25|max:16',
        ]);

        $s = OvertimeSetting::orderByDesc('id')->first() ?: new OvertimeSetting();
        $s->fill($v);
        $s->count_holiday_work = $request->boolean('count_holiday_work');
        $s->done_by = Auth::user()->name;
        $s->save();

        return redirect()->route('overtime.index', ['month' => $request->input('month')])
            ->with(['message' => 'Overtime settings saved.', 'alert-type' => 'success']);
    }

    /** Activate / deactivate overtime for employees. */
    public function eligibility(Request $request)
    {
        $ids = array_map('intval', $request->input('active_ids', []));

        DB::transaction(function () use ($ids) {
            DB::table('employees')->where('status', 1)->update(['over_time' => 0]);
            if (!empty($ids)) {
                DB::table('employees')->whereIn('id', $ids)->update(['over_time' => 1]);
            }
        });

        return redirect()->route('overtime.index', ['month' => $request->input('month')])
            ->with(['message' => count($ids) . ' employee(s) are now active for overtime.', 'alert-type' => 'success']);
    }

    private function cleanMonth(?string $month, string $default): string
    {
        return ($month && preg_match('/^\d{4}-\d{2}$/', $month)) ? $month : $default;
    }

    private function back(?string $month, string $msg, string $type)
    {
        return redirect()->route('overtime.index', ['month' => $month])
            ->with(['message' => $msg, 'alert-type' => $type]);
    }
}