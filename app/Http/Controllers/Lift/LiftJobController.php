<?php

namespace App\Http\Controllers\Lift;

use App\Models\Lift\LiftContract;
use App\Models\Lift\LiftJob;
use App\Models\Lift\LiftUnit;
use App\Models\Product;
use App\Services\Lift\LiftBillingService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LiftJobController extends LiftBaseController
{
    function __construct(private LiftBillingService $service)
    {
        $this->guardPermissions(['index', 'show']);
    }

    public function index(Request $request)
    {
        $jobs = LiftJob::with(['unit', 'customer'])
            ->when($request->filled('status'), fn($q) => $q->where('status', $request->status))
            ->when($request->filled('from'), fn($q) => $q->whereDate('scheduled_date', '>=', $request->from))
            ->when($request->filled('to'), fn($q) => $q->whereDate('scheduled_date', '<=', $request->to))
            ->orderByRaw("CASE WHEN status='scheduled' THEN 0 ELSE 1 END")
            ->orderBy('scheduled_date')
            ->limit(500)
            ->get();

        return view('pages.lift.jobs.index', [
            'jobs' => $jobs,
            'filters' => $request->only('status', 'from', 'to')
        ]);
    }

    public function create()
    {
        $units = LiftUnit::with('customer')
            ->where('status', 1)
            ->orderBy('customer_id')
            ->get();

        $contracts = LiftContract::where('status', 'active')
            ->orderByDesc('id')
            ->get(['id', 'contract_no', 'customer_id']);

        return view('pages.lift.jobs.form', compact('units', 'contracts'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'lift_unit_id' => 'required|integer|exists:lift_units,id',
            'contract_id' => 'nullable|integer|exists:lift_amc_contracts,id',
            'job_type' => 'required|in:amc_visit,repair,breakdown',
            'scheduled_date' => 'required|date',
            'technician_name' => 'nullable|string|max:100',
            'technician_mobile' => 'nullable|string|max:30',
            'problem' => 'nullable|string',
        ]);

        return $this->run(
            fn() => $this->service->createJob($data, $this->user()),
            'Service job created successfully.',
            fn($job) => redirect()->route('lift.jobs.show', $job->id)
        );
    }

    public function show(LiftJob $job)
    {
        $job->load([
            'unit',
            'customer',
            'contract',
            'parts.product',
            'bill'
        ]);

        $products = Product::orderBy('product_name')
            ->get(['id', 'product_name', 'sales_price']);

        $warehouses = DB::table('warehouses')
            ->where('status', 1)
            ->orderBy('name')
            ->pluck('name', 'id');

        return view('pages.lift.jobs.show', compact('job', 'products', 'warehouses'));
    }

    public function complete(Request $request, LiftJob $job)
    {
        $data = $request->validate([
            'completed_date' => 'required|date',
            'work_done' => 'nullable|string',
            'technician_name' => 'nullable|string|max:100',
            'technician_mobile' => 'nullable|string|max:30',
            'is_billable' => 'nullable|boolean',
            'service_charge' => 'nullable|numeric|min:0',
            'parts' => 'nullable|array',
            'parts.*.product_id' => 'nullable|integer',
            'parts.*.warehouse_id' => 'nullable|integer',
            'parts.*.quantity' => 'nullable|numeric|min:0',
            'parts.*.unit_price' => 'nullable|numeric|min:0',
        ]);

        return $this->run(
            fn() => $this->service->completeJob(
                $job->id,
                $data,
                $data['parts'] ?? [],
                $this->user()
            ),
            'Service job completed successfully. Spare parts stock has been updated.'
        );
    }

    public function cancel(LiftJob $job)
    {
        return $this->run(
            fn() => $this->service->cancelJob($job->id),
            'Service job cancelled successfully.'
        );
    }

    public function bill(Request $request, LiftJob $job)
    {
        $data = $request->validate([
            'bill_date' => 'required|date',
            'discount' => 'nullable|numeric|min:0'
        ]);

        return $this->run(
            fn() => $this->service->createJobBill(
                $job->id,
                $data['bill_date'],
                (float) ($data['discount'] ?? 0),
                $this->user()
            ),
            'Bill generated successfully. The transaction has been recorded in Finance.',
            fn($bill) => redirect()->route('lift.bills.show', $bill->id)
        );
    }
}
