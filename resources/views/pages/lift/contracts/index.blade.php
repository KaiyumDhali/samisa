
<x-default-layout>

    <div id="kt_app_content" class="app-content flex-column-fluid my-5">
        <div id="kt_app_content_container" class="app-container">

            @include('pages.lift._alerts')

            <div class="card card-flush">

                <div class="card-header align-items-center py-5">
                    <div class="card-title">
                        <h2>AMC Contracts</h2>
                    </div>

                    <div class="card-toolbar">
                        @can('write lift service')
                            <a href="{{ route('lift.contracts.create') }}" class="btn btn-sm btn-primary">
                                + New Contract
                            </a>
                        @endcan
                    </div>
                </div>

                <div class="card-body pt-0">

                    <table class="table table-bordered table-sm align-middle">

                        <thead>
                            <tr>
                                <th>Contract Number</th>
                                <th>Customer</th>
                                <th>Contract Period</th>
                                <th>Number of Lifts</th>
                                <th>Billing Cycle</th>
                                <th class="text-end">Fee Per Cycle</th>
                                <th>Next Billing Date</th>
                                <th>Status</th>
                            </tr>
                        </thead>

                        <tbody>

                            @forelse ($contracts as $c)

                                @php($expired = $c->status === 'active' && $c->end_date->lt(today()))

                                <tr>
                                    <td>
                                        <a href="{{ route('lift.contracts.show', $c->id) }}">
                                            {{ $c->contract_no }}
                                        </a>
                                    </td>

                                    <td>{{ $c->customer->account_name ?? '' }}</td>

                                    <td>
                                        {{ $c->start_date->format('d-m-Y') }}
                                        →
                                        {{ $c->end_date->format('d-m-Y') }}
                                    </td>

                                    <td>{{ $c->units_count }}</td>

                                    <td>
                                        {{ ucfirst(str_replace('_', ' ', $c->billing_cycle)) }}
                                    </td>

                                    <td class="text-end">
                                        {{ number_format($c->fee_per_cycle, 2) }}
                                    </td>

                                    <td>
                                        {{ $c->next_bill_date && $c->next_bill_date->lte($c->end_date)
                                            ? $c->next_bill_date->format('d-m-Y')
                                            : '—' }}
                                    </td>

                                    <td>
                                        @if ($c->status === 'cancelled')
                                            <span class="badge badge-light-secondary">Cancelled</span>
                                        @elseif ($expired)
                                            <span class="badge badge-light-warning">Expired</span>
                                        @else
                                            <span class="badge badge-light-success">Active</span>
                                        @endif
                                    </td>
                                </tr>

                            @empty

                                <tr>
                                    <td colspan="8" class="text-center text-muted">
                                        No AMC contracts found.
                                    </td>
                                </tr>

                            @endforelse

                        </tbody>

                    </table>

                </div>
            </div>

        </div>
    </div>

</x-default-layout>
