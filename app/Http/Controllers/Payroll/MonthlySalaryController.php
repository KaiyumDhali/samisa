<?php
namespace App\Http\Controllers\Payroll;
use App\Http\Controllers\Controller;

// use App\Models\PayslipType;
// use App\Models\IncomeHead;
// use App\Models\DeductionHead;
// use App\Models\PaySlip;

use App\Models\Employee;
use App\Models\EmpBranch;
use App\Models\EmpPosting;

use App\Models\payrollFormula;
use App\Models\PayrollHead;
use App\Models\payroll;
use App\Models\MonthlySalary;

use App\Models\MonthlySalaryDetail;

use App\Models\EmployeeDesignation;
use App\Models\EmployeeSalary;
use App\Models\Income;
use App\Services\PayrollCalculator;
use App\Models\Deduction;

use Illuminate\Http\Request;
use Auth;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Barryvdh\DomPDF\Facade\Pdf;

class MonthlySalaryController extends Controller
{

    function __construct() {
        $this->middleware('permission:read monthly salary|write monthly salary|create monthly salary', ['only' => ['index', 'show']]);
        $this->middleware('permission:create monthly salary', ['only' => ['create', 'store']]);
        $this->middleware('permission:write monthly salary', ['only' => ['edit', 'update', 'destroy', 'approve']]);
    }

    // Generate monthly Salary List get
       // Generate monthly Salary List get (head-agnostic: je head-ই thakuk dekhabe)
        // Generate monthly Salary List get (head-agnostic: je head-ই thakuk dekhabe)
    public function monthlySalariesList($month, $pdf)
    {
        return $this->salarySheet($month, $pdf, 0);
    }

    private function salarySheet($month, $pdf, $branchID = 0)
    {
        $salaries = MonthlySalary::where('salary_month', $month)
            ->when($branchID, fn ($q) => $q->where('monthly_salaries.branch_id', $branchID))
            ->join('employees', 'employees.id', '=', 'monthly_salaries.employee_id')
            ->orderBy('employees.order')
            ->select('monthly_salaries.*', 'employees.employee_name', 'employees.employee_code', 'employees.order as employee_order')
            ->get();

        $details = MonthlySalaryDetail::whereIn('monthly_salary_id', $salaries->pluck('id'))->get()
            ->groupBy('monthly_salary_id');

        // Column list: shob head, Income age, tarpor Deduction
        $heads = MonthlySalaryDetail::whereIn('monthly_salary_id', $salaries->pluck('id'))
            ->select('head_type', 'head_name')->distinct()->get()
            ->sortBy(fn ($h) => ($h->head_type === 'Income' ? '0' : '1') . $h->head_name)->values();

        $rows = $salaries->map(function ($ms) use ($details) {
            $amounts = [];
            foreach ($details->get($ms->id, collect()) as $d) {
                $amounts[$d->head_type . '|' . $d->head_name] = (float) $d->amount;
            }
            return [
                'employee_order' => $ms->employee_order,
                'employee_code'  => $ms->employee_code,
                'employee_name'  => $ms->employee_name,
                'basic_salary'   => (float) $ms->basic_salary,
                'working_days'   => $ms->working_days,
                'present_days'   => $ms->present_days,
                'leave_days'     => $ms->leave_days,
                'absent_days'    => $ms->absent_days,
                'income'         => (float) $ms->income,
                'deduction'      => (float) $ms->deduction,
                'net_payble'     => (float) $ms->net_payble,
                'status'         => $ms->status,
                'amounts'        => $amounts,
            ];
        });

        if ($pdf == "list") {
            return response()->json(['heads' => $heads, 'rows' => $rows]);
        }
        if ($pdf == "pdfurl") {
            $data['month'] = $month;
            $pdf = PDF::loadView('pages.pdf.monthly_salaries_report_pdf', ['rows' => $rows, 'heads' => $heads, 'data' => $data]);
            return $pdf->stream(Carbon::now() . '-salary-sheet.pdf');
        }
    }

    public function monthlySalaries($branchID, $month, $pdf)
    {
        return $this->salarySheet($month, $pdf, (int) $branchID);
    }
    /**
     * Display a listing of the resource.
     */
    public function index()
    {
        //         $month = 2023-11;
        //         $query = "
        //             SELECT
        //                 (SELECT e.order FROM employees e WHERE e.id=ms.employee_id) AS employee_order,
                        
        //                 ms.employee_id AS employee_id,
        //                 DATE_FORMAT(ms.generate_date, '%Y-%m-%d') AS generate_date,
        //                 ms.salary_month AS salary_month,
                        
        //                 (SELECT e.employee_name FROM employees e WHERE e.id=ms.employee_id) AS employee_name,
        //                 (SELECT ed.designation_name FROM emp_designations ed WHERE ed.id=(SELECT e.designation_id FROM employees e WHERE e.id=ms.employee_id)) AS designation_name,
                        
        //                 (SELECT es.amount FROM  employee_salaries es WHERE es.employee_id=ms.employee_id ORDER BY ms.salary_month DESC LIMIT 1) AS Base_Salary,
                    
        //                 (SELECT msd.amount FROM  monthly_salary_details msd WHERE msd.monthly_salary_id=ms.id and msd.head_type='Income' and msd.head_id=1) AS House_Rent,
        //                 (SELECT msd.amount FROM  monthly_salary_details msd WHERE msd.monthly_salary_id=ms.id and msd.head_type='Income' and msd.head_id=2) AS Medical,
        //                 (SELECT msd.amount FROM  monthly_salary_details msd WHERE msd.monthly_salary_id=ms.id and msd.head_type='Income' and msd.head_id=3) AS PF,
        //                 (SELECT msd.amount FROM  monthly_salary_details msd WHERE msd.monthly_salary_id=ms.id and msd.head_type='Income' and msd.head_id=4) AS iOthers,
                        
        //                 (SELECT msd.amount FROM  monthly_salary_details msd WHERE msd.monthly_salary_id=ms.id and msd.head_type='Deduction' and msd.head_id=1) AS TAX,
        //                 (SELECT msd.amount FROM  monthly_salary_details msd WHERE msd.monthly_salary_id=ms.id and msd.head_type='Deduction' and msd.head_id=2) AS dPF,
        //                 (SELECT msd.amount FROM  monthly_salary_details msd WHERE msd.monthly_salary_id=ms.id and msd.head_type='Deduction' and msd.head_name='Others') AS dOthers
                        
        //             FROM monthly_salaries AS ms
                    
        //             WHERE ms.salary_month = '$month'
                    
        //             ORDER BY employee_order ASC
        //         ";

        //         $monthlySalaries = DB::table(DB::raw("($query) AS subquery"))
        //                 ->select('employee_order', 'employee_id', 'employee_name', 'designation_name','Base_Salary','House_Rent','Medical','PF','iOthers','TAX', 'dPF', 'dOthers')
        //                 ->orderBy('employee_order')
        //                 ->get();

        // dd($monthlySalaries);

        $allEmpBranch = EmpBranch::where('status', 1)->pluck('branch_name', 'id')->all();
        // dd($results);
        return view('pages.payroll.salary_sheet.index', compact('allEmpBranch'));
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function __store(Request $request)
    {
        // $salary_month = '2024-03'; // Enclose the string in quotes
        $salary_month = $request->selectedmonth;

        // Retrieve total monthly salary employee IDs (employees who were in the company by the end of the specified month)
        $totalMonthlySalaryEmployeeIds = Employee::join('emp_postings', 'emp_postings.employee_id', '=', 'employees.id')
                                                ->where('employees.salary_held_up', 0)
                                                ->whereDate('emp_postings.joining_date', '<=', date('Y-m-t', strtotime($salary_month)))
                                                ->orderBy('emp_postings.joining_date', 'desc')
                                                ->pluck('employees.id');
        // dd($totalMonthlySalaryEmployeeIds);
        // Retrieve added monthly salary employee IDs for the specified month
        $addedMonthlySalaryEmployeeIds = MonthlySalary::where('salary_month', $salary_month)
                                                    ->pluck('employee_id');
        // dd($addedMonthlySalaryEmployeeIds);
        // Check if there are new employees (employees who received salaries but are not included in total monthly salary employees)
        if ($totalMonthlySalaryEmployeeIds->count() > $addedMonthlySalaryEmployeeIds->count()) {
            // Calculate IDs of new employees
            $newEmployeeIds = $totalMonthlySalaryEmployeeIds->diff($addedMonthlySalaryEmployeeIds);
            // dd($newEmployeeIds);
            
            foreach ($newEmployeeIds as $employeeId) {
                // Get the latest gross salary from EmpPosting for the employee
                $basic_salary_amount = EmpPosting::where('employee_id', $employeeId)
                    ->orderBy('id', 'desc')
                    ->value('gross_salary');
            
                // Fetch all relevant payroll IDs for the employee based on effective date
                $payrolls = Payroll::where('employee_id', $employeeId)
                    ->whereDate('effective_date', '<=', date('Y-m-t', strtotime($salary_month)))
                    ->pluck('payroll_head_id');
            
                // Iterate through each payroll ID and retrieve payroll head data
                foreach ($payrolls as $payroll) {
                    $payrollHeadData = PayrollHead::select(
                            'payroll_heads.id as payroll_head_id',
                            'payroll_heads.name as payroll_head_name',
                            'payroll_heads.type as payroll_head_type',
                            'payroll_formulas.formula'
                        )
                        ->join('payroll_formulas', 'payroll_heads.id', '=', 'payroll_formulas.payroll_head')
                        ->where('payroll_heads.id', $payroll)
                        ->get();
            
                    // Iterate through each payroll head data to process the formula
                    foreach ($payrollHeadData as $payrollData) {
                        // Get the formula from payroll head data
                        $formula = $payrollData->formula;
            
                        // Replace placeholder {Basic Salary} with actual basic_salary_amount
                        // Assuming {Basic Salary} is meant to be replaced with $basic_salary_amount
                        $formula = str_replace('{Basic Salary}', $basic_salary_amount, $formula);
            
                        // Evaluate the modified formula (if needed)
                        // This step depends on how the formula should be processed
                        // For example, you might need to parse and evaluate this formula dynamically
                        // using a custom function or library, depending on the expression format.
            
                        // For now, let's assume you're evaluating a simple arithmetic expression
                        // Example: {Basic Salary}/100*35
                        // Evaluating this expression (assuming formula structure is valid):
                        eval('$result = ' . $formula . ';');
            
                        // Now, $result holds the calculated value based on the payroll formula
                        // You can use or store this result as needed for further processing
                        // For example, save this result to a database or display it somewhere.
                        // In this example, $result represents 35% of the basic_salary_amount.
            
                        // Example of how you might use or display the result
                        echo "Employee ID: $employeeId, Payroll Head Name: $payrollData->payroll_head_name, Payroll Head Type: $payrollData->payroll_head_type, Calculated Result: $result\n";
                    }
                }
            }
        }
    }


          public function store(Request $request)
    {
        $request->validate(['selectedmonth' => ['required', 'regex:/^\d{4}-\d{2}$/']]);
        $salary_month = $request->selectedmonth;           // e.g. 2026-11
        $monthEnd     = date('Y-m-t', strtotime($salary_month . '-01'));
        $created_by   = Auth::user()->id;
        $calc         = new PayrollCalculator();

        // Regenerate: shudhu approve na-howa (status 0) salary muche abar toiri
        if ($request->boolean('regenerate')) {
            $ids = MonthlySalary::where('salary_month', $salary_month)->where('status', 0)->pluck('id');
            MonthlySalaryDetail::whereIn('monthly_salary_id', $ids)->delete();
            MonthlySalary::whereIn('id', $ids)->delete();
        }

        $eligibleIds = Employee::join('emp_postings', 'emp_postings.employee_id', '=', 'employees.id')
            ->where('employees.salary_held_up', 0)
            ->whereDate('emp_postings.joining_date', '<=', $monthEnd)
            ->where(function ($q) use ($salary_month) {
                $q->whereNull('employees.quite_date')
                  ->orWhere('employees.quite_date', '>=', $salary_month . '-01');
            })
            ->pluck('employees.id')->unique();

        $alreadyIds = MonthlySalary::where('salary_month', $salary_month)->pluck('employee_id');
        $newIds = $eligibleIds->diff($alreadyIds);

        if ($newIds->isEmpty()) {
            return redirect()->route('monthly_salaries.index')->with([
                'message' => 'Salary already created for this month.',
                'alert-type' => 'danger',
            ]);
        }

        // Gross salary set na thakle ager-e janiye deya
        $noSalary = $newIds->filter(fn ($id) => !(float) EmpPosting::where('employee_id', $id)->orderByDesc('id')->value('gross_salary'));
        if ($noSalary->isNotEmpty()) {
            $codes = Employee::whereIn('id', $noSalary)->pluck('employee_code')->implode(', ');
            return redirect()->route('monthly_salaries.index')->with([
                'message' => 'Gross salary set kora nai (Employee Code: ' . $codes . ')',
                'alert-type' => 'danger',
            ]);
        }

        DB::transaction(function () use ($newIds, $salary_month, $created_by, $calc) {
            foreach ($newIds as $employeeId) {
                $res = $calc->calculate((int) $employeeId, $salary_month);

                $monthly = MonthlySalary::create([
                    'employee_id'   => $employeeId,
                    'branch_id'     => EmpPosting::where('employee_id', $employeeId)->orderByDesc('id')->value('branch_id'),
                    'generate_date' => Carbon::now(),
                    'salary_month'  => $salary_month,
                    'basic_salary'  => $res['basic_salary'],
                    'income'        => $res['income'],
                    'deduction'     => $res['deduction'],
                    'net_payble'    => $res['net_payble'],
                    'working_days'  => $res['working_days'],
                    'present_days'  => $res['present_days'],
                    'leave_days'    => $res['leave_days'],
                    'absent_days'   => $res['absent_days'],
                    'status'        => 0,
                    'created_by'    => $created_by,
                ]);

                foreach ($res['rows'] as $row) {
                    MonthlySalaryDetail::create($row + [
                        'monthly_salary_id' => $monthly->id,
                        'created_by'        => Auth::user()->name,
                    ]);
                }
            }
        });

        return redirect()->route('monthly_salaries.index')->with([
            'message' => 'Salary successfully created for ' . $newIds->count() . ' employee(s).',
            'alert-type' => 'success',
        ]);
    }

    /** Mash-er shob pending salary approve (lock) kora. */
    public function approve(Request $request)
    {
        $request->validate(['salary_month' => ['required', 'regex:/^\d{4}-\d{2}$/']]);
        $count = MonthlySalary::where('salary_month', $request->salary_month)->where('status', 0)
            ->update(['status' => 1, 'approved_by' => Auth::user()->name]);
        return back()->with([
            'message' => $count . ' salary approved.',
            'alert-type' => 'success',
        ]);
    }
    /**
     * Display the specified resource.
     */
    public function show(MonthlySalary $monthlySalary)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(MonthlySalary $monthlySalary)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, MonthlySalary $monthlySalary)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(MonthlySalary $monthlySalary)
    {
        //
    }
}