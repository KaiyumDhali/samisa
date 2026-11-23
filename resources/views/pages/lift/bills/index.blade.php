
<x-default-layout>

    <div id="kt_app_content" class="app-content flex-column-fluid my-5">
        <div id="kt_app_content_container" class="app-container">

            @include('pages.lift._alerts')

            <div class="card card-flush">

                <div class="card-header align-items-center py-5">

                    <div class="card-title">
                        <h2>Service Bills</h2>
                    </div>

                    <div class="card-toolbar">

    <form method="GET" class="d-flex flex-wrap align-items-center gap-2">

        <div class="w-175px w-md-200px">
            <select name="status" class="form-select form-select-sm form-select-solid"
                data-control="select2" data-hide-search="true" data-placeholder="All Statuses">
                <option value="">All Statuses</option>

                @foreach (['unpaid', 'partial', 'paid', 'cancelled'] as $s)
                    <option value="{{ $s }}" @selected(($filters['status'] ?? '') === $s)>
                        {{ ucfirst($s) }}
                    </option>
                @endforeach
            </select>
        </div>

        <div class="w-200px w-md-250px">
            <select name="customer_id" class="form-select form-select-sm form-select-solid"
                data-control="select2" data-placeholder="All Customers">
                <option value="">All Customers</option>

                @foreach ($customers as $id => $name)
                    <option value="{{ $id }}" @selected(($filters['customer_id'] ?? '') == $id)>
                        {{ $name }}
                    </option>
                @endforeach
            </select>
        </div>

        <button type="submit" class="btn btn-sm btn-light-primary">
            Filter
        </button>

    </form>

</div>
                </div>

                <div class="card-body pt-0">

                    <table class="table table-bordered table-sm align-middle">

                        <thead>
                            <tr>
                                <th>Bill Number</th>
                                <th>Bill Date</th>
                                <th>Customer</th>
                                <th>Bill Type</th>
                                <th class="text-end">Total Amount</th>
                                <th class="text-end">Paid Amount</th>
                                <th class="text-end">Outstanding Balance</th>
                                <th>Status</th>
                            </tr>
                        </thead>

                        <tbody>

                            @php($tot = 0)

                            @forelse ($bills as $b)

                                @php($tot += $b->due_amount)

                                <tr class="{{ $b->status === 'cancelled' ? 'text-muted text-decoration-line-through' : '' }}">

                                    <td>
                                        <a href="{{ route('lift.bills.show', $b->id) }}">
                                            {{ $b->bill_no }}
                                        </a>
                                    </td>

                                    <td>
                                        {{ $b->bill_date->format('d-m-Y') }}
                                    </td>

                                    <td>
                                        {{ $b->customer->account_name ?? '' }}
                                    </td>

                                    <td>
                                        {{ $b->bill_type === 'amc' ? 'AMC Contract' : 'Service Job' }}
                                    </td>

                                    <td class="text-end">
                                        {{ number_format($b->total_amount, 2) }}
                                    </td>

                                    <td class="text-end">
                                        {{ number_format($b->paid_amount, 2) }}
                                    </td>

                                    <td class="text-end">
                                        {{ number_format($b->due_amount, 2) }}
                                    </td>

                                    <td>
                                        {{ ucfirst($b->status) }}
                                    </td>

                                </tr>

                            @empty

                                <tr>
                                    <td colspan="8" class="text-center text-muted">
                                        No service bills found.
                                    </td>
                                </tr>

                            @endforelse

                        </tbody>

                        <tfoot>
                            <tr>
                                <th colspan="6" class="text-end">
                                    Total Outstanding Balance
                                </th>

                                <th class="text-end">
                                    {{ number_format($tot, 2) }}
                                </th>

                                <th></th>
                            </tr>
                        </tfoot>

                    </table>

                </div>
            </div>

        </div>
    </div>

</x-default-layout>
