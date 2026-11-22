<x-default-layout>
    @php
        $modeLabels = [
            'manual' => 'Manual only',
            'auto_review' => 'Auto + HR review',
            'auto_approve' => 'Auto + auto approve',
        ];
        $statusBadge = [
            'draft' => 'badge-light-warning',
            'approved' => 'badge-light-success',
            'rejected' => 'badge-light-danger',
        ];
    @endphp

    <div class="col-xl-12 px-5">
        @if ($errors->any())
            <div class="alert alert-danger"><ul class="mb-0">
                @foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach
            </ul></div>
        @endif
        @if (session('message'))
            <div class="alert alert-{{ session('alert-type') }}">{{ session('message') }}</div>
        @endif
    </div>

    <div class="app-toolbar"><div class="app-container d-flex flex-stack">
        <h3>Overtime</h3>
        <span class="badge badge-light-primary fs-7">Mode: {{ $modeLabels[$settings->mode] ?? $settings->mode }}</span>
    </div></div>

    {{-- Month filter --}}
    <div class="col-xl-12 py-3">
        <div class="card">
            <div class="card-body py-4">
                <form method="GET" action="{{ route('overtime.index') }}" class="d-flex align-items-center gap-3">
                    <label class="form-label mb-0">Month</label>
                    <input type="month" name="month" value="{{ $month }}" class="form-control form-control-sm w-200px">
                    <button class="btn btn-sm btn-primary">Show</button>
                    @if ($locked)
                        <span class="badge badge-light-danger">Salary approved. Overtime is locked for this month.</span>
                    @endif
                </form>
            </div>
        </div>
    </div>

    {{-- Summary --}}
    <div class="col-xl-12 py-3">
        <div class="row g-3">
            <div class="col-md-4"><div class="card"><div class="card-body py-4">
                <div class="text-muted fs-7">Waiting for approval (draft)</div>
                <div class="fs-2 fw-bold">{{ $draftCount }}</div>
            </div></div></div>
            <div class="col-md-4"><div class="card"><div class="card-body py-4">
                <div class="text-muted fs-7">Approved hours</div>
                <div class="fs-2 fw-bold">{{ number_format($approvedHours, 2) }}</div>
            </div></div></div>
            <div class="col-md-4"><div class="card"><div class="card-body py-4">
                <div class="text-muted fs-7">Approved amount (estimate)</div>
                <div class="fs-2 fw-bold">{{ number_format($approvedAmount, 2) }}</div>
            </div></div></div>
        </div>
    </div>

    <div class="col-xl-12 py-3">
        <div class="card">
            <div class="card-header">
                <ul class="nav nav-tabs nav-line-tabs fs-6 border-0 mt-3">
                    <li class="nav-item"><a class="nav-link active" data-bs-toggle="tab" href="#tab_list">Overtime</a></li>
                    <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#tab_eligible">Eligible Employees</a></li>
                    <li class="nav-item"><a class="nav-link" data-bs-toggle="tab" href="#tab_settings">Settings</a></li>
                </ul>
            </div>
            <div class="card-body tab-content">

                {{-- TAB 1: LIST --}}
                <div class="tab-pane fade show active" id="tab_list">

                    @if (!$locked)
                        <div class="d-flex flex-wrap gap-2 mb-4">
                            @can('create monthly salary')
                                @if ($settings->mode !== 'manual')
                                    <form method="POST" action="{{ route('overtime.generate') }}">
                                        @csrf
                                        <input type="hidden" name="month" value="{{ $month }}">
                                        <button class="btn btn-sm btn-primary">Generate from attendance</button>
                                    </form>
                                @else
                                    <span class="text-muted fs-7 align-self-center">Mode is "Manual only". Switch to an Auto mode in Settings to generate from attendance.</span>
                                @endif
                            @endcan
                            @can('write monthly salary')
                                @if ($draftCount > 0)
                                    <form method="POST" action="{{ route('overtime.bulk_status') }}"
                                          onsubmit="return confirm('Approve all draft rows of this month?');">
                                        @csrf
                                        <input type="hidden" name="month" value="{{ $month }}">
                                        <button name="action" value="approve_all" class="btn btn-sm btn-success">Approve all drafts</button>
                                    </form>
                                @endif
                            @endcan
                        </div>
                    @endif

                    {{-- Bulk form (checkboxes and buttons below point to it with the form attribute) --}}
                    <form id="bulkForm" method="POST" action="{{ route('overtime.bulk_status') }}">
                        @csrf
                        <input type="hidden" name="month" value="{{ $month }}">
                    </form>

                    @if (!$locked)
                    @can('write monthly salary')
                        <div class="d-flex gap-2 mb-3">
                            <button form="bulkForm" name="action" value="approve" class="btn btn-sm btn-light-success">Approve selected</button>
                            <button form="bulkForm" name="action" value="reject" class="btn btn-sm btn-light-danger">Reject selected</button>
                            <button form="bulkForm" name="action" value="reset" class="btn btn-sm btn-light">Back to draft</button>
                        </div>
                    @endcan
                    @endif

                    <div class="table-responsive">
                    <table class="table table-bordered table-striped align-middle fs-7">
                        <thead>
                            <tr>
                                <th class="w-30px"><input type="checkbox" id="selectAll"></th>
                                <th>Date</th>
                                <th>Code</th>
                                <th>Employee</th>
                                <th>In</th>
                                <th>Out</th>
                                <th>Source</th>
                                <th>Status</th>
                                <th>Hours / Rate (edit)</th>
                                <th class="text-end">Amount</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse ($overtimes as $o)
                                <tr>
                                    <td><input type="checkbox" name="ids[]" value="{{ $o->id }}" form="bulkForm" class="row-check"></td>
                                    <td>{{ $o->work_date ? $o->work_date->format('d M Y') : '-' }}</td>
                                    <td>{{ $o->employee->employee_code ?? '' }}</td>
                                    <td>{{ $o->employee->employee_name ?? '' }}
                                        <div class="text-muted fs-8">{{ $o->title }}</div>
                                    </td>
                                    <td>{{ $o->punch_in ? substr($o->punch_in, 0, 5) : '-' }}</td>
                                    <td>{{ $o->punch_out ? substr($o->punch_out, 0, 5) : '-' }}</td>
                                    <td><span class="badge {{ $o->source === 'auto' ? 'badge-light-info' : 'badge-light-primary' }}">{{ ucfirst($o->source) }}</span></td>
                                    <td><span class="badge {{ $statusBadge[$o->status] ?? 'badge-light' }}">{{ ucfirst($o->status) }}</span></td>
                                    <td style="min-width: 250px;">
                                        @if (!$locked)
                                        @can('write monthly salary')
                                            <form method="POST" action="{{ route('overtime.update', $o->id) }}" class="d-flex gap-1">
                                                @csrf @method('PUT')
                                                <input type="number" step="0.25" min="0.25" max="24" name="hours" value="{{ $o->hours + 0 }}"
                                                       class="form-control form-control-sm w-80px" title="Hours">
                                                <input type="number" step="0.01" min="0" name="rate" value="{{ $o->rate ? $o->rate + 0 : '' }}"
                                                       placeholder="auto: {{ number_format($o->calc_rate, 2) }}"
                                                       class="form-control form-control-sm w-120px" title="Rate per hour (empty = formula rate)">
                                                <button class="btn btn-sm btn-light-primary">Save</button>
                                            </form>
                                        @else
                                            {{ $o->calc_hours + 0 }} h x {{ number_format($o->calc_rate, 2) }}
                                        @endcan
                                        @else
                                            {{ $o->calc_hours + 0 }} h x {{ number_format($o->calc_rate, 2) }}
                                        @endif
                                    </td>
                                    <td class="text-end">{{ number_format($o->calc_amount, 2) }}</td>
                                    <td class="text-end text-nowrap">
                                        @if (!$locked)
                                        @can('write monthly salary')
                                            @if ($o->status !== 'approved')
                                                <form method="POST" action="{{ route('overtime.bulk_status') }}" class="d-inline">
                                                    @csrf
                                                    <input type="hidden" name="month" value="{{ $month }}">
                                                    <input type="hidden" name="ids[]" value="{{ $o->id }}">
                                                    <button name="action" value="approve" class="btn btn-sm btn-light-success">Approve</button>
                                                </form>
                                            @endif
                                            @if ($o->status === 'draft')
                                                <form method="POST" action="{{ route('overtime.bulk_status') }}" class="d-inline">
                                                    @csrf
                                                    <input type="hidden" name="month" value="{{ $month }}">
                                                    <input type="hidden" name="ids[]" value="{{ $o->id }}">
                                                    <button name="action" value="reject" class="btn btn-sm btn-light-warning">Reject</button>
                                                </form>
                                            @endif
                                            <form method="POST" action="{{ route('overtime.destroy', $o->id) }}" class="d-inline"
                                                  onsubmit="return confirm('Delete this row?');">
                                                @csrf @method('DELETE')
                                                <button class="btn btn-sm btn-light-danger">Delete</button>
                                            </form>
                                        @endcan
                                        @endif
                                    </td>
                                </tr>
                            @empty
                                <tr><td colspan="11" class="text-center">No overtime rows for this month.</td></tr>
                            @endforelse
                        </tbody>
                    </table>
                    </div>

                    {{-- Manual entry --}}
                    @if (!$locked)
                    @can('create monthly salary')
                        <hr class="my-6">
                        <h4 class="mb-4">Add manually</h4>
                        <form method="POST" action="{{ route('overtime.store') }}" class="row g-3">
                            @csrf
                            <div class="col-md-3">
                                <label class="form-label">Employee (active only)</label>
                                <select name="employee_id" class="form-select form-select-sm" required>
                                    <option value="">Select</option>
                                    @foreach ($eligible as $e)
                                        <option value="{{ $e->id }}">{{ $e->employee_code }} - {{ $e->employee_name }}</option>
                                    @endforeach
                                </select>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label">Date</label>
                                <input type="date" name="work_date" value="{{ $month }}-01" class="form-control form-control-sm" required>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label">Hours</label>
                                <input type="number" step="0.25" min="0.25" max="24" name="hours" class="form-control form-control-sm" required>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label">Rate / hour <small class="text-muted">(empty = formula)</small></label>
                                <input type="number" step="0.01" min="0" name="rate" class="form-control form-control-sm">
                            </div>
                            <div class="col-md-2">
                                <label class="form-label">Reason</label>
                                <input type="text" name="title" class="form-control form-control-sm" placeholder="Manual overtime">
                            </div>
                            <div class="col-md-1 d-flex align-items-end">
                                <button class="btn btn-sm btn-success w-100">Add</button>
                            </div>
                        </form>
                    @endcan
                    @endif
                </div>

                {{-- TAB 2: ELIGIBLE EMPLOYEES --}}
                <div class="tab-pane fade" id="tab_eligible">
                    <p class="text-muted fs-7">Only checked (Active) employees get overtime, both from attendance and manual entry. Turning an employee off does not delete overtime that was already approved.</p>
                    @can('write monthly salary')
                    <form method="POST" action="{{ route('overtime.eligibility') }}">
                        @csrf
                        <input type="hidden" name="month" value="{{ $month }}">
                        <table class="table table-bordered table-striped align-middle fs-7">
                            <thead>
                                <tr>
                                    <th class="w-60px"><input type="checkbox" id="selectAllEmp"> Active</th>
                                    <th>Code</th>
                                    <th>Employee</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach ($allEmployees as $e)
                                    <tr>
                                        <td><input type="checkbox" class="emp-check" name="active_ids[]" value="{{ $e->id }}" {{ $e->over_time ? 'checked' : '' }}></td>
                                        <td>{{ $e->employee_code }}</td>
                                        <td>{{ $e->employee_name }}</td>
                                    </tr>
                                @endforeach
                            </tbody>
                        </table>
                        <button class="btn btn-sm btn-primary">Save</button>
                    </form>
                    @else
                        <p>You do not have permission to change this.</p>
                    @endcan
                </div>

                {{-- TAB 3: SETTINGS --}}
                <div class="tab-pane fade" id="tab_settings">
                    @can('write monthly salary')
                    <form method="POST" action="{{ route('overtime.settings') }}" class="row g-3">
                        @csrf
                        <input type="hidden" name="month" value="{{ $month }}">
                        <div class="col-md-4">
                            <label class="form-label">Mode</label>
                            <select name="mode" class="form-select form-select-sm">
                                @foreach ($modeLabels as $key => $label)
                                    <option value="{{ $key }}" {{ $settings->mode === $key ? 'selected' : '' }}>{{ $label }}</option>
                                @endforeach
                            </select>
                            <div class="text-muted fs-8 mt-1">
                                Manual only: HR enters everything by hand.<br>
                                Auto + HR review: system creates drafts from attendance, HR approves.<br>
                                Auto + auto approve: system creates and approves directly.
                            </div>
                        </div>
                        <div class="col-md-2">
                            <label class="form-label">Ignore if less than (minutes)</label>
                            <input type="number" min="0" max="240" name="min_minutes" value="{{ $settings->min_minutes }}" class="form-control form-control-sm" required>
                        </div>
                        <div class="col-md-2">
                            <label class="form-label">Round down to (minutes)</label>
                            <input type="number" min="1" max="60" name="round_minutes" value="{{ $settings->round_minutes }}" class="form-control form-control-sm" required>
                        </div>
                        <div class="col-md-2">
                            <label class="form-label">Max hours / working day</label>
                            <input type="number" step="0.25" min="0.25" max="10" name="max_hours_per_day" value="{{ $settings->max_hours_per_day + 0 }}" class="form-control form-control-sm" required>
                        </div>
                        <div class="col-md-2">
                            <label class="form-label">Max hours / weekend or holiday</label>
                            <input type="number" step="0.25" min="0.25" max="16" name="holiday_max_hours" value="{{ $settings->holiday_max_hours + 0 }}" class="form-control form-control-sm" required>
                        </div>
                        <div class="col-md-4">
                            <div class="form-check form-switch">
                                <input class="form-check-input" type="checkbox" name="count_holiday_work" value="1" id="count_holiday_work"
                                    {{ $settings->count_holiday_work ? 'checked' : '' }}>
                                <label class="form-check-label" for="count_holiday_work">Count weekend / holiday attendance as overtime</label>
                            </div>
                        </div>
                        <div class="col-12">
                            <button class="btn btn-sm btn-primary">Save settings</button>
                        </div>
                    </form>
                    <hr class="my-6">
                    <p class="fs-7 text-muted mb-0">
                        Overtime rate per hour comes from the <strong>"Over Time"</strong> head in Payroll Formula
                        (default: <code>{Basic Salary}/208*2</code>). A rate typed on a row overrides it.
                        Office end time, weekend days and holidays come from the existing HR Admin setup.
                    </p>
                    @else
                        <p>You do not have permission to change this.</p>
                    @endcan
                </div>
            </div>
        </div>
    </div>

    <script>
        document.getElementById('selectAll')?.addEventListener('change', function () {
            document.querySelectorAll('.row-check').forEach(c => c.checked = this.checked);
        });
        document.getElementById('selectAllEmp')?.addEventListener('change', function () {
            document.querySelectorAll('.emp-check').forEach(c => c.checked = this.checked);
        });
    </script>
</x-default-layout>