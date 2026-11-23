<?php

namespace App\Http\Controllers\Lift;

use App\Models\Lift\LiftBill;
use App\Services\Lift\LiftBillingService;
use Illuminate\Http\Request;

class LiftBillController extends LiftBaseController
{
    function __construct(private LiftBillingService $service)
    {
        $this->guardPermissions(['index', 'show']);
    }

    public function index(Request $request)
    {
        $bills = LiftBill::with('customer')
            ->when($request->filled('status'), fn($q) => $q->where('status', $request->status))
            ->when($request->filled('customer_id'), fn($q) => $q->where('customer_id', $request->customer_id))
            ->orderByDesc('id')
            ->limit(500)
            ->get();

        return view('pages.lift.bills.index', [
            'bills' => $bills,
            'customers' => $this->customers(),
            'filters' => $request->only('status', 'customer_id')
        ]);
    }

    public function show(LiftBill $bill)
    {
        $bill->load([
            'customer',
            'contract',
            'job.parts.product',
            'payments.receiveAccount'
        ]);

        return view('pages.lift.bills.show', [
            'bill' => $bill,
            'receiveAccounts' => $this->receiveAccounts()
        ]);
    }

    public function pay(Request $request, LiftBill $bill)
    {
        $data = $request->validate([
            'payment_date' => 'required|date',
            'amount' => 'required|numeric|min:0.01',
            'receive_account_id' => 'required|integer',
            'remarks' => 'nullable|string|max:255',
        ]);

        return $this->run(
            fn() => $this->service->receivePayment(
                $bill->id,
                (float) $data['amount'],
                (int) $data['receive_account_id'],
                $data['payment_date'],
                $data['remarks'] ?? null,
                $this->user()
            ),
            'Payment received successfully. A receipt voucher has been created.'
        );
    }

    public function cancel(Request $request, LiftBill $bill)
    {
        $data = $request->validate([
            'cancel_date' => 'required|date'
        ]);

        return $this->run(
            fn() => $this->service->cancelBill(
                $bill->id,
                $data['cancel_date'],
                $this->user()
            ),
            'Bill cancelled successfully. A reversal entry has been created.'
        );
    }
}
