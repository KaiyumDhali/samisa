<?php

namespace App\Http\Controllers\Employee;

use App\Http\Controllers\Controller;
use App\Models\AttendanceRequest;
use App\Models\Employee;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

/**
 * Delay In / Early Out / Out of Office applications (entered and decided by HR).
 * Approved applications are copied into employee_delayin_earlyouts, which the
 * attendance reports and the late-leave calculation already read.
 */
class EmployeeDelayinEarlyoutController extends Controller
{
    public const TYPES = [
        'delay_in' => 'Delay In (late arrival)',
        'early_out' => 'Early Out (early departure)',
        'out_of_office' => 'Out of Office (official work)',
        'absences' => 'Mark as Absent (HR override)',
    ];

    function __construct()
    {
        $this->middleware('permission:read delayin earlyout|write delayin earlyout|create delayin earlyout', ['only' => ['index', 'show']]);
        $this->middleware('permission:create delayin earlyout', ['only' => ['create', 'store']]);
        $this->middleware('permission:write delayin earlyout', ['only' => ['edit', 'update', 'destroy', 'decide']]);
    }

    public function index(Request $request)
    {
        return $this->render($request, null);
    }

    public function edit(Request $request, $id)
    {
        $record = AttendanceRequest::findOrFail($id);
        if (!$request->filled('month')) {
            $request->merge(['month' => Carbon::parse($record->request_date)->format('Y-m')]);
        }
        return $this->render($request, $record);
    }

    public function create()
    {
        return redirect()->route('emp_delayin_earlyout.index');
    }

    public function show($id)
    {
        return redirect()->route('emp_delayin_earlyout.index');
    }

    public function store(Request $request)
    {
        $v = $this->validated($request);

        $exists = AttendanceRequest::where('employee_id', $v['employee_id'])
            ->whereDate('request_date', $v['request_date'])->exists();
        if ($exists) {
            return $this->back($v['request_date'], 'An application already exists for this employee on this date. Edit it instead.', 'danger');
        }

        $approveNow = $request->boolean('approve_now') && Auth::user()->can('write delayin earlyout');

        $r = AttendanceRequest::create([
            'employee_id' => $v['employee_id'],
            'request_date' => $v['request_date'],
            'request_type' => $v['request_type'],
            'expected_time' => $v['expected_time'] ?? null,
            'reason' => $v['reason'] ?? null,
            'status' => $approveNow ? 'approved' : 'pending',
            'decided_by' => $approveNow ? Auth::user()->name : null,
            'decided_at' => $approveNow ? now() : null,
            'done_by' => Auth::user()->name,
        ]);
        $this->sync($r);

        return $this->back($v['request_date'], $approveNow ? 'Application saved and approved.' : 'Application saved. It is waiting for approval.', 'success');
    }

    public function update(Request $request, $id)
    {
        $r = AttendanceRequest::findOrFail($id);
        $v = $this->validated($request);

        $exists = AttendanceRequest::where('employee_id', $v['employee_id'])
            ->whereDate('request_date', $v['request_date'])->where('id', '!=', $r->id)->exists();
        if ($exists) {
            return $this->back($v['request_date'], 'Another application already exists for this employee on this date.', 'danger');
        }

        $r->update([
            'employee_id' => $v['employee_id'],
            'request_date' => $v['request_date'],
            'request_type' => $v['request_type'],
            'expected_time' => $v['expected_time'] ?? null,
            'reason' => $v['reason'] ?? null,
        ]);
        $this->sync($r);

        return $this->back($v['request_date'], 'Application updated.', 'success');
    }

    public function destroy($id)
    {
        $r = AttendanceRequest::findOrFail($id);
        $date = $r->request_date;
        if ($r->exception_id) {
            DB::table('employee_delayin_earlyouts')->where('id', $r->exception_id)->delete();
        }
        $r->delete();

        return $this->back($date, 'Application deleted.', 'success');
    }

    /** Approve / reject / back to pending (one or many rows). */
    public function decide(Request $request)
    {
        $request->validate([
            'action' => 'required|in:approve,reject,reset',
            'ids' => 'required|array|min:1',
            'ids.*' => 'integer',
        ]);

        $count = 0;
        foreach (AttendanceRequest::whereIn('id', $request->input('ids'))->get() as $r) {
            if ($request->action === 'approve') {
                $r->status = 'approved';
                $r->decided_by = Auth::user()->name;
                $r->decided_at = now();
            } elseif ($request->action === 'reject') {
                $r->status = 'rejected';
                $r->decided_by = Auth::user()->name;
                $r->decided_at = now();
            } else {
                $r->status = 'pending';
                $r->decided_by = null;
                $r->decided_at = null;
            }
            $r->save();
            $this->sync($r);
            $count++;
        }

        return redirect()->route('emp_delayin_earlyout.index', ['month' => $request->input('month')])
            ->with(['message' => "{$count} application(s) updated.", 'alert-type' => 'success']);
    }

    // ------------------------------------------------------------------

    private function validated(Request $request): array
    {
        return $request->validate([
            'employee_id' => 'required|integer|exists:employees,id',
            'request_date' => 'required|date',
            'request_type' => 'required|in:' . implode(',', array_keys(self::TYPES)),
            'expected_time' => 'nullable|date_format:H:i|required_if:request_type,delay_in,early_out',
            'reason' => 'nullable|max:255',
        ]);
    }

    /**
     * Keep employee_delayin_earlyouts in step with the application:
     * approved -> a row exists, anything else -> the row is removed.
     */
    private function sync(AttendanceRequest $r): void
    {
        $table = DB::table('employee_delayin_earlyouts');

        if ($r->status === 'approved') {
            $data = [
                'employee_id' => $r->employee_id,
                'date' => Carbon::parse($r->request_date)->toDateString(),
                'status' => $r->request_type,
                'remarks' => $r->reason,
                'delay_in_time' => $r->request_type === 'delay_in' ? $r->expected_time : null,
                'early_out_time' => $r->request_type === 'early_out' ? $r->expected_time : null,
                'done_by' => $r->decided_by,
                'updated_at' => now(),
            ];

            if ($r->exception_id && DB::table('employee_delayin_earlyouts')->where('id', $r->exception_id)->exists()) {
                DB::table('employee_delayin_earlyouts')->where('id', $r->exception_id)->update($data);
            } else {
                $data['created_at'] = now();
                $id = DB::table('employee_delayin_earlyouts')->insertGetId($data);
                $r->exception_id = $id;
                $r->save();
            }
        } elseif ($r->exception_id) {
            DB::table('employee_delayin_earlyouts')->where('id', $r->exception_id)->delete();
            $r->exception_id = null;
            $r->save();
        }
    }

    private function render(Request $request, ?AttendanceRequest $editing)
    {
        $month = preg_match('/^\d{4}-\d{2}$/', (string) $request->get('month')) ? $request->get('month') : now()->format('Y-m');
        $start = Carbon::parse($month . '-01')->startOfMonth()->toDateString();
        $end = Carbon::parse($month . '-01')->endOfMonth()->toDateString();

        $q = AttendanceRequest::with('employee:id,employee_name,employee_code')
            ->whereBetween('request_date', [$start, $end]);
        if ($request->filled('status')) {
            $q->where('status', $request->get('status'));
        }
        if ($request->filled('employee_id')) {
            $q->where('employee_id', $request->get('employee_id'));
        }
        $rows = $q->orderByDesc('request_date')->orderByDesc('id')->get();

        $counts = AttendanceRequest::whereBetween('request_date', [$start, $end])
            ->select('status', DB::raw('COUNT(*) as c'))->groupBy('status')->pluck('c', 'status');

        $employees = Employee::where('status', 1)->orderBy('order')->get(['id', 'employee_code', 'employee_name']);

        return view('pages.employee.emp_delayin_earlyout.index', [
            'rows' => $rows,
            'counts' => $counts,
            'employees' => $employees,
            'month' => $month,
            'editing' => $editing,
            'types' => self::TYPES,
            'statusFilter' => $request->get('status'),
            'employeeFilter' => $request->get('employee_id'),
        ]);
    }

    private function back($date, string $msg, string $type)
    {
        return redirect()->route('emp_delayin_earlyout.index', ['month' => Carbon::parse($date)->format('Y-m')])
            ->with(['message' => $msg, 'alert-type' => $type]);
    }
}