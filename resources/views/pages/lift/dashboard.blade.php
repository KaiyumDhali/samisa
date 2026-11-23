
<x-default-layout>
    <div id="kt_app_content" class="app-content flex-column-fluid my-5">
        <div id="kt_app_content_container" class="app-container">
            @include('pages.lift._alerts')

            <div class="row g-5 mb-5">
                @foreach ([
                    ['Active Lifts', $stats['units'], 'lift.units.index', ''],
                    ['Active AMC Contracts', $stats['active_contracts'], 'lift.contracts.index', ''],
                    ['Contracts Expiring (Next 30 Days)', $stats['expiring'], 'lift.contracts.index', $stats['expiring'] ? 'text-warning' : ''],
                    ['Overdue Service Jobs', $stats['overdue_jobs'], 'lift.jobs.index', $stats['overdue_jobs'] ? 'text-danger' : ''],
                    ['Upcoming Jobs (Next 7 Days)', $stats['week_jobs'], 'lift.jobs.index', ''],
                    ['Completed but Not Billed', $stats['unbilled_jobs'], 'lift.jobs.index', $stats['unbilled_jobs'] ? 'text-warning' : ''],
                    ['Outstanding Bills', number_format($stats['unpaid_total'], 2) . ' ৳', 'lift.bills.index', $stats['unpaid_total'] > 0 ? 'text-danger' : ''],
                ] as [$label, $value, $route, $cls])
                    <div class="col-md-3">
                        <a href="{{ route($route) }}" class="card p-8 text-decoration-none">
                            <h2 class="{{ $cls }}">{{ $value }}</h2>
                            <h6 class="text-gray-700 mb-0">{{ $label }}</h6>
                        </a>
                    </div>
                @endforeach
            </div>

            <div class="row g-5">
                <div class="col-md-6">
                    <div class="card card-flush">
                        <div class="card-header">
                            <div class="card-title">
                                <h4>Upcoming / Overdue Service Jobs</h4>
                            </div>
                        </div>
                        <div class="card-body pt-0">
                            <table class="table table-sm table-bordered align-middle">
                                <thead>
                                    <tr>
                                        <th>Date</th>
                                        <th>Job Number</th>
                                        <th>Lift / Customer</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @forelse ($upcoming as $j)
                                        <tr class="{{ $j->scheduled_date->lt(today()) ? 'table-danger' : '' }}">
                                            <td>{{ $j->scheduled_date->format('d-m-Y') }}</td>
                                            <td>
                                                <a href="{{ route('lift.jobs.show', $j->id) }}">{{ $j->job_no }}</a>
                                                <small class="text-muted">{{ $j->job_type }}</small>
                                            </td>
                                            <td>
                                                {{ $j->unit->site_name ?? '' }}
                                                <br>
                                                <small>{{ $j->customer->account_name ?? '' }}</small>
                                            </td>
                                        </tr>
                                    @empty
                                        <tr>
                                            <td colspan="3" class="text-center text-muted">
                                                No scheduled service jobs found.
                                            </td>
                                        </tr>
                                    @endforelse
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <div class="col-md-6">
                    <div class="card card-flush">
                        <div class="card-header">
                            <div class="card-title">
                                <h4>Outstanding Bills</h4>
                            </div>
                        </div>
                        <div class="card-body pt-0">
                            <table class="table table-sm table-bordered align-middle">
                                <thead>
                                    <tr>
                                        <th>Bill Number</th>
                                        <th>Customer</th>
                                        <th class="text-end">Due Amount</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    @forelse ($dueBills as $b)
                                        <tr>
                                            <td>
                                                <a href="{{ route('lift.bills.show', $b->id) }}">{{ $b->bill_no }}</a>
                                                <br>
                                                <small>{{ $b->bill_date->format('d-m-Y') }}</small>
                                            </td>
                                            <td>{{ $b->customer->account_name ?? '' }}</td>
                                            <td class="text-end">
                                                {{ number_format($b->due_amount, 2) }}
                                            </td>
                                        </tr>
                                    @empty
                                        <tr>
                                            <td colspan="3" class="text-center text-muted">
                                                No outstanding bills found.
                                            </td>
                                        </tr>
                                    @endforelse
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-default-layout>
