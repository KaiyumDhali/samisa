<!--begin::sidebar menu-->
<div class="app-sidebar-menu overflow-hidden flex-column-fluid">
    <!--begin::Menu wrapper-->
    <div id="kt_app_sidebar_menu_wrapper" class="app-sidebar-wrapper hover-scroll-overlay-y my-5" data-kt-scroll="true"
        data-kt-scroll-activate="true" data-kt-scroll-height="auto"
        data-kt-scroll-dependencies="#kt_app_sidebar_logo, #kt_app_sidebar_footer"
        data-kt-scroll-wrappers="#kt_app_sidebar_menu" data-kt-scroll-offset="5px" data-kt-scroll-save-state="true">

        @role('employee')
            <div class="menu menu-column menu-rounded menu-sub-indention px-3 fw-semibold fs-6" id="#kt_app_sidebar_menu"
                data-kt-menu="true" data-kt-menu-expand="false">

                <!--begin:Menu item-->
                <div class="menu-item menu-accordion {{ request()->routeIs('dashboard') ? 'here show' : '' }}">
                    <!--begin:Menu link-->
                    <a class="menu-link {{ request()->routeIs('dashboard') ? 'active' : '' }}"
                        href="{{ route('dashboard') }}">
                        <i class="bi bi-grid-fill fs-2"></i>
                        <span class="menu-title ms-4">Dashboards</span>
                        {{-- <span class="menu-arrow"></span> --}}
                    </a>
                    <!--end:Menu link-->
                    <!--begin:Menu sub-->
                    <div class="menu-sub menu-sub-accordion">
                        <!--begin:Menu item-->
                        <div class="menu-item">
                            <!--begin:Menu link-->

                            <!--end:Menu link-->
                        </div>
                        <!--end:Menu item-->
                    </div>
                    <!--end:Menu sub-->
                </div>
                <!--end:Menu item-->

                <!--begin:Menu item-->
                <div class="menu-item">
                    <!--begin:Menu link-->
                    <a class="menu-link {{ request()->routeIs('employee_profile.*') ? 'active' : '' }}"
                        href="{{ route('employee_profile') }}">
                        <i class="bi bi-person-bounding-box fs-2"></i>
                        <span class="menu-title ms-4">Employee Profile</span>
                    </a>
                    <!--end:Menu link-->
                </div>
                <!--end:Menu item-->

                <div class="menu-item">
                    <!--begin:Menu link-->
                    <a class="menu-link {{ request()->routeIs('single_employee_all_attendance_search.*') ? 'active' : '' }}"
                        href="{{ route('single_employee_all_attendance_search') }}">
                        {{-- <i class="bi bi-window-plus fs-2"></i> --}}
                        <i class="bi bi-card-list fs-2"></i>
                        <span class="menu-title ms-4">Attendance Report</span>
                    </a>
                    <!--end:Menu link-->
                </div>



                <!--begin:Menu item-->
                <div class="menu-item">
                    <!--begin:Menu link-->
                    <a class="menu-link {{ request()->routeIs('employee_profile_leave_entry.*') ? 'active' : '' }}"
                        href="{{ route('employee_profile_leave_entry') }}">
                        <i class="bi bi-window-plus fs-2"></i>
                        <span class="menu-title ms-4">Employee Leave</span>
                    </a>
                    <!--end:Menu link-->
                </div>
                <!--end:Menu item-->

                <!--begin:Menu item-->
                <div class="menu-item">
                    <!--begin:Menu link-->
                    <a class="menu-link {{ request()->routeIs('employee_profile_ledger.*') ? 'active' : '' }}"
                        href="{{ route('employee_profile_ledger') }}">
                        <i class="bi bi-card-checklist fs-2"></i>
                        <span class="menu-title ms-4">Ledgers Details</span>
                    </a>
                    <!--end:Menu link-->
                </div>
                <!--end:Menu item-->


            </div>
        @else
            <!--begin::Menu-->
            <div class="menu menu-column menu-rounded menu-sub-indention px-3 fw-semibold fs-6" id="#kt_app_sidebar_menu"
                data-kt-menu="true" data-kt-menu-expand="false">

                <!--begin:Menu item-->
                <div class="menu-item menu-accordion {{ request()->routeIs('dashboard') ? 'here show' : '' }}">
                    <!--begin:Menu link-->
                    <a class="menu-link {{ request()->routeIs('dashboard') ? 'active' : '' }}"
                        href="{{ route('dashboard') }}">
                        <i class="bi bi-grid-fill fs-2"></i>
                        <span class="menu-title ms-4">Dashboards</span>
                        {{-- <span class="menu-arrow"></span> --}}
                    </a>
                    <!--end:Menu link-->
                    <!--begin:Menu sub-->
                    <div class="menu-sub menu-sub-accordion">
                        <!--begin:Menu item-->
                        <div class="menu-item">
                            <!--begin:Menu link-->

                            <!--end:Menu link-->
                        </div>
                        <!--end:Menu item-->
                    </div>
                    <!--end:Menu sub-->
                </div>
                <!--end:Menu item-->

                {{-- Add: General Setting item --}}
                <div data-kt-menu-trigger="click"
                    class="menu-item menu-accordion {{ request()->routeIs('emp_branch*', 'emp_department*', 'emp_designation*') ? 'here show' : '' }}">
                    <!--begin:Menu link-->
                    <span class="menu-link">
                        <i class="bi bi-gear fs-2"></i>
                        <span class="menu-title ms-4"> General Setting</span>
                        <span class="menu-arrow"></span>
                    </span>
                    <!--end:Menu link-->
                    <!--begin:Menu sub-->
                    <div class="menu-sub menu-sub-accordion">
                        <!--begin:Menu item-->
                        <div class="menu-item">
                            <!--begin:Menu link-->
                            @can('read employee branch')
                                <a class="menu-link {{ request()->routeIs('emp_branch.*') ? 'active' : '' }}"
                                    href="{{ route('emp_branch.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Company </span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read employee department')
                                <a class="menu-link {{ request()->routeIs('emp_department.*') ? 'active' : '' }}"
                                    href="{{ route('emp_department.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title"> Department</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read employee designation')
                                <a class="menu-link {{ request()->routeIs('emp_designation.*') ? 'active' : '' }}"
                                    href="{{ route('emp_designation.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title"> Designation</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                        </div>
                        <!--end:Menu item-->
                    </div>
                    <!--end:Menu sub-->
                </div>
                {{-- End: General Setting item --}}

                {{-- Add: Employee Menu item --}}
                <div data-kt-menu-trigger="click"
                    class="menu-item menu-accordion {{ request()->routeIs('employees*', 'employee_ledger*') ? 'here show' : '' }}">
                    <!--begin:Menu link-->
                    <span class="menu-link">
                        <i class="bi bi-people fs-2"></i>
                        <span class="menu-title ms-4"> Employee</span>
                        <span class="menu-arrow"></span>
                    </span>
                    <!--end:Menu link-->
                    <!--begin:Menu sub-->
                    <div class="menu-sub menu-sub-accordion">
                        <!--begin:Menu item-->
                        <div class="menu-item">
                            <!--begin:Menu link-->
                            @can('read employee')
                                <a class="menu-link {{ request()->routeIs('employees.*') ? 'active' : '' }}"
                                    href="{{ route('employees.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Add Employee</span>
                                </a>
                            @endcan
                        </div>
                        <!--end:Menu link-->
                        <!--begin:Menu link-->
                        <div class="menu-item">
                            @can('read employee ledger')
                                <a class="menu-link {{ request()->routeIs('employee_ledger.*') ? 'active' : '' }}"
                                    href="{{ route('employee_ledger.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Employee Ledgers</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                        </div>
                        <!--end:Menu item-->
                    </div>
                    <!--end:Menu sub-->
                </div>
                {{-- End: Employee Menu item --}}

                {{-- Add: Employee Leave item --}}
                <div data-kt-menu-trigger="click"
                    class="menu-item menu-accordion {{ request()->routeIs(
                        'leave_report*',
                        'late_of_leave*',
                        'employee_leave_setting*',
                        'employee_leave_entry*',
                        'employee_leave_approve_dept*',
                        'employee_leave_approve_hr*',
                        'employee_leave_approve_manag*',
                        'employee_leave_entry_list*',
                    )
                        ? 'here show'
                        : '' }}">
                    <!--begin:Menu link-->
                    <span class="menu-link">
                        <i class="bi bi-person-vcard fs-2"></i>
                        <span class="menu-title ms-4"> Employee Leave</span>
                        <span class="menu-arrow"></span>
                    </span>

                    <!--end:Menu link-->
                    <!--begin:Menu sub-->
                    <div class="menu-sub menu-sub-accordion">
                        <!--begin:Menu item-->
                        <div class="menu-item">
                            <!--begin:Menu link-->
                            <a class="menu-link {{ request()->routeIs('leave_report.*') ? 'active' : '' }}"
                                href="{{ route('leave_report.index') }}">
                                <span class="menu-bullet">
                                    <span class="bullet bullet-dot"></span>
                                </span>
                                <span class="menu-title">Leave Report</span>
                            </a>
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            <a class="menu-link {{ request()->routeIs('late_of_leave') ? 'active' : '' }}"
                                href="{{ route('late_of_leave') }}">
                                <span class="menu-bullet">
                                    <span class="bullet bullet-dot"></span>
                                </span>
                                <span class="menu-title">Late of Leave</span>
                            </a>
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            <a class="menu-link {{ request()->routeIs('employee_leave_entry_list') ? 'active' : '' }}"
                                href="{{ route('employee_leave_entry_list') }}">
                                <span class="menu-bullet">
                                    <span class="bullet bullet-dot"></span>
                                </span>
                                <span class="menu-title">Leave Entry List</span>
                            </a>
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read leave setting')
                                <a class="menu-link {{ request()->routeIs('employee_leave_setting.*') ? 'active' : '' }}"
                                    href="{{ route('employee_leave_setting.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Leave Setting</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read leave entry')
                                <a class="menu-link {{ request()->routeIs('employee_leave_entry.*') ? 'active' : '' }}"
                                    href="{{ route('employee_leave_entry.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Leave Entry</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read leave approved department')
                                <a class="menu-link {{ request()->routeIs('employee_leave_approve_dept.*') ? 'active' : '' }}"
                                    href="{{ route('employee_leave_approve_dept.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Leave Approved Department</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read leave approved hr')
                                <a class="menu-link {{ request()->routeIs('employee_leave_approve_hr.*') ? 'active' : '' }}"
                                    href="{{ route('employee_leave_approve_hr.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Leave Approved HR</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read leave approved management')
                                <a class="menu-link {{ request()->routeIs('employee_leave_approve_manag.*') ? 'active' : '' }}"
                                    href="{{ route('employee_leave_approve_manag.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Leave Approved Management</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->


                        </div>
                        <!--end:Menu item-->
                    </div>
                    <!--end:Menu sub-->
                </div>
                {{-- End: Employee Leave item --}}

                {{-- Add: HR Admin Setup Menu item --}}
                <div data-kt-menu-trigger="click"
                    class="menu-item menu-accordion {{ request()->routeIs(
                        'attendance*',
                        'work_time*',
                        'break_time*',
                        'late_time*',
                        'emp_delayin_earlyout*',
                        'promotion*',
                        'resignation*',
                        'termination*',
                        'announcement*',
                        'holiday*',
                        'meeting*',
                    )
                        ? 'here show'
                        : '' }}">
                    <!--begin:Menu link-->
                    <span class="menu-link">
                        <i class="bi bi-card-list fs-2"></i>
                        <span class="menu-title ms-4">HR Admin Setup</span>
                        <span class="menu-arrow"></span>
                    </span>
                    <!--end:Menu link-->
                    <!--begin:Menu sub-->
                    <div class="menu-sub menu-sub-accordion">
                        <!--begin:Menu item-->
                        <div class="menu-item">
                            <!--begin:Menu link-->
                            @can('read timetable')
                                <a class="menu-link {{ request()->routeIs('work_time.*') ? 'active' : '' }}"
                                    href="{{ route('work_time.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Set Timetable </span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            {{-- @can('read attendance')
                                <a class="menu-link {{ request()->routeIs('break_time.*') ? 'active' : '' }}"
                                    href="{{ route('break_time.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Break Time</span>
                                </a>
                            @endcan --}}
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            {{-- @can('read attendance')
                                <a class="menu-link {{ request()->routeIs('late_time.*') ? 'active' : '' }}"
                                    href="{{ route('late_time.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Late Time</span>
                                </a>
                            @endcan --}}
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read attendance')
                                <a class="menu-link {{ request()->routeIs('attendance.*') ? 'active' : '' }}"
                                    href="{{ route('attendance.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Attendance</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read delayin earlyout')
                                <a class="menu-link {{ request()->routeIs('emp_delayin_earlyout.*') ? 'active' : '' }}"
                                    href="{{ route('emp_delayin_earlyout.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Delay In Early Exit</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read promotion')
                                <a class="menu-link {{ request()->routeIs('promotion.*') ? 'active' : '' }}"
                                    href="{{ route('promotion.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Promotion</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            {{-- @can('read resignation')
                                <a class="menu-link {{ request()->routeIs('resignation.*') ? 'active' : '' }}"
                                    href="{{ route('resignation.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Resignation</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read termination')
                                <a class="menu-link {{ request()->routeIs('termination.*') ? 'active' : '' }}"
                                    href="{{ route('termination.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Termination</span>
                                </a>
                            @endcan --}}
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read announcement')
                                <a class="menu-link {{ request()->routeIs('announcement.*') ? 'active' : '' }}"
                                    href="{{ route('announcement.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Announcement</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                             @can('read holiday')
                                <a class="menu-link {{ request()->routeIs('holiday.*') ? 'active' : '' }}"
                                    href="{{ route('holiday.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Holiday</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            {{--@can('read meeting')
                                <a class="menu-link {{ request()->routeIs('meeting.*') ? 'active' : '' }}"
                                    href="{{ route('meeting.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Meeting</span>
                                </a>
                            @endcan --}}
                            <!--end:Menu link-->

                        </div>
                        <!--end:Menu item-->
                    </div>
                    <!--end:Menu sub-->
                </div>
                {{-- End: HR Admin Setup Menu item --}}

                {{-- Add: Employee payroll Menu item --}}
                <div data-kt-menu-trigger="click"
                    class="menu-item menu-accordion {{ request()->routeIs('set_salaries*', 'monthly_salaries*', 'payslips*', 'payslip_type*', 'income_head*','deduction_head*', 'allowance_option*', 'loan_option*') ? 'here show' : '' }}">
                    <!--begin:Menu link-->
                    <span class="menu-link">
                        <i class="bi bi-cash-stack fs-2"></i>
                        <span class="menu-title ms-4">Employee Payroll</span>
                        <span class="menu-arrow"></span>
                    </span>
                    <!--end:Menu link-->
                    <!--begin:Menu sub-->
                    <div class="menu-sub menu-sub-accordion">
                        <!--begin:Menu item-->
                        <div class="menu-item">

                            <!--begin:Menu link-->
                            @can('read set salaries')
                                <a class="menu-link {{ request()->routeIs('set_salaries.*') ? 'active' : '' }}"
                                    href="{{ route('set_salaries.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Set Salaries</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read monthly salary')
                                <a class="menu-link {{ request()->routeIs('monthly_salaries.*') ? 'active' : '' }}"
                                    href="{{ route('monthly_salaries.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Salary Sheet</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            {{-- @can('read payslips')
                                <a class="menu-link {{ request()->routeIs('payslips.*') ? 'active' : '' }}"
                                    href="{{ route('payslips.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Payslips</span>
                                </a>
                            @endcan --}}
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read payslip type')
                                <a class="menu-link {{ request()->routeIs('payslip_type.*') ? 'active' : '' }}"
                                    href="{{ route('payslip_type.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Payslip Type</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read income head')
                                <a class="menu-link {{ request()->routeIs('income_head.*') ? 'active' : '' }}"
                                    href="{{ route('income_head.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Income Head</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read deduction head')
                                <a class="menu-link {{ request()->routeIs('deduction_head.*') ? 'active' : '' }}"
                                    href="{{ route('deduction_head.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Deduction Head</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read allowance option')
<!--                                <a class="menu-link {{ request()->routeIs('allowance_option.*') ? 'active' : '' }}"
                                    href="{{ route('allowance_option.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Allowance Option</span>
                                </a>-->
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read loan option')
<!--                                <a class="menu-link {{ request()->routeIs('loan_option.*') ? 'active' : '' }}"
                                    href="{{ route('loan_option.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Loan Option</span>
                                </a>-->
                            @endcan
                            <!--end:Menu link-->
                        </div>
                        <!--end:Menu item-->
                    </div>
                    <!--end:Menu sub-->
                </div>
                {{-- End: Employee payroll Menu item --}}

                {{-- Add: Employee Performance Menu item --}}
                <div data-kt-menu-trigger="click"
                    class="menu-item menu-accordion {{ request()->routeIs('performance_type*', 'employee_performance*') ? 'here show' : '' }}">
                    <!--begin:Menu link-->
                    <span class="menu-link">
                        <i class="bi bi-person-check fs-2"></i>
                        <span class="menu-title ms-4">Employee Performance</span>
                        <span class="menu-arrow"></span>
                    </span>
                    <!--end:Menu link-->
                    <!--begin:Menu sub-->
                    <div class="menu-sub menu-sub-accordion">
                        <!--begin:Menu item-->
                        <div class="menu-item">
                            <!--begin:Menu link-->
                            @can('read performance type')
                                <a class="menu-link {{ request()->routeIs('performance_type.*') ? 'active' : '' }}"
                                    href="{{ route('performance_type.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Performance Type</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->
                            <!--begin:Menu link-->
                            @can('read employee performance')
                                <a class="menu-link {{ request()->routeIs('employee_performance.*') ? 'active' : '' }}"
                                    href="{{ route('employee_performance.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Employee Performance</span>
                                </a>
                            @endcan
                            <!--end:Menu link-->

                        </div>
                        <!--end:Menu item-->
                    </div>
                    <!--end:Menu sub-->
                </div>
                {{-- End: Employee Performance Menu item --}}

                <!--begin:Menu item-->
                <div class="menu-item pt-5">
                    <!--begin:Menu content-->
                    <div class="menu-content">
                        <span class="menu-heading fw-bold text-uppercase fs-7">Apps</span>
                    </div>
                    <!--end:Menu content-->
                </div>
                <!--end:Menu item-->

                @can('write user management')
                    <!--begin:Menu item-->
                    <div data-kt-menu-trigger="click"
                        class="menu-item menu-accordion {{ request()->routeIs('user-management.*') ? 'here show' : '' }}">
                        <!--begin:Menu link-->
                        <span class="menu-link">
                            <i class="bi bi-person-fill-gear fs-2"></i>
                            <span class="menu-title ms-4">User Management</span>
                            <span class="menu-arrow"></span>
                        </span>
                        <!--end:Menu link-->
                        <!--begin:Menu sub-->
                        <div class="menu-sub menu-sub-accordion">
                            <!--begin:Menu item-->
                            <div class="menu-item">
                                <!--begin:Menu link-->
                                <a class="menu-link {{ request()->routeIs('user-management.users.*') ? 'active' : '' }}"
                                    href="{{ route('user-management.users.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Users</span>
                                </a>
                                <!--end:Menu link-->
                            </div>
                            <!--end:Menu item-->
                            <!--begin:Menu item-->
                            <div class="menu-item">
                                <!--begin:Menu link-->
                                <a class="menu-link {{ request()->routeIs('user-management.roles.*') ? 'active' : '' }}"
                                    href="{{ route('user-management.roles.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Roles</span>
                                </a>
                                <!--end:Menu link-->
                            </div>
                            <!--end:Menu item-->
                            <!--begin:Menu item-->
                            <div class="menu-item">
                                <!--begin:Menu link-->
                                <a class="menu-link {{ request()->routeIs('user-management.permissions.*') ? 'active' : '' }}"
                                    href="{{ route('user-management.permissions.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Permissions</span>
                                </a>
                                <!--end:Menu link-->
                            </div>
                            <!--end:Menu item-->
                        </div>
                        <!--end:Menu sub-->
                    </div>
                    <!--end:Menu item-->
                @endcan
                <!--end:Menu item-->

                {{-- Add: DB Backup Menu item --}}
                @can('read dbbackup')
                <div data-kt-menu-trigger="click"
                    class="menu-item menu-accordion {{ request()->routeIs('dbbackups.*') ? 'here show' : '' }}">
                    <!--begin:Menu link-->
                    <span class="menu-link">
                        <i class="bi bi-database-check fs-2"></i>
                        <span class="menu-title ms-4">Database</span>
                        <span class="menu-arrow"></span>
                    </span>
                    <!--end:Menu link-->
                    <!--begin:Menu sub-->
                    <div class="menu-sub menu-sub-accordion">
                        <!--begin:Menu item-->
                        <div class="menu-item">
                            <!--begin:Menu link-->
                            
                                <a class="menu-link {{ request()->routeIs('dbbackups.index*') ? 'active' : '' }}"
                                    href="{{ route('dbbackups.index') }}">
                                    <span class="menu-bullet">
                                        <span class="bullet bullet-dot"></span>
                                    </span>
                                    <span class="menu-title">Database Backup</span>
                                </a>
                            
                            <!--end:Menu link-->
                        </div>
                        <!--end:Menu item-->
                    </div>
                    <!--end:Menu sub-->
                </div>
                @endcan
                {{-- End: DB Backup Menu item --}}

            </div>
        @endrole
        <!--end::Menu-->
    </div>
    <!--end::Menu wrapper-->
</div>
<!--end::sidebar menu-->