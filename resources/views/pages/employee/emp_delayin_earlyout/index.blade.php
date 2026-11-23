<x-default-layout>
    @php
        $typeBadge = [
            'delay_in' => 'badge-light-warning',
            'early_out' => 'badge-light-info',
            'out_of_office' => 'badge-light-primary',
            'absences' => 'badge-light-danger',
        ];
        $statusBadge = [
            'pending' => 'badge-light-warning',
            'approved' => 'badge-light-success',
            'rejected' => 'badge-light-danger',
        ];

        // Re-open the modal when the server sends the user back to this page
        // (edit link, or validation errors after saving the form)
        $reopen = null;
        if ($editing) {
            $reopen = [
                'id' => $editing->id,
                'employee_id' => $editing->employee_id,
                'request_date' => $editing->request_date->format('Y-m-d'),
                'request_type' => $editing->request_type,
                'expected_time' => $editing->expected_time ? substr($editing->expected_time, 0, 5) : '',
                'reason' => $editing->reason,
                'approve_now' => false,
            ];
        } elseif ($errors->any() && old('_modal')) {
            $reopen = [
                'id' => old('_edit_id') ?: null,
                'employee_id' => old('employee_id'),
                'request_date' => old('request_date'),
                'request_type' => old('request_type', 'delay_in'),
                'expected_time' => old('expected_time'),
                'reason' => old('reason'),
                'approve_now' => (bool) old('approve_now'),
            ];
        }
    @endphp

    <div class="col-xl-12 px-5">
        {{-- Errors of the modal form are shown inside the modal --}}
        @if ($errors->any() && !old('_modal'))
            <div class="alert alert-danger"><ul class="mb-0">
                @foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach
            </ul></div>
        @endif
        @if (session('message'))
            <div class="alert alert-{{ session('alert-type') }}">{{ session('message') }}</div>
        @endif
    </div>

    <div class="app-toolbar w-100 px-5 py-3">
        <div class="d-flex align-items-center justify-content-between w-100">
            <h3 class="mb-0">Delay In / Early Out Applications</h3>
            @canany(['create delayin earlyout', 'write delayin earlyout'])
                <button type="button" class="btn btn-sm btn-primary ms-auto"
                        data-bs-toggle="modal" data-bs-target="#requestModal" data-mode="create">
                    + New application
                </button>
            @endcanany
        </div>
    </div>

    {{-- Filters --}}
    <div class="col-xl-12 py-3">
        <div class="card"><div class="card-body py-4">
            <form method="GET" action="{{ route('emp_delayin_earlyout.index') }}" class="d-flex flex-wrap align-items-center gap-3">
                <input type="month" name="month" value="{{ $month }}" class="form-control form-control-sm w-200px">
                <select name="status" class="form-select form-select-sm w-150px">
                    <option value="">All status</option>
                    @foreach (['pending' => 'Pending', 'approved' => 'Approved', 'rejected' => 'Rejected'] as $k => $l)
                        <option value="{{ $k }}" {{ $statusFilter == $k ? 'selected' : '' }}>{{ $l }}</option>
                    @endforeach
                </select>
                <select name="employee_id" class="form-select form-select-sm w-250px">
                    <option value="">All employees</option>
                    @foreach ($employees as $e)
                        <option value="{{ $e->id }}" {{ $employeeFilter == $e->id ? 'selected' : '' }}>{{ $e->employee_code }} - {{ $e->employee_name }}</option>
                    @endforeach
                </select>
                <button class="btn btn-sm btn-primary">Show</button>
                <span class="ms-auto">
                    <span class="badge badge-light-warning">Pending: {{ $counts['pending'] ?? 0 }}</span>
                    <span class="badge badge-light-success">Approved: {{ $counts['approved'] ?? 0 }}</span>
                    <span class="badge badge-light-danger">Rejected: {{ $counts['rejected'] ?? 0 }}</span>
                </span>
            </form>
        </div></div>
    </div>

    {{-- List --}}
    <div class="col-xl-12 py-3">
        <div class="card"><div class="card-body">
            <form id="bulkForm" method="POST" action="{{ route('emp_delayin_earlyout.decide') }}">
                @csrf
                <input type="hidden" name="month" value="{{ $month }}">
            </form>

            @can('write delayin earlyout')
                <div class="d-flex gap-2 mb-3">
                    <button form="bulkForm" name="action" value="approve" class="btn btn-sm btn-light-success">Approve selected</button>
                    <button form="bulkForm" name="action" value="reject" class="btn btn-sm btn-light-danger">Reject selected</button>
                    <button form="bulkForm" name="action" value="reset" class="btn btn-sm btn-light">Back to pending</button>
                </div>
            @endcan

            <div class="table-responsive">
            <table class="table table-bordered table-striped align-middle fs-7">
                <thead>
                    <tr>
                        <th class="w-30px"><input type="checkbox" id="selectAll"></th>
                        <th>Date</th>
                        <th>Code</th>
                        <th>Employee</th>
                        <th>Type</th>
                        <th>Time</th>
                        <th>Reason</th>
                        <th>Status</th>
                        <th>Decided by</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                    @forelse ($rows as $r)
                        <tr>
                            <td><input type="checkbox" name="ids[]" value="{{ $r->id }}" form="bulkForm" class="row-check"></td>
                            <td>{{ $r->request_date->format('d M Y') }}</td>
                            <td>{{ $r->employee->employee_code ?? '' }}</td>
                            <td>{{ $r->employee->employee_name ?? '' }}</td>
                            <td><span class="badge {{ $typeBadge[$r->request_type] ?? 'badge-light' }}">{{ $types[$r->request_type] ?? $r->request_type }}</span></td>
                            <td>{{ $r->expected_time ? substr($r->expected_time, 0, 5) : '-' }}</td>
                            <td>{{ $r->reason }}</td>
                            <td><span class="badge {{ $statusBadge[$r->status] ?? 'badge-light' }}">{{ ucfirst($r->status) }}</span></td>
                            <td>
                                {{ $r->decided_by ?? '-' }}
                                @if ($r->decided_at)
                                    <div class="text-muted fs-8">{{ $r->decided_at->format('d M Y H:i') }}</div>
                                @endif
                            </td>
                            <td class="text-end text-nowrap">
                                @can('write delayin earlyout')
                                    @if ($r->status !== 'approved')
                                        <form method="POST" action="{{ route('emp_delayin_earlyout.decide') }}" class="d-inline">
                                            @csrf
                                            <input type="hidden" name="month" value="{{ $month }}">
                                            <input type="hidden" name="ids[]" value="{{ $r->id }}">
                                            <button name="action" value="approve" class="btn btn-sm btn-light-success">Approve</button>
                                        </form>
                                    @endif
                                    @if ($r->status === 'pending')
                                        <form method="POST" action="{{ route('emp_delayin_earlyout.decide') }}" class="d-inline">
                                            @csrf
                                            <input type="hidden" name="month" value="{{ $month }}">
                                            <input type="hidden" name="ids[]" value="{{ $r->id }}">
                                            <button name="action" value="reject" class="btn btn-sm btn-light-warning">Reject</button>
                                        </form>
                                    @endif
                                    <button type="button" class="btn btn-sm btn-light-primary"
                                            data-bs-toggle="modal" data-bs-target="#requestModal" data-mode="edit"
                                            data-id="{{ $r->id }}"
                                            data-employee="{{ $r->employee_id }}"
                                            data-date="{{ $r->request_date->format('Y-m-d') }}"
                                            data-type="{{ $r->request_type }}"
                                            data-time="{{ $r->expected_time ? substr($r->expected_time, 0, 5) : '' }}"
                                            data-reason="{{ $r->reason }}">Edit</button>
                                    <form method="POST" action="{{ route('emp_delayin_earlyout.destroy', $r->id) }}" class="d-inline"
                                          onsubmit="return confirm('Delete this application?');">
                                        @csrf @method('DELETE')
                                        <button class="btn btn-sm btn-light-danger">Delete</button>
                                    </form>
                                @endcan
                            </td>
                        </tr>
                    @empty
                        <tr><td colspan="10" class="text-center">No applications for this month.</td></tr>
                    @endforelse
                </tbody>
            </table>
            </div>
            <p class="text-muted fs-8 mb-0">
                Only <strong>Approved</strong> applications are used in attendance reports and in the late count.
                One application per employee per day.
            </p>
        </div></div>
    </div>

    {{-- Application modal (used for both New and Edit) --}}
    @canany(['create delayin earlyout', 'write delayin earlyout'])
    <div class="modal fade" id="requestModal" tabindex="-1" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered mw-650px">
            <div class="modal-content">
                <form id="requestForm" method="POST" action="{{ route('emp_delayin_earlyout.store') }}">
                    @csrf
                    <input type="hidden" name="_method" id="form_method" value="PUT" disabled>
                    <input type="hidden" name="_modal" value="1">
                    <input type="hidden" name="_edit_id" id="edit_id" value="">

                    <div class="modal-header">
                        <h3 class="modal-title" id="modal_title">New application</h3>
                        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
                    </div>

                    <div class="modal-body">
                        @if ($errors->any() && old('_modal'))
                            <div class="alert alert-danger"><ul class="mb-0">
                                @foreach ($errors->all() as $error)<li>{{ $error }}</li>@endforeach
                            </ul></div>
                        @endif

                        <div class="row g-4">
                            <div class="col-12">
                                <label class="form-label required">Employee</label>
                                <select name="employee_id" id="f_employee" class="form-select form-select-sm"
                                        data-control="select2" data-dropdown-parent="#requestModal"
                                        data-placeholder="Select employee" required>
                                    <option value="">Select employee</option>
                                    @foreach ($employees as $e)
                                        <option value="{{ $e->id }}">{{ $e->employee_code }} - {{ $e->employee_name }}</option>
                                    @endforeach
                                </select>
                            </div>

                            <div class="col-md-6">
                                <label class="form-label required">Date</label>
                                <input type="date" name="request_date" id="f_date" class="form-control form-control-sm" required>
                            </div>

                            <div class="col-md-6">
                                <label class="form-label required">Type</label>
                                <select name="request_type" id="request_type" class="form-select form-select-sm" required>
                                    @foreach ($types as $key => $label)
                                        <option value="{{ $key }}">{{ $label }}</option>
                                    @endforeach
                                </select>
                            </div>

                            <div class="col-md-6" id="time_box">
                                <label class="form-label required" id="time_label">Expected time</label>
                                <input type="time" name="expected_time" id="expected_time" class="form-control form-control-sm">
                            </div>

                            <div class="col-12">
                                <label class="form-label">Reason</label>
                                <textarea name="reason" id="f_reason" rows="2" maxlength="255" class="form-control form-control-sm"
                                          placeholder="Why is this needed?"></textarea>
                            </div>

                            @can('write delayin earlyout')
                                <div class="col-12" id="approve_box">
                                    <div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" name="approve_now" value="1" id="approve_now" checked>
                                        <label class="form-check-label" for="approve_now">Approve now</label>
                                    </div>
                                    <div class="text-muted fs-8">If off, the application is saved as Pending and approved later from the list.</div>
                                </div>
                            @endcan
                        </div>
                    </div>

                    <div class="modal-footer">
                        <button type="button" class="btn btn-sm btn-light" data-bs-dismiss="modal">Cancel</button>
                        <button type="submit" class="btn btn-sm btn-primary" id="save_btn">Save</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    @endcanany

    <script>
        document.addEventListener('DOMContentLoaded', function () {
            var storeUrl = @json(route('emp_delayin_earlyout.store'));
            var updateUrl = @json(route('emp_delayin_earlyout.update', ['emp_delayin_earlyout' => ':id']));
            var pending = @json($reopen);

            var modalEl = document.getElementById('requestModal');
            var form = document.getElementById('requestForm');

            function todayLocal() {
                var d = new Date();
                return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0');
            }

            // Time field is needed only for Delay In and Early Out
            function updateTimeField() {
                var t = document.getElementById('request_type').value;
                var box = document.getElementById('time_box');
                var label = document.getElementById('time_label');
                var input = document.getElementById('expected_time');
                if (t === 'delay_in') {
                    box.style.display = '';
                    label.textContent = 'Expected arrival time';
                    input.required = true;
                } else if (t === 'early_out') {
                    box.style.display = '';
                    label.textContent = 'Leaving time';
                    input.required = true;
                } else {
                    box.style.display = 'none';
                    input.required = false;
                    input.value = '';
                }
            }

            // Fill the modal for a new or an existing application
            function fillForm(data) {
                var isEdit = !!data.id;
                document.getElementById('modal_title').textContent = isEdit ? 'Edit application' : 'New application';
                form.action = isEdit ? updateUrl.replace(':id', data.id) : storeUrl;
                document.getElementById('form_method').disabled = !isEdit;   // sends _method=PUT only when editing
                document.getElementById('edit_id').value = isEdit ? data.id : '';

                var emp = document.getElementById('f_employee');
                emp.value = data.employee_id || '';
                if (window.jQuery) { jQuery(emp).trigger('change'); }

                document.getElementById('f_date').value = data.request_date || '';
                document.getElementById('request_type').value = data.request_type || 'delay_in';
                document.getElementById('expected_time').value = data.expected_time || '';
                document.getElementById('f_reason').value = data.reason || '';

                var box = document.getElementById('approve_box');
                if (box) {
                    box.style.display = isEdit ? 'none' : '';
                    document.getElementById('approve_now').checked = isEdit ? false : (data.approve_now !== false);
                }
                document.getElementById('save_btn').textContent = isEdit ? 'Update' : 'Save';
                updateTimeField();
            }

            if (modalEl && form) {
                modalEl.addEventListener('show.bs.modal', function (event) {
                    var data = pending;
                    pending = null;

                    if (!data) {
                        var t = event.relatedTarget;
                        if (t && t.dataset && t.dataset.mode === 'edit') {
                            data = {
                                id: t.dataset.id,
                                employee_id: t.dataset.employee,
                                request_date: t.dataset.date,
                                request_type: t.dataset.type,
                                expected_time: t.dataset.time,
                                reason: t.dataset.reason,
                                approve_now: false
                            };
                        } else {
                            data = { request_type: 'delay_in', request_date: todayLocal(), approve_now: true };
                        }
                    }
                    fillForm(data);
                });

                document.getElementById('request_type').addEventListener('change', updateTimeField);

                // Open again after a validation error, or when the page was opened from an edit link
                if (pending && window.bootstrap) {
                    bootstrap.Modal.getOrCreateInstance(modalEl).show();
                }
            }

            var selectAll = document.getElementById('selectAll');
            if (selectAll) {
                selectAll.addEventListener('change', function () {
                    document.querySelectorAll('.row-check').forEach(function (c) { c.checked = selectAll.checked; });
                });
            }
        });
    </script>
</x-default-layout>