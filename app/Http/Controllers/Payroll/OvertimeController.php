<?php
namespace App\Http\Controllers\Payroll;

use App\Http\Controllers\Controller;
use App\Models\Employee;
use App\Models\MonthlySalary;
use App\Models\Overtime;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * Mash-wise overtime entry.
 *   Amount = number_of_days x hours x rate
 *   rate khali rakhle salary generate-er somoy auto rate dhora hoy:
 *   (gross / 30 / 8) x 2   (PayrollCalculator-e OVERTIME_* constant)
 */
class OvertimeController extends Controller
{
    public function __construct()
    {
        $this->middleware('permission:read monthly salary|write monthly salary|create monthly salary', ['only' => ['index']]);
        $this->middleware('permission:create monthly salary', ['only' => ['store']]);
        $this->middleware('permission:write monthly salary', ['only' => ['update', 'destroy']]);
    }

    public function index(Request $request)
    {
        $month = $request->get('month', now()->subMonth()->format('Y-m'));
        if (!preg_match('/^\d{4}-\d{2}$/', $month)) {
            $month = now()->format('Y-m');
        }

        $overtimes = Overtime::with('employee:id,employee_name,employee_code')
            ->where('overtime_month', $month)->orderByDesc('id')->get();

        $employees = Employee::where('status', 1)->orderBy('order')
            ->get(['id', 'employee_code', 'employee_name']);

        $locked = MonthlySalary::where('salary_month', $month)->where('status', 1)->exists();

        return view('pages.payroll.overtime.index', compact('overtimes', 'employees', 'month', 'locked'));
    }

    public function store(Request $request)
    {
        $v = $request->validate([
            'employee_id'    => 'required|integer|exists:employees,id',
            'overtime_month' => ['required', 'regex:/^\d{4}-\d{2}$/'],
            'title'          => 'nullable|max:100',
            'number_of_days' => 'required|integer|min:1|max:31',
            'hours'          => 'required|numeric|min:0.25|max:24',
            'rate'           => 'nullable|numeric|min:0',
        ]);

        if ($this->isLocked($v['overtime_month'])) {
            return $this->back($v['overtime_month'], 'Ei mash-er salary approve kora, overtime add kora jabe na.', 'danger');
        }

        Overtime::create([
            'employee_id'    => $v['employee_id'],
            'overtime_month' => $v['overtime_month'],
            'title'          => $v['title'] ?: 'Overtime',
            'number_of_days' => $v['number_of_days'],
            'hours'          => $v['hours'],
            'rate'           => $v['rate'] ?? null,
            'created_by'     => Auth::user()->id,
        ]);

        return $this->back($v['overtime_month'], 'Overtime added. Salary age generate kora thakle Regenerate korun.', 'success');
    }

    public function update(Request $request, Overtime $overtime)
    {
        $v = $request->validate([
            'title'          => 'nullable|max:100',
            'number_of_days' => 'required|integer|min:1|max:31',
            'hours'          => 'required|numeric|min:0.25|max:24',
            'rate'           => 'nullable|numeric|min:0',
        ]);

        if ($this->isLocked($overtime->overtime_month)) {
            return $this->back($overtime->overtime_month, 'Ei mash-er salary approve kora, bodlano jabe na.', 'danger');
        }

        $overtime->update([
            'title'          => $v['title'] ?: 'Overtime',
            'number_of_days' => $v['number_of_days'],
            'hours'          => $v['hours'],
            'rate'           => $v['rate'] ?? null,
        ]);

        return $this->back($overtime->overtime_month, 'Overtime updated.', 'success');
    }

    public function destroy(Overtime $overtime)
    {
        $month = $overtime->overtime_month;
        if ($this->isLocked($month)) {
            return $this->back($month, 'Ei mash-er salary approve kora, delete kora jabe na.', 'danger');
        }
        $overtime->delete();
        return $this->back($month, 'Overtime deleted.', 'success');
    }

    private function isLocked(?string $month): bool
    {
        return $month && MonthlySalary::where('salary_month', $month)->where('status', 1)->exists();
    }

    private function back(?string $month, string $msg, string $type)
    {
        return redirect()->route('overtime.index', ['month' => $month])
            ->with(['message' => $msg, 'alert-type' => $type]);
    }
}