
<x-default-layout>
    <div id="kt_app_content" class="app-content flex-column-fluid my-5">
        <div id="kt_app_content_container" class="app-container">
            @include('pages.lift._alerts')

            <div class="card card-flush">
                <div class="card-header">
                    <div class="card-title">
                        <h2>New Service Job (Repair / Breakdown / Extra Visit)</h2>
                    </div>
                </div>

                <div class="card-body">
                    <form method="POST" action="{{ route('lift.jobs.store') }}">
                        @csrf

                        <div class="row g-5">
                            <div class="col-md-6">
                                <label class="form-label required">Lift</label>
                                <select name="lift_unit_id" class="form-select form-select-solid" required data-control="select2">
                                    <option value="">Select Lift</option>
                                    @foreach ($units as $u)
                                        <option value="{{ $u->id }}" @selected(old('lift_unit_id') == $u->id)>
                                            {{ $u->customer->account_name ?? '' }} —
                                            {{ $u->lift_code ? $u->lift_code . ' / ' : '' }}
                                            {{ $u->site_name }}
                                        </option>
                                    @endforeach
                                </select>
                            </div>

                            <div class="col-md-3">
                                <label class="form-label">AMC Contract (Optional)</label>
                                <select name="contract_id" class="form-select form-select-solid" data-control="select2" >
                                    <option value="">No Contract</option>
                                    @foreach ($contracts as $c)
                                        <option value="{{ $c->id }}" @selected(old('contract_id') == $c->id)>
                                            {{ $c->contract_no }}
                                        </option>
                                    @endforeach
                                </select>
                            </div>

                            <div class="col-md-3">
                                <label class="form-label required">Job Type</label>
                                <select name="job_type" class="form-select form-select-solid" data-control="select2" >
                                    @foreach ([
                                        'repair' => 'Repair',
                                        'breakdown' => 'Breakdown Call',
                                        'amc_visit' => 'AMC Visit (Extra)',
                                    ] as $k => $v)
                                        <option value="{{ $k }}" @selected(old('job_type', 'repair') == $k)>
                                            {{ $v }}
                                        </option>
                                    @endforeach
                                </select>
                            </div>

                            <div class="col-md-3">
                                <label class="form-label required">Scheduled Date</label>
                                <input type="date" name="scheduled_date"
                                    class="form-control form-control-solid"
                                    required
                                    value="{{ old('scheduled_date', date('Y-m-d')) }}">
                            </div>

                            <div class="col-md-3">
                                <label class="form-label">Technician Name</label>
                                <input name="technician_name"
                                    class="form-control form-control-solid"
                                    value="{{ old('technician_name') }}">
                            </div>

                            <div class="col-md-3">
                                <label class="form-label">Technician Mobile</label>
                                <input name="technician_mobile"
                                    class="form-control form-control-solid"
                                    value="{{ old('technician_mobile') }}">
                            </div>

                            <div class="col-md-12">
                                <label class="form-label">Problem / Complaint Details</label>
                                <textarea name="problem" rows="2"
                                    class="form-control form-control-solid">{{ old('problem') }}</textarea>
                            </div>
                        </div>

                        <div class="mt-6">
                            <button type="submit" class="btn btn-primary">
                                Create Job
                            </button>

                            <a href="{{ route('lift.jobs.index') }}" class="btn btn-light">
                                Back
                            </a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-default-layout>
