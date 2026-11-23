<?php

namespace App\Http\Controllers\Lift;

use App\Models\Lift\LiftBill;
use App\Models\Lift\LiftContract;
use App\Models\Lift\LiftJob;
use App\Models\Lift\LiftUnit;

class LiftDashboardController extends LiftBaseController
{
    function __construct()
    {
        $this->guardPermissions(['index']);
    }

    public function index()
    {
        $today = now()->toDateString();
        $stats = [
            'units' => LiftUnit::where('status', 1)->count(),
            'active_contracts' => LiftContract::where('status', 'active')->where('end_date', '>=', $today)->count(),
            'expiring' => LiftContract::where('status', 'active')->whereBetween('end_date', [$today, now()->addDays(30)->toDateString()])->count(),
            'overdue_jobs' => LiftJob::where('status', 'scheduled')->where('scheduled_date', '<', $today)->count(),
            'week_jobs' => LiftJob::where('status', 'scheduled')->whereBetween('scheduled_date', [$today, now()->addDays(7)->toDateString()])->count(),
            'unpaid_total' => (float) LiftBill::whereIn('status', ['unpaid', 'partial'])->selectRaw('IFNULL(SUM(total_amount - paid_amount),0) AS d')->value('d'),
            'unbilled_jobs' => LiftJob::where('status', 'completed')->where('is_billable', 1)->whereNull('bill_id')->count(),
        ];
        $upcoming = LiftJob::with(['unit', 'customer'])->where('status', 'scheduled')->orderBy('scheduled_date')->limit(10)->get();
        $dueBills = LiftBill::with('customer')->whereIn('status', ['unpaid', 'partial'])->orderBy('bill_date')->limit(10)->get();

        return view('pages.lift.dashboard', compact('stats', 'upcoming', 'dueBills'));
    }
}
