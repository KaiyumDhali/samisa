
<x-default-layout>
    <div id="kt_app_content" class="app-content flex-column-fluid my-5">
        <div id="kt_app_content_container" class="app-container">
            @include('pages.lift._alerts')

            <div class="card card-flush">
                <div class="card-header align-items-center py-5">
                    <div class="card-title">
                        <h2>Service Jobs</h2>
                    </div>

                    <div class="card-toolbar gap-3">
                        <form method="GET" class="d-flex gap-2 align-items-end">
                            <select name="status" class="form-select form-select-sm form-select-solid">
                                <option value="">All Statuses</option>
                                @foreach (['scheduled', 'completed', 'cancelled'] as $s)
                                    <option value="{{ $s }}" @selected(($filters['status'] ?? '') === $s)>
                                        {{ ucfirst($s) }}
                                    </option>
                                @endforeach
                            </select>

                            <input type="date" name="from"
                                value="{{ $filters['from'] ?? '' }}"
                                class="form-control form-control-sm form-control-solid"
                                title="From Date">

                            <input type="date" name="to"
                                value="{{ $filters['to'] ?? '' }}"
                                class="form-control form-control-sm form-control-solid"
                                title="To Date">

                            <button type="submit" class="btn btn-sm btn-light-primary">
                                Filter
                            </button>
                        </form>

                        @can('write lift service')
                            <a href="{{ route('lift.jobs.create') }}" class="btn btn-sm btn-primary">
                                + New Job
                            </a>
                        @endcan
                    </div>
                </div>

                <div class="card-body pt-0">
                    <table class="table table-bordered table-sm align-middle">
                        <thead>
                            <tr>
                                <th>Job Number</th>
                                <th>Scheduled Date</th>
                                <th>Job Type</th>
                                <th>Customer / Lift</th>
                                <th>Technician</th>
                                <th>Status</th>
                                <th>Bill</th>
                            </tr>
                        </thead>

                        <tbody>
                            @forelse ($jobs as $j)
                                <tr class="{{ $j->status === 'scheduled' && $j->scheduled_date->lt(today()) ? 'table-danger' : '' }}">
                                    <td>
                                        <a href="{{ route('lift.jobs.show', $j->id) }}">
                                            {{ $j->job_no }}
                                        </a>
                                    </td>

                                    <td>{{ $j->scheduled_date->format('d-m-Y') }}</td>

                                    <td>{{ ucfirst(str_replace('_', ' ', $j->job_type)) }}</td>

                                    <td>
                                        {{ $j->customer->account_name ?? '' }}
                                        <br>
                                        <small class="text-muted">
                                            {{ $j->unit->site_name ?? '' }}
                                        </small>
                                    </td>

                                    <td>{{ $j->technician_name }}</td>

                                    <td>{{ ucfirst($j->status) }}</td>

                                    <td>
                                        @if ($j->bill_id)
                                            <a href="{{ route('lift.bills.show', $j->bill_id) }}">
                                                View Bill
                                            </a>
                                        @elseif ($j->status === 'completed' && $j->is_billable)
                                            <span class="text-warning">
                                                Not Billed Yet
                                            </span>
                                        @else
                                            —
                                        @endif
                                    </td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="7" class="text-center text-muted">
                                        No service jobs found.
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
