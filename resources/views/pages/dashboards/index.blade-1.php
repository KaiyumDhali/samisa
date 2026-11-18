<x-default-layout>
    @role('employee')
        @php
            $employeeData = \App\Models\Employee::where('user_id', auth()->user()->id)->first();
            if ($employeeData) {
                $employeeID = $employeeData->id;
                $employeeCode = $employeeData->employee_code;
                $employeeName = $employeeData->employee_name;
                $employeeBranch = $employeeData->branch_id;
                $employeePhoto = $employeeData->photo;
            } else {
                $employeeID = null;
                $employeeCode = null;
                $employeeName = null;
                $employeeBranch = null;
                $employeePhoto = null;
            }
        @endphp

        @include('pages/dashboards/employee')
    
    
    
    
    @else

    @section('title')
    Dashboard
    @endsection

    {{-- @section('breadcrumbs')
        {{ Breadcrumbs::render('dashboard') }}
    @endsection --}}

    <!--begin::Row-->
    <div class="row g-5 g-xl-10 mb-5 mb-xl-10">
        <!--begin::Col-->
        <div class="col-md-6 col-lg-6 col-xl-6 col-xxl-3 mb-md-5 mb-xl-10">
            @include('partials/widgets/cards/_widget-20')

            @include('partials/widgets/cards/_widget-7')
        </div>
        <!--end::Col-->
        <!--begin::Col-->
        <div class="col-md-6 col-lg-6 col-xl-6 col-xxl-3 mb-md-5 mb-xl-10">
            @include('partials/widgets/cards/_widget-17')

            @include('partials/widgets/lists/_widget-26')
        </div>
        <!--end::Col-->
        <!--begin::Col-->
        <div class="col-xxl-6">
            @include('partials/widgets/engage/_widget-10')
        </div>
        <!--end::Col-->
    </div>
    <!--end::Row-->

     <!--begin::Row-->
     <div class="row g-5 g-xl-10 mb-5 mb-xl-10">
        <!--begin::Col-->
        <div class="col-xl-12">
            {{-- @include('partials/widgets/tables/_widget-14') --}}
            @include('partials/widgets/tables/attendance_report')
        </div>
        <!--end::Col-->
    </div>
    <!--end::Row-->

    @endrole
</x-default-layout>
