
<x-default-layout>

    <div id="kt_app_content" class="app-content flex-column-fluid my-5">
        <div id="kt_app_content_container" class="app-container">

            @include('pages.lift._alerts')

            <div class="card card-flush mb-5" id="bill_print">

                <div class="card-header align-items-center py-5">

                    <div class="card-title">
                        <h2>
                            Bill {{ $bill->bill_no }}

                            <span class="badge badge-light-{{ ['paid' => 'success', 'partial' => 'warning', 'unpaid' => 'danger', 'cancelled' => 'secondary'][$bill->status] ?? 'secondary' }}">
                                {{ ucfirst($bill->status) }}
                            </span>
                        </h2>
                    </div>

                    <div class="card-toolbar gap-3 d-print-none">

                        <button class="btn btn-sm btn-light-primary" onclick="window.print()">
                            Print
                        </button>

                        <a href="{{ route('lift.bills.index') }}" class="btn btn-sm btn-light">
                            Back
                        </a>

                    </div>
                </div>

                <div class="card-body pt-0">

                    <div class="row g-4 mb-6">

                        <div class="col-md-3">
                            <b>Customer</b><br>
                            {{ $bill->customer->account_name ?? '' }}
                        </div>

                        <div class="col-md-2">
                            <b>Bill Date</b><br>
                            {{ $bill->bill_date->format('d-m-Y') }}
                        </div>

                        <div class="col-md-3">
                            <b>Billing Reference</b><br>

                            @if ($bill->bill_type === 'amc')

                                AMC Contract:
                                <a href="{{ route('lift.contracts.show', $bill->contract_id) }}">
                                    {{ $bill->contract->contract_no ?? '' }}
                                </a>
                                <br>

                                <small>
                                    {{ $bill->period_from?->format('d-m-Y') }}
                                    to
                                    {{ $bill->period_to?->format('d-m-Y') }}
                                </small>

                            @else

                                Service Job:
                                <a href="{{ route('lift.jobs.show', $bill->job_id) }}">
                                    {{ $bill->job->job_no ?? '' }}
                                </a>

                            @endif
                        </div>

                        <div class="col-md-4">
                            <b>Finance Voucher</b><br>

                            {{ $bill->voucher_no }}

                            @if ($bill->cancel_voucher_no)
                                <br>
                                <small class="text-danger">
                                    Cancellation Voucher: {{ $bill->cancel_voucher_no }}
                                </small>
                            @endif
                        </div>

                    </div>

                    @if ($bill->job && $bill->job->parts->count())

                        <table class="table table-sm table-bordered">

                            <thead>
                                <tr>
                                    <th>Spare Part</th>
                                    <th class="text-end">Quantity</th>
                                    <th class="text-end">Unit Price</th>
                                    <th class="text-end">Total</th>
                                </tr>
                            </thead>

                            <tbody>

                                @foreach ($bill->job->parts as $p)
                                    <tr>
                                        <td>{{ $p->product->product_name ?? '' }}</td>
                                        <td class="text-end">{{ $p->quantity + 0 }}</td>
                                        <td class="text-end">{{ number_format($p->unit_price, 2) }}</td>
                                        <td class="text-end">{{ number_format($p->total_amount, 2) }}</td>
                                    </tr>
                                @endforeach

                            </tbody>

                        </table>

                    @endif

                    <table class="table table-sm table-bordered w-50 ms-auto">

                        <tr>
                            <td>Service Amount</td>
                            <td class="text-end">
                                {{ number_format($bill->service_amount, 2) }}
                            </td>
                        </tr>

                        <tr>
                            <td>Spare Parts Amount</td>
                            <td class="text-end">
                                {{ number_format($bill->parts_amount, 2) }}
                            </td>
                        </tr>

                        <tr>
                            <td>Discount</td>
                            <td class="text-end">
                                ({{ number_format($bill->discount, 2) }})
                            </td>
                        </tr>

                        <tr>
                            <th>Grand Total</th>
                            <th class="text-end">
                                {{ number_format($bill->total_amount, 2) }}
                            </th>
                        </tr>

                        <tr>
                            <td>Paid Amount</td>
                            <td class="text-end">
                                {{ number_format($bill->paid_amount, 2) }}
                            </td>
                        </tr>

                        <tr>
                            <th>Outstanding Balance</th>
                            <th class="text-end">
                                {{ number_format($bill->due_amount, 2) }}
                            </th>
                        </tr>

                    </table>

                </div>
            </div>

            <div class="row g-5 d-print-none">

                <div class="col-md-6">

                    <div class="card card-flush">

                        <div class="card-header">
                            <div class="card-title">
                                <h4>Payment History</h4>
                            </div>
                        </div>

                        <div class="card-body pt-0">

                            <table class="table table-sm table-bordered">

                                <thead>
                                    <tr>
                                        <th>Payment Date</th>
                                        <th>Received In</th>
                                        <th>Voucher Number</th>
                                        <th class="text-end">Amount</th>
                                    </tr>
                                </thead>

                                <tbody>

                                    @forelse ($bill->payments as $p)

                                        <tr>
                                            <td>
                                                {{ $p->payment_date->format('d-m-Y') }}
                                            </td>

                                            <td>
                                                {{ $p->receiveAccount->account_name ?? '' }}
                                            </td>

                                            <td>
                                                {{ $p->voucher_no }}
                                            </td>

                                            <td class="text-end">
                                                {{ number_format($p->amount, 2) }}
                                            </td>
                                        </tr>

                                    @empty

                                        <tr>
                                            <td colspan="4" class="text-center text-muted">
                                                No payments received yet.
                                            </td>
                                        </tr>

                                    @endforelse

                                </tbody>

                            </table>

                            @can('write lift service')

                                @if ($bill->status !== 'cancelled' && $bill->due_amount > 0)

                                    <form method="POST"
                                          action="{{ route('lift.bills.pay', $bill->id) }}"
                                          class="row g-3 mt-2">

                                        @csrf

                                        <div class="col-md-4">
                                            <label class="form-label mb-1">Payment Date</label>

                                            <input type="date"
                                                   name="payment_date"
                                                   value="{{ date('Y-m-d') }}"
                                                   class="form-control form-control-sm form-control-solid"
                                                   required>
                                        </div>

                                        <div class="col-md-4">
                                            <label class="form-label mb-1">Payment Amount</label>

                                            <input type="number"
                                                   step="0.01"
                                                   min="0.01"
                                                   max="{{ $bill->due_amount }}"
                                                   name="amount"
                                                   value="{{ $bill->due_amount }}"
                                                   class="form-control form-control-sm form-control-solid"
                                                   required>
                                        </div>

                                        <div class="col-md-4">

                                            <label class="form-label mb-1">Receive In</label>

                                            <select name="receive_account_id"
                                                    class="form-select form-select-sm form-select-solid"
                                                    required>

                                                @foreach ($receiveAccounts as $id => $name)
                                                    <option value="{{ $id }}">
                                                        {{ $name }}
                                                    </option>
                                                @endforeach

                                            </select>

                                        </div>

                                        <div class="col-md-12">
                                            <input name="remarks"
                                                   placeholder="Remarks (Optional)"
                                                   class="form-control form-control-sm form-control-solid">
                                        </div>

                                        <div class="col-md-12">
                                            <button class="btn btn-sm btn-success"
                                                    onclick="return confirm('A payment receipt voucher will be created. Do you want to continue?')">
                                                Receive Payment
                                            </button>
                                        </div>

                                    </form>

                                @endif

                            @endcan

                        </div>
                    </div>

                </div>

                <div class="col-md-6">

                    @can('write lift service')

                        @if ($bill->status === 'unpaid')

                            <div class="card card-flush">

                                <div class="card-header">
                                    <div class="card-title">
                                        <h4>Cancel Bill</h4>
                                    </div>
                                </div>

                                <div class="card-body pt-0">

                                    <p class="text-muted">
                                        Only bills with no payments received can be cancelled.
                                        A reversal entry (Service Account Dr / Customer Cr)
                                        will be created in Finance.
                                        For AMC bills, only the latest contract bill can be cancelled.
                                    </p>

                                    <form method="POST"
                                          action="{{ route('lift.bills.cancel', $bill->id) }}"
                                          class="d-flex gap-3 align-items-end">

                                        @csrf

                                        <div>
                                            <label class="form-label mb-1">Cancellation Date</label>

                                            <input type="date"
                                                   name="cancel_date"
                                                   value="{{ date('Y-m-d') }}"
                                                   class="form-control form-control-sm form-control-solid"
                                                   required>
                                        </div>

                                        <button class="btn btn-sm btn-light-danger"
                                                onclick="return confirm('Are you sure you want to cancel this bill?')">
                                            Cancel Bill
                                        </button>

                                    </form>

                                </div>
                            </div>

                        @endif

                    @endcan

                </div>

            </div>

        </div>
    </div>

</x-default-layout>
