
<x-default-layout>

    <div id="kt_app_content" class="app-content flex-column-fluid my-5">
        <div id="kt_app_content_container" class="app-container">

            @include('pages.lift._alerts')

            <div class="card card-flush mb-5">

                <div class="card-header align-items-center py-5">
                    <div class="card-title">
                        <h2>
                            Contract {{ $contract->contract_no }}

                            @if ($contract->status === 'cancelled')
                                <span class="badge badge-light-secondary">Cancelled</span>
                            @endif
                        </h2>
                    </div>

                    <div class="card-toolbar gap-3">

                        <a href="{{ route('lift.contracts.index') }}" class="btn btn-sm btn-light">
                            Back
                        </a>

                        @can('write lift service')
                            @if ($contract->status === 'active')
                                <form method="POST"
                                      action="{{ route('lift.contracts.cancel', $contract->id) }}"
                                      onsubmit="return confirm('Are you sure you want to cancel this contract? All future scheduled visits will also be cancelled.')">

                                    @csrf

                                    <button class="btn btn-sm btn-light-danger">
                                        Cancel Contract
                                    </button>
                                </form>
                            @endif
                        @endcan

                    </div>
                </div>

                <div class="card-body pt-0">

                    <div class="row g-4">

                        <div class="col-md-3">
                            <b>Customer</b><br>
                            {{ $contract->customer->account_name ?? '' }}
                        </div>

                        <div class="col-md-3">
                            <b>Contract Period</b><br>
                            {{ $contract->start_date->format('d-m-Y') }}
                            →
                            {{ $contract->end_date->format('d-m-Y') }}
                        </div>

                        <div class="col-md-3">
                            <b>Billing Details</b><br>
                            {{ ucfirst(str_replace('_', ' ', $contract->billing_cycle)) }}
                            — {{ number_format($contract->fee_per_cycle, 2) }} ৳
                        </div>

                        <div class="col-md-3">
                            <b>Visits Per Year</b><br>
                            {{ $contract->visits_per_year }} (Per Lift)
                        </div>

                        <div class="col-md-12">
                            <b>Covered Lifts:</b>

                            @foreach ($contract->units as $u)
                                <span class="badge badge-light-primary me-1">
                                    {{ $u->lift_code ? $u->lift_code . ' — ' : '' }}{{ $u->site_name }}
                                </span>
                            @endforeach
                        </div>

                    </div>

                    @can('write lift service')

                        @if ($contract->status === 'active' && $contract->next_bill_date && $contract->next_bill_date->lte($contract->end_date))

                            <form method="POST"
                                  action="{{ route('lift.contracts.bill', $contract->id) }}"
                                  class="d-flex align-items-end gap-3 mt-6 p-4 bg-light rounded">

                                @csrf

                                <div>
                                    <label class="form-label mb-1">
                                        Next Billing Period Starts:
                                        <b>{{ $contract->next_bill_date->format('d-m-Y') }}</b>
                                    </label>

                                    <input type="date"
                                           name="bill_date"
                                           value="{{ date('Y-m-d') }}"
                                           class="form-control form-control-sm form-control-solid"
                                           required>
                                </div>

                                <button class="btn btn-sm btn-primary"
                                        onclick="return confirm('Generating this bill will create an entry in Finance. Do you want to continue?')">
                                    Generate Bill
                                </button>

                            </form>

                        @elseif ($contract->status === 'active')

                            <div class="text-success mt-5">
                                ✔ All contract periods have been billed.
                            </div>

                        @endif

                    @endcan

                </div>
            </div>

            <div class="row g-5">

                <div class="col-md-5">

                    <div class="card card-flush">

                        <div class="card-header">
                            <div class="card-title">
                                <h4>Contract Bills</h4>
                            </div>
                        </div>

                        <div class="card-body pt-0">

                            <table class="table table-sm table-bordered">

                                <thead>
                                    <tr>
                                        <th>Bill Number</th>
                                        <th>Billing Period</th>
                                        <th class="text-end">Total Amount</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>

                                <tbody>

                                    @forelse ($contract->bills as $b)

                                        <tr>
                                            <td>
                                                <a href="{{ route('lift.bills.show', $b->id) }}">
                                                    {{ $b->bill_no }}
                                                </a>
                                            </td>

                                            <td>
                                                {{ $b->period_from?->format('d-m-y') }}
                                                –
                                                {{ $b->period_to?->format('d-m-y') }}
                                            </td>

                                            <td class="text-end">
                                                {{ number_format($b->total_amount, 2) }}
                                            </td>

                                            <td>{{ ucfirst($b->status) }}</td>
                                        </tr>

                                    @empty

                                        <tr>
                                            <td colspan="4" class="text-center text-muted">
                                                No bills generated yet.
                                            </td>
                                        </tr>

                                    @endforelse

                                </tbody>

                            </table>

                        </div>
                    </div>

                </div>

                <div class="col-md-7">

                    <div class="card card-flush">

                        <div class="card-header">
                            <div class="card-title">
                                <h4>Service Visits / Jobs</h4>
                            </div>
                        </div>

                        <div class="card-body pt-0" style="max-height:480px;overflow:auto">

                            <table class="table table-sm table-bordered">

                                <thead>
                                    <tr>
                                        <th>Scheduled Date</th>
                                        <th>Job Number / Type</th>
                                        <th>Lift / Site</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>

                                <tbody>

                                    @foreach ($jobs as $j)

                                        <tr class="{{ $j->status === 'scheduled' && $j->scheduled_date->lt(today()) ? 'table-danger' : '' }}">

                                            <td>
                                                {{ $j->scheduled_date->format('d-m-Y') }}
                                            </td>

                                            <td>
                                                <a href="{{ route('lift.jobs.show', $j->id) }}">
                                                    {{ $j->job_no }}
                                                </a>

                                                <small class="text-muted">
                                                    {{ ucfirst(str_replace('_', ' ', $j->job_type)) }}
                                                </small>
                                            </td>

                                            <td>
                                                {{ $j->unit->site_name ?? '' }}
                                            </td>

                                            <td>
                                                {{ ucfirst($j->status) }}
                                            </td>

                                        </tr>

                                    @endforeach

                                </tbody>

                            </table>

                        </div>
                    </div>

                </div>

            </div>

        </div>
    </div>

</x-default-layout>
