<x-default-layout>

    <style>
        .dataTables_filter {
            float: right;
        }

        .dataTables_buttons {
            float: left;
        }

        .bottom {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
    </style>

    <div id="kt_app_toolbar" class="app-toolbar py-3 py-lg-6">
        <div id="kt_app_toolbar_container" class="app-container  d-flex flex-stack">
            <div class="page-title d-flex flex-column justify-content-center flex-wrap me-3">
                <h3>Late of Leave Report</h3>
            </div>
        </div>
    </div>
    <div id="kt_app_content" class="app-content flex-column-fluid">
        <!--begin::Content container-->
        <div id="kt_app_content_container" class="app-container ">

            <!--begin::Late leave rule-->
            <div class="card card-flush mb-5">
                <div class="card-header py-4">
                    <div class="card-title fs-6">
                        Current rule:
                        <span class="ms-2 badge badge-light-primary fs-7">
                            {{ $policy->late_count }} late = {{ $policy->deduct_days }} day(s) {{ $policy->leave_type }}
                            @if ($policy->fallback_leave_type)
                                (fallback: {{ $policy->fallback_leave_type }})
                            @endif
                            {{ $policy->repeat_deduction ? '- repeat' : '- one time' }}
                        </span>
                    </div>
                    <div class="card-toolbar">
                        <button class="btn btn-sm btn-light-primary" type="button" data-bs-toggle="collapse"
                            data-bs-target="#late_policy_form">Change rule</button>
                    </div>
                </div>
                <div id="late_policy_form" class="collapse">
                    <div class="card-body pt-0">
                        <form method="POST" action="{{ route('late_leave_policy_save') }}">
                            @csrf
                            <div class="row g-4 align-items-end">
                                <div class="col-md-2">
                                    <label class="form-label fs-7">Late days</label>
                                    <input type="number" min="1" max="31" name="late_count" class="form-control form-control-sm"
                                        value="{{ $policy->late_count }}" required>
                                </div>
                                <div class="col-md-2">
                                    <label class="form-label fs-7">Leave days to deduct</label>
                                    <input type="number" min="1" max="31" name="deduct_days" class="form-control form-control-sm"
                                        value="{{ $policy->deduct_days }}" required>
                                </div>
                                <div class="col-md-2">
                                    <label class="form-label fs-7">Deduct from leave type</label>
                                    <select name="leave_type" class="form-select form-select-sm">
                                        @foreach (\App\Models\LateLeavePolicy::LEAVE_TYPES as $t)
                                            <option value="{{ $t }}" {{ $policy->leave_type == $t ? 'selected' : '' }}>{{ $t }}</option>
                                        @endforeach
                                    </select>
                                </div>
                                <div class="col-md-2">
                                    <label class="form-label fs-7">If balance is insufficient (optional)</label>
                                    <select name="fallback_leave_type" class="form-select form-select-sm">
                                        <option value="">-- none --</option>
                                        @foreach (\App\Models\LateLeavePolicy::LEAVE_TYPES as $t)
                                            <option value="{{ $t }}" {{ $policy->fallback_leave_type == $t ? 'selected' : '' }}>{{ $t }}</option>
                                        @endforeach
                                    </select>
                                </div>
                                <div class="col-md-2">
                                    <div class="form-check form-switch">
                                        <input class="form-check-input" type="checkbox" name="repeat_deduction" value="1" id="repeat_deduction"
                                            {{ $policy->repeat_deduction ? 'checked' : '' }}>
                                        <label class="form-check-label fs-7" for="repeat_deduction">Repeat (6 late = 2 days)</label>
                                    </div>
                                </div>
                                <div class="col-md-2">
                                    <button type="submit" class="btn btn-sm btn-primary">Save rule</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
            <!--end::Late leave rule-->

            <!--begin::Products-->
            <div class="card card-flush">
                <!--begin::Card header-->
                <div class="card-header align-items-center py-5 gap-2 gap-md-5">
                    <!--begin::Card title-->
                    <div class="card-title">
                        <div id="year_div">
                            <div class="card-body p-2">
                                <div class="product fv-row fv-plugins-icon-container">
                                    <select class="form-select form-select-sm" data-control="select2" id="year" name="year">
                                        @for ($year = '2023'; $year <= date('Y') + 7; $year++) <option
                                            value="{{ $year }}" {{ date('Y') == $year ? 'selected' : '' }}>
                                            {{ $year }}</option>
                                            @endfor
                                    </select>
                                </div>
                            </div>
                        </div>
                        <div id="month_div">
                            <div class="card-body p-2">
                                <div class="product fv-row fv-plugins-icon-container">
                                    <select class="form-select form-select-sm" data-control="select2" id="month" name="month">
                                        <option value="">Month</option>
                                        @foreach (['january', 'february', 'march', 'april', 'may', 'june', 'july', 'august', 'september', 'october', 'november', 'december'] as $m)
                                            <option value="{{ $m }}" {{ strtolower(date('F')) == $m ? 'selected' : '' }}>{{ ucfirst($m) }}</option>
                                        @endforeach
                                    </select>
                                </div>
                            </div>
                        </div>
                        <div class="d-flex align-items-center position-relative my-1 ">
                            <div class="card-body p-2">
                                <div class="product fv-row fv-plugins-icon-container">
                                    <button type="submit" id="searchBtn"
                                        class="btn btn-sm btn-primary px-5">{{ __('Search') }}</button>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                <div id="tableDiv" class="card-body pt-0">
                    <div id="messageContainer" class="alert my-5" style="display: none;"></div>

                    <form id="myForm">
                        <button type="button" class="btn btn-sm btn-success px-5" onclick="submitSelectedRows()">Approve Selected</button>

                        <table class="table table-striped table-bordered align-middle table-row-dashed fs-7 gy-5 mb-0"
                            id="late_of_leave">
                            <thead>
                                <tr class="text-start fs-7 text-uppercase gs-0">
                                    <th class="w-80px"><input type="checkbox" id="select-all-checkbox"></th>
                                    <th class="w-60px">Code</th>
                                    <th class="min-w-150px">Name</th>
                                    <th class="min-w-150px">Status</th>
                                    <th class="w-100px">No of Late</th>
                                    <th class="w-100px">Leave Days</th>
                                    <th class="w-100px">Deduct: Casual</th>
                                    <th class="w-100px">Deduct: Sick</th>
                                    <th class="w-100px">Deduct: Annual</th>
                                    <th class="w-100px">Deduct: Special</th>
                                </tr>
                            </thead>
                            <tbody class="fw-semibold text-gray-700" id="attendance_list">
                                <!-- Table data is added dynamically using JavaScript -->
                            </tbody>
                        </table>
                    </form>
                </div>
                <!--end::Card body-->
            </div>
            <!--end::Products-->
        </div>
        <!--end::Content container-->
    </div>
    <!--end::Content-->
</x-default-layout>
<meta name="csrf-token" content="{{ csrf_token() }}">

<script>
    var table = $('#late_of_leave').DataTable({
        pageLength: 100,
    });

    // "Select All" checkbox
    $('#select-all-checkbox').click(function() {
        $('.row-checkbox').prop('checked', this.checked);
    });

    // Input box for one leave type, with its balance below
        // Input box for one leave type, with the remaining balance below it
    function dedInput(d, type) {
        let src = {};
        if (d.status === 'pending') {
            (d.deductions || []).forEach(x => { src[x.type] = x.days; });
        } else {
            src = d.approved || {};
        }
        let days = src[type] || 0;
        // balance available before this month's late-leave
        let before = (d.balances && d.balances[type] !== undefined) ? d.balances[type] : 0;
        return '<input type="number" min="0" max="' + before + '" class="form-control form-control-sm ded-input" data-type="' + type + '" data-before="' + before + '" value="' + days + '">'
             + '<div class="text-muted fs-8 mt-1">Balance left: <span class="bal-left">' + (before - days) + '</span></div>';
    }

    // Update "Balance left" when HR changes a value, and never allow more than the available balance
    $(document).on('input', '.ded-input', function () {
        let before = parseFloat($(this).data('before')) || 0;
        let v = parseInt($(this).val()) || 0;
        if (v > before) {
            v = before;
            $(this).val(v);
        }
        if (v < 0) {
            v = 0;
            $(this).val(v);
        }
        $(this).next().find('.bal-left').text(before - v);
    });

    function statusBadge(d) {
        if (d.status === 'approved') {
            return '<span class="badge badge-light-success">Approved</span>';
        }
        if (d.status === 'changed') {
            return '<span class="badge badge-light-warning">Approved (late count changed, please approve again)</span>';
        }
        return '<span class="badge badge-light-primary">Pending</span>';
    }

    function showMessage(isSuccess, text) {
        $('#messageContainer')
            .removeClass('alert-success alert-danger')
            .addClass(isSuccess ? 'alert-success' : 'alert-danger')
            .html(text)
            .show();
        setTimeout(function () {
            $('#messageContainer').hide();
        }, 5000);
    }

    function CallBack(pdfdata) {
        let url;
        var year = $('#year').val();
        var month = $('#month').val();

        url = '{{ route('late_of_leave_report_search', ['year' => ':year', 'month' => ':month', 'pdf' => ':pdf']) }}';

        url = url.replace(':year', year);
        url = url.replace(':month', month);
        url = url.replace(':pdf', pdfdata);

        if (pdfdata == 'list') {
            $.ajax({
                url: url,
                type: "GET",
                data: {
                    "_token": "{{ csrf_token() }}"
                },
                dataType: "json",
                success: function(data) {
                    table.clear().draw();
                    if (data.length > 0) {
                        $.each(data, function(key, value) {
                            let d = data[key];
                            let nameText = d.employee_name;
                            if (d.uncovered_days > 0) {
                                nameText += ' <span class="text-danger">(' + d.uncovered_days + ' day(s) not covered, no balance)</span>';
                            }

                            table.row.add([
                                '<input type="checkbox" class="row-checkbox" name="selected_users[]" value="' + d.eid + '">',
                                d.employee_code, nameText, statusBadge(d),
                                '<input type="text" class="form-control form-control-sm" name="late_count[]" readonly value="' + d.Late_Count + '">',
                                '<input type="text" class="form-control form-control-sm" name="late_leave[]" readonly value="' + d.late_leave + '">',
                                dedInput(d, 'Casual'), dedInput(d, 'Sick'), dedInput(d, 'Annual'), dedInput(d, 'Special')
                            ]).draw();
                        });
                    }
                }
            });
        }
    }
    CallBack("list");

    $('#searchBtn').on('click', function() {
        CallBack("list");
    });

    function submitSelectedRows() {
        let selectedRows = $('#late_of_leave').find('.row-checkbox:checked');

        if (selectedRows.length === 0) {
            alert('Please select at least one row.');
            return;
        }

        let selectedData = [];
        selectedRows.each(function () {
            let row = $(this).closest('tr');
            selectedData.push({
                'selected_users': row.find('[name="selected_users[]"]').val(),
                'late_count': row.find('[name="late_count[]"]').val(),
                'late_leave': row.find('[name="late_leave[]"]').val(),
                'deductions': JSON.stringify(
                    row.find('.ded-input').map(function () {
                        return { type: $(this).data('type'), days: parseInt($(this).val()) || 0 };
                    }).get().filter(x => x.days > 0)
                ),
                'month': $('#month').val(),
                'year': $('#year').val(),
            });
        });

        $.ajax({
            url: '{{ route("late_of_leave_add") }}',
            method: 'POST',
            headers: {
                'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content'),
            },
            data: { selectedData: selectedData },
            success: function () {
                showMessage(true, 'Leave deducted successfully.');
                CallBack("list");
            },
            error: function (error) {
                let msg = (error.responseJSON && error.responseJSON.error) ? error.responseJSON.error : 'Something went wrong.';
                showMessage(false, msg);
            }
        });
    }
</script>