<?php

namespace App\Http\Controllers\Lift;

use App\Models\Lift\LiftContract;
use App\Models\Lift\LiftJob;
use App\Models\Lift\LiftUnit;
use App\Services\Lift\LiftBillingService;
use Illuminate\Http\Request;

class LiftContractController extends LiftBaseController
{
    function __construct(private LiftBillingService $service)
    {
        $this->guardPermissions(['index', 'show', 'unitsByCustomer']);
    }

    public function index()
    {
        $contracts = LiftContract::with('customer')->withCount('units')->orderByDesc('id')->get();
        return view('pages.lift.contracts.index', compact('contracts'));
    }

    public function create()
    {
        return view('pages.lift.contracts.form', ['customers' => $this->customers()]);
    }

    /** customer select korle tar lift gulo (ajax) */
    public function unitsByCustomer($customerId)
    {
        return response()->json(
            LiftUnit::where('customer_id', $customerId)->where('status', 1)->orderBy('id')
                ->get(['id', 'lift_code', 'site_name', 'brand'])
        );
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'customer_id' => 'required|integer|exists:finance_accounts,id',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'billing_cycle' => 'required|in:monthly,quarterly,half_yearly,yearly',
            'fee_per_cycle' => 'required|numeric|min:0.01',
            'visits_per_year' => 'required|integer|min:0|max:365',
            'unit_ids' => 'required|array|min:1',
            'unit_ids.*' => 'integer',
            'terms' => 'nullable|string',
        ]);

        return $this->run(
            fn() => $this->service->createContract($data, $data['unit_ids'], $this->user()),
            'AMC contract created, visit schedule o toiri hoyeche.',
            fn($c) => redirect()->route('lift.contracts.show', $c->id)
        );
    }

    public function show(LiftContract $contract)
    {
        $contract->load(['customer', 'units', 'bills' => fn($q) => $q->orderByDesc('id')]);
        $jobs = LiftJob::with('unit')->where('contract_id', $contract->id)->orderBy('scheduled_date')->get();
        return view('pages.lift.contracts.show', compact('contract', 'jobs'));
    }

    public function generateBill(Request $request, LiftContract $contract)
    {
        $data = $request->validate(['bill_date' => 'required|date']);
        return $this->run(
            fn() => $this->service->createContractBill($contract->id, $data['bill_date'], $this->user()),
            'AMC bill toiri hoyeche, Finance e entry hoyeche.',
            fn($bill) => redirect()->route('lift.bills.show', $bill->id)
        );
    }

    /** Contract bondho: future scheduled visit gulo cancel (bill/entry bodlay na) */
    public function cancel(LiftContract $contract)
    {
        if ($contract->status !== 'active') {
            return back()->withErrors(['error' => 'Contract active na.']);
        }
        $contract->update(['status' => 'cancelled']);
        LiftJob::where('contract_id', $contract->id)->where('status', 'scheduled')->where('job_type', 'amc_visit')->update(['status' => 'cancelled']);
        return back()->with(['message' => 'Contract cancelled.', 'alert-type' => 'success']);
    }
}
