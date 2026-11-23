
<x-default-layout>
    <div id="kt_app_content" class="app-content flex-column-fluid my-5">
        <div id="kt_app_content_container" class="app-container">
            @include('pages.lift._alerts')

            <div class="card card-flush">
                <div class="card-header align-items-center py-5">
                    <div class="card-title">
                        <h2>Lifts</h2>
                    </div>

                    <div class="card-toolbar gap-3">
                        <form method="GET" class="d-flex gap-4">
                            <select name="customer_id" class="form-select form-select-sm form-select-solid" onchange="this.form.submit()" data-control="select2" >
                                <option value="">All Customers</option>
                                @foreach ($customers as $id => $name)
                                    <option value="{{ $id }}" @selected($customerId == $id)>
                                        {{ $name }}
                                    </option>
                                @endforeach
                            </select>
                        </form>

                        @can('write lift service')
                            <a href="{{ route('lift.units.create') }}" class="btn btn-sm btn-primary">
                                + Add Lift
                            </a>
                        @endcan
                    </div>
                </div>

                <div class="card-body pt-0">
                    <table class="table table-bordered table-sm align-middle">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Lift Code</th>
                                <th>Customer</th>
                                <th>Site</th>
                                <th>Brand / Model</th>
                                <th>Capacity / Floors</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>

                        <tbody>
                            @forelse ($units as $u)
                                <tr>
                                    <td>{{ $u->id }}</td>
                                    <td>{{ $u->lift_code }}</td>
                                    <td>{{ $u->customer->account_name ?? '' }}</td>
                                    <td>
                                        {{ $u->site_name }}
                                        <br>
                                        <small class="text-muted">{{ $u->site_address }}</small>
                                    </td>
                                    <td>{{ $u->brand }} {{ $u->model }}</td>
                                    <td>{{ $u->capacity_persons }} / {{ $u->floors }}</td>
                                    <td>
                                        {!! $u->status
                                            ? '<span class="badge badge-light-success">Active</span>'
                                            : '<span class="badge badge-light-secondary">Inactive</span>' !!}
                                    </td>
                                    <td>
                                        @can('write lift service')
                                            <a href="{{ route('lift.units.edit', $u->id) }}"
                                               class="btn btn-sm btn-light-primary py-1">
                                                Edit
                                            </a>
                                        @endcan
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="8" class="text-center text-muted">
                                        No lifts found.
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
