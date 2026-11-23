
<x-default-layout>
    
    <div id="kt_app_content" class="app-content flex-column-fluid my-5">
        <div id="kt_app_content_container" class="app-container">
            @include('pages.lift._alerts')

            <div class="card card-flush">
                <div class="card-header">
                    <div class="card-title">
                        <h2>{{ $unit->exists ? 'Edit Lift' : 'Add New Lift' }}</h2>
                    </div>
                </div>

                <div class="card-body">
                    <form method="POST"
                        action="{{ $unit->exists ? route('lift.units.update', $unit->id) : route('lift.units.store') }}">

                        @csrf
                        @if ($unit->exists)
                            @method('PUT')
                        @endif

                        <div class="row g-5">
    <div class="col-md-4">
        <label class="form-label required">Customer</label>
        <select name="customer_id" class="form-select form-select-solid w-100"
            data-control="select2" data-placeholder="Select Customer" required>
            <option value="">Select Customer</option>
            @foreach ($customers as $id => $name)
                <option value="{{ $id }}" @selected(old('customer_id', $unit->customer_id) == $id)>
                    {{ $name }}
                </option>
            @endforeach
        </select>
    </div>

    <div class="col-md-4">
        <label class="form-label">Lift Code</label>
        <input name="lift_code" class="form-control form-control-solid"
            value="{{ old('lift_code', $unit->lift_code) }}">
    </div>

    <div class="col-md-4">
        <label class="form-label required">Site Name</label>
        <input name="site_name" class="form-control form-control-solid" required
            value="{{ old('site_name', $unit->site_name) }}">
    </div>

    <div class="col-md-12">
        <label class="form-label">Site Address</label>
        <textarea name="site_address" rows="2"
            class="form-control form-control-solid">{{ old('site_address', $unit->site_address) }}</textarea>
    </div>

    <div class="col-md-3">
        <label class="form-label">Brand</label>
        <input name="brand" class="form-control form-control-solid"
            value="{{ old('brand', $unit->brand) }}">
    </div>

    <div class="col-md-3">
        <label class="form-label">Model</label>
        <input name="model" class="form-control form-control-solid"
            value="{{ old('model', $unit->model) }}">
    </div>

    <div class="col-md-2">
        <label class="form-label">Capacity (Persons)</label>
        <input type="number" min="0" name="capacity_persons"
            class="form-control form-control-solid"
            value="{{ old('capacity_persons', $unit->capacity_persons) }}">
    </div>

    <div class="col-md-2">
        <label class="form-label">Floors</label>
        <input type="number" min="0" name="floors"
            class="form-control form-control-solid"
            value="{{ old('floors', $unit->floors) }}">
    </div>

    <div class="col-md-2">
        <label class="form-label">Status</label>
        <select name="status" class="form-select form-select-solid w-100"
            data-control="select2" data-hide-search="true">
            <option value="1" @selected(old('status', $unit->status) == 1)>Active</option>
            <option value="0" @selected(old('status', $unit->status) == 0)>Inactive</option>
        </select>
    </div>

    <div class="col-md-3">
        <label class="form-label">Installation Date</label>
        <input type="date" name="installation_date"
            class="form-control form-control-solid"
            value="{{ old('installation_date', $unit->installation_date) }}">
    </div>

    <div class="col-md-9">
        <label class="form-label">Remarks</label>
        <input name="remarks" class="form-control form-control-solid"
            value="{{ old('remarks', $unit->remarks) }}">
    </div>
</div>

                        <div class="mt-8">
                            <button type="submit" class="btn btn-primary">
                                Save
                            </button>

                            <a href="{{ route('lift.units.index') }}" class="btn btn-light">
                                Back
                            </a>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</x-default-layout>
