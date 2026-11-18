<?php
namespace App\Http\Controllers\Employee;
use App\Http\Controllers\Controller;
use App\Models\EmployeeLeaveSetting;
use App\Models\EmployeeLeaveEntry;
use App\Models\Employee;
use App\Models\EmpBranch;
use App\Models\User;
use App\Models\LateLeavePolicy;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Date;
use Carbon\Carbon;
use validator;
use Auth;
use Barryvdh\DomPDF\Facade\Pdf;

// use Illuminate\Support\Facades\DB;
use DB;

class leaveReportController extends Controller
{
        public function addLateOFLeave(Request $request)
    {
        $selectedData = $request->input('selectedData', []);
        $done_by = Auth::user()->name;
        try {
            DB::transaction(function () use ($selectedData, $done_by) {
                foreach ($selectedData as $data) {
                    $monthNumber = Carbon::parse($data['month'])->month;
                    $date = Carbon::create($data['year'], $monthNumber, 1)->toDateString();

                    // age ei mashe auto-banano entry muche notun kore banai (double kata thekate)
                    EmployeeLeaveEntry::where('employee_id', $data['selected_users'])
                        ->where('late_of_leave_month', $date)
                        ->where('remarks', 'Monthly Late Leave')
                        ->delete();

                    $deductions = json_decode($data['deductions'] ?? '[]', true) ?: [];
                    foreach ($deductions as $dd) {
                        if (empty($dd['days']) || (int) $dd['days'] < 1) {
                            continue;
                        }
                        if (!in_array($dd['type'], LateLeavePolicy::LEAVE_TYPES)) {
                            throw new \Exception('Invalid leave type: ' . $dd['type']);
                        }
                        $bal = $this->typeBalance($data['selected_users'], $data['year'], $dd['type'], $date);
                        if ((int) $dd['days'] > $bal) {
                            throw new \Exception($dd['type'] . ' leave balance (' . $bal . ' din) er cheye beshi kata jabe na.');
                        }
                        EmployeeLeaveEntry::create([
                            'leave_year' => $data['year'],
                            'leave_type' => $dd['type'],
                            'employee_id' => $data['selected_users'],
                            'no_of_late' => $data['late_count'],
                            'total_days' => (int) $dd['days'],
                            'final_status' => 1,
                            'late_of_leave_month' => $date,
                            'remarks' => 'Monthly Late Leave',
                            'done_by' => $done_by,
                        ]);
                    }
                }
            });
            return response()->json(['message' => 'Data submitted successfully']);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    }

    public function saveLatePolicy(Request $request)
    {
        $types = implode(',', LateLeavePolicy::LEAVE_TYPES);
        $v = $request->validate([
            'late_count' => 'required|integer|min:1|max:31',
            'deduct_days' => 'required|integer|min:1|max:31',
            'leave_type' => "required|in:$types",
            'fallback_leave_type' => "nullable|in:$types",
        ]);

        LateLeavePolicy::where('status', 1)->update(['status' => 0]);
        LateLeavePolicy::create([
            'late_count' => $v['late_count'],
            'deduct_days' => $v['deduct_days'],
            'leave_type' => $v['leave_type'],
            'fallback_leave_type' => $v['fallback_leave_type'] ?? null,
            'repeat_deduction' => $request->boolean('repeat_deduction'),
            'status' => 1,
            'done_by' => Auth::user()->name,
        ]);

        return back()->with(['message' => 'Late leave rule saved', 'alert-type' => 'success']);
    }
    private function typeBalance($empId, $year, $type, $monthStart)
    {
        $col = LateLeavePolicy::TYPE_COLUMN[$type] ?? null;
        if (!$col) {
            return 0;
        }
        $total = DB::table('employee_leave_settings')
            ->where('leave_year', $year)->where('employee_id', $empId)->value($col) ?? 0;
        $spent = DB::table('employee_leave_entries')
            ->where('leave_year', $year)->where('employee_id', $empId)
            ->where('leave_type', $type)->where('final_status', 1)
            ->where(function ($q) use ($monthStart) {
                $q->whereNull('late_of_leave_month')->orWhere('late_of_leave_month', '!=', $monthStart);
            })
            ->sum('total_days');
        return (float) $total - (float) $spent;
    }
    public function lateOFLeave()
    {
        $allEmpBranch = EmpBranch::where('status', 1)->pluck('branch_name', 'id')->all();   
       $policy = LateLeavePolicy::current();
return view('pages.employee.leave_report.late_of_leave', compact('allEmpBranch', 'policy'));
    }
    
    public function lateOFLeaveReport($year, $month, $pdf)
    {
        // $year = 2023;
        // $month = 'September';

        // Convert month name to month number
        $monthNumber = Carbon::parse($month)->month;

        // Create start and end dates
        $startDate = Carbon::create($year, $monthNumber, 1)->toDateString();
        $endDate = Carbon::create($year, $monthNumber, 1)->endOfMonth()->toDateString();

        $query = "
            WITH LeaveData AS (
                SELECT 
                    es.employee_id as eid, 
                    (select e.order from employees e where e.id = es.employee_id) as eorder,
                    (select e.employee_code from employees e where e.id = es.employee_id) as employee_code,
                    (select e.employee_name from employees e where e.id = es.employee_id) as employee_name,
                    (SELECT IFNULL(SUM(le.total_days), 0) FROM employee_leave_entries le WHERE le.leave_year ='$year' AND le.employee_id = es.employee_id AND le.leave_type = 'Casual' AND le.final_status = 1) as Approve_Casual_Leave,
                es.casual_leave as Total_Casual_Leave
                FROM employee_leave_settings es 
                WHERE es.leave_year = '$year'
            ),
            
            LateData AS (
                SELECT *
                FROM
                    ( select * from ( SELECT *        
                        FROM
                            attendances a
                                JOIN (
                                SELECT ADDDATE('1970-01-01', t4.i * 10000 + t3.i * 1000 + t2.i * 100 + t1.i * 10 + t0.i) AS _date
                                FROM 
                                    (SELECT 0 i UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 )t0,
                                    (SELECT 0 i UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) t1,
                                    (SELECT 0 i UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) t2,
                                    (SELECT 0 i UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) t3,
                                    (SELECT 0 i UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) t4
                                )v on v._date=a.date_only_record
                        WHERE
                            v._date BETWEEN '$startDate' AND '$endDate'    
                )v1
                group by v1.date_only_record, v1.employee_code)f 
                WHERE Time(f.date_time_record) > time((SELECT late_time FROM late_times ORDER BY id DESC LIMIT 1))
            )
                       SELECT *,  (Total_Casual_Leave - Approve_Casual_Leave) AS Deu_Casual_leave, 
            if( ((SELECT COUNT(ld.employee_code) FROM LateData ld WHERE ld.employee_code = LeaveData.employee_code)-(SELECT COUNT(id) FROM `employee_delayin_earlyouts` as dl WHERE dl.date BETWEEN '$startDate' AND '$endDate' AND dl.employee_id = eid)) >0, ((SELECT COUNT(ld.employee_code) FROM LateData ld WHERE ld.employee_code = LeaveData.employee_code)-(SELECT COUNT(id) FROM `employee_delayin_earlyouts` as dl WHERE dl.date BETWEEN '$startDate' AND '$endDate' AND dl.employee_id = eid)) ,0)
            AS Late_Count
            FROM LeaveData ORDER BY eorder
            ";
        $employeeDetails = DB::select($query);
        $this->applyLatePolicy($employeeDetails, $year, $startDate);

        if ($pdf == "list") {
            return response()->json($employeeDetails);
        }
        if ($pdf == "pdfurl") {
            $data['branch_id'] = '';
            $data['month'] = $month;
            $data['year'] = $year;
            $pdf = PDF::loadView('pages.pdf.employee_leave_report_pdf', array('employeeDetails' => $employeeDetails, 'data' => $data));
            return $pdf->stream(Carbon::now().'-recentstat.pdf');
        }
    }
        private function applyLatePolicy(array &$employees, $year, $monthStart)
    {
        $policy = LateLeavePolicy::current();
        // order: rule er primary, fallback, tarpor Casual -> Annual -> Sick
        $order = array_values(array_unique(array_filter([
            $policy->leave_type, $policy->fallback_leave_type, 'Casual', 'Annual', 'Sick',
        ])));

        $settings = DB::table('employee_leave_settings')->where('leave_year', $year)->get()->keyBy('employee_id');

        // ei mashe kora late-leave bad diye, ei bochor approved leave
        $used = DB::table('employee_leave_entries')
            ->where('leave_year', $year)
            ->where('final_status', 1)
            ->where(function ($q) use ($monthStart) {
                $q->whereNull('late_of_leave_month')->orWhere('late_of_leave_month', '!=', $monthStart);
            })
            ->select('employee_id', 'leave_type', DB::raw('SUM(total_days) as days'))
            ->groupBy('employee_id', 'leave_type')
            ->get()
            ->groupBy('employee_id');

        // ei mashe already approve kora late-leave
        $approved = DB::table('employee_leave_entries')
            ->where('leave_year', $year)
            ->where('final_status', 1)
            ->where('remarks', 'Monthly Late Leave')
            ->where('late_of_leave_month', $monthStart)
            ->select('employee_id', 'leave_type', 'total_days', 'no_of_late')
            ->get()
            ->groupBy('employee_id');

        foreach ($employees as $e) {
            // proti leave type er balance (ei month er late-leave er age porjonto)
            $bal = [];
            foreach (LateLeavePolicy::TYPE_COLUMN as $type => $col) {
                $total = isset($settings[$e->eid]) ? (float) $settings[$e->eid]->$col : 0;
                $spent = optional(optional($used->get($e->eid))->firstWhere('leave_type', $type))->days ?? 0;
                $bal[$type] = max(0, $total - (float) $spent);
            }

            // suggestion
            $need = $policy->daysFor((int) $e->Late_Count);
            $deductions = [];
            foreach ($order as $type) {
                if ($need < 1) {
                    break;
                }
                $take = min($need, (int) floor($bal[$type] ?? 0));
                if ($take > 0) {
                    $deductions[] = ['type' => $type, 'days' => $take];
                    $need -= $take;
                }
            }

            // approve kora ache kina
            $ap = [];
            $apLate = 0;
            foreach (($approved->get($e->eid) ?? collect()) as $a) {
                $ap[$a->leave_type] = (int) $a->total_days;
                $apLate = max($apLate, (int) $a->no_of_late);
            }

            $e->balances = $bal;
            $e->deductions = $deductions;
            $e->approved = $ap;
            $e->status = empty($ap) ? 'pending' : ($apLate == (int) $e->Late_Count ? 'approved' : 'changed');
            $e->late_leave = array_sum(array_column($deductions, 'days'));
            $e->uncovered_days = $need;
        }
    }
    // leave report index
    public function index()
    {
        $allEmpBranch = EmpBranch::where('status', 1)->pluck('branch_name', 'id')->all();   
        return view('pages.employee.leave_report.index', compact('allEmpBranch'));
    }
 
    // final leave report index list get
     public function leaveReport($year, $month, $pdf)
    {
        $monthNumber = Carbon::parse($month)->month;

        $typeSql = function ($type) use ($year, $monthNumber) {
            return "(select IFNULL(SUM(ee.total_days), 0) from employee_leave_entries ee
                WHERE ee.employee_id = es.employee_id AND ee.leave_year = '$year' AND ee.final_status = 1
                AND ee.leave_type = '$type'
                AND MONTH(COALESCE(ee.leave_start_date, ee.late_of_leave_month)) = $monthNumber)";
        };

        $query = "
        WITH LeaveData AS (
            SELECT 
                es.employee_id as eid, 
                (select e.order from employees e where e.id = es.employee_id) as eorder,
                (select e.employee_code from employees e where e.id = es.employee_id) as employee_code,
                (select e.employee_name from employees e where e.id = es.employee_id) as employee_name,
                " . $typeSql('Casual') . " AS casual,
                " . $typeSql('Sick') . " AS sick,
                " . $typeSql('Annual') . " AS annual,
                " . $typeSql('Special') . " AS special,

                (select IFNULL(SUM(ee.total_days), 0) from employee_leave_entries ee WHERE ee.leave_year = '$year' AND ee.employee_id = es.employee_id AND ee.final_status = 1 ) AS LeaveAvailed,

                (select IFNULL(MAX(ee.no_of_late), 0) from employee_leave_entries ee
                    WHERE ee.employee_id = es.employee_id AND ee.leave_year = '$year' AND ee.final_status = 1
                    AND ee.remarks = 'Monthly Late Leave' AND MONTH(ee.late_of_leave_month) = $monthNumber) AS NoOfLate,

                (select IFNULL(GROUP_CONCAT(CONCAT(ee.total_days, ' ', ee.leave_type) SEPARATOR ' + '), '-') from employee_leave_entries ee
                    WHERE ee.employee_id = es.employee_id AND ee.leave_year = '$year' AND ee.final_status = 1
                    AND ee.remarks = 'Monthly Late Leave' AND MONTH(ee.late_of_leave_month) = $monthNumber) AS LateDeduction,

                es.total_leave
            FROM employee_leave_settings es 
            WHERE es.leave_year = '$year' 
        )
        SELECT *, (total_leave - LeaveAvailed) AS LeaveBalance FROM LeaveData ORDER BY eorder";

        $employeeDetails = DB::select($query);
        if ($pdf == "list") {
            return response()->json($employeeDetails);
        }
        if ($pdf == "pdfurl") {
            $data['branch_id'] = '';
            $data['month'] = $month;
            $data['year'] = $year;
            $pdf = PDF::loadView('pages.pdf.employee_leave_report_pdf', array('employeeDetails' => $employeeDetails, 'data' => $data));
            return $pdf->stream(Carbon::now().'-recentstat.pdf');
        }
    }
}