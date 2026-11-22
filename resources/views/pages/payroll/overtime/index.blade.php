<x-default-layout>
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
        <h3>Overtime Entry</h3>
    </div></div>

    <div class="col-xl-12 py-3">
        <div class="card">
            <div class="card-body py-4">
                <form method="GET" action="{{ route('overtime.index') }}" class="d-flex align-items-center gap-3">
                    <label class="form-label mb-0">Month</label>
                    <input type="month" name="month" value="{{ $month }}" class="form-control form-control-sm w-200px">
                    <button class="btn btn-sm btn-primary">Show</button>
                    @if ($locked)
                        <span class="badge badge-light-danger">Salary approved. Edit kora jabe na</span>
                    @endif
                </form>
            </div>
        </div>
    </div>

    @if (!$locked)
    @can('create monthly salary')
    <div class="col-xl-12 py-3">
        <div class="card">
            <div class="card-header"><div class="card-title"><h4>Add Overtime ({{ $month }})</h4></div></div>
            <div class="card-body">
                <form method="POST" action="{{ route('overtime.store') }}" class="row g-3">
                    @csrf
                    <input type="hidden" name="overtime_month" value="{{ $month }}">
                    <div class="col-md-3">
                        <label class="form-label">Employee</label>
                        <select name="employee_id" class="form-select form-select-sm" required>
                            <option value="">Select</option>
                            @foreach ($employees as $e)
                                <option value="{{ $e->id }}">{{ $e->employee_code }} - {{ $e->employee_name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Title</label>
                        <input type="text" name="title" class="form-control form-control-sm" placeholder="Overtime">
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Days</label>
                        <input type="number" name="number_of_days" value="1" min="1" max="31" class="form-control form-control-sm" required>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Hours / day</label>
                        <input type="number" step="0.25" name="hours" class="form-control form-control-sm" required>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label">Rate / hour <small class="text-muted">(khali = auto)</small></label>
                        <input type="number" step="0.01" name="rate" class="form-control form-control-sm">
                    </div>
                    <div class="col-md-1 d-flex align-items-end">
                        <button class="btn btn-sm btn-success w-100">Add</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    @endcan
    @endif

    <div class="col-xl-12 py-3">
        <div class="card">
            <div class="card-body">
                <table class="table table-bordered table-striped align-middle fs-7">
                    <thead>
                        <tr>
                            <th>Code</th><th>Employee</th><th>Title</th>
                            <th class="text-end">Days</th><th class="text-end">Hours/day</th>
                            <th class="text-end">Total hours</th><th class="text-end">Rate</th><th></th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse ($overtimes as $o)
                            <tr>
                                <td>{{ $o->employee->employee_code ?? '' }}</td>
                                <td>{{ $o->employee->employee_name ?? '' }}</td>
                                <td>{{ $o->title }}</td>
                                <td class="text-end">{{ $o->number_of_days }}</td>
                                <td class="text-end">{{ $o->hours + 0 }}</td>
                                <td class="text-end">{{ ($o->number_of_days * $o->hours) + 0 }}</td>
                                <td class="text-end">{{ $o->rate ? $o->rate + 0 : 'Auto' }}</td>
                                <td class="text-end">
                                    @if (!$locked)
                                    @can('write monthly salary')
                                    <form method="POST" action="{{ route('overtime.destroy', $o->id) }}"
                                          onsubmit="return confirm('Delete korben?');">
                                        @csrf @method('DELETE')
                                        <button class="btn btn-sm btn-light-danger">Delete</button>
                                    </form>
                                    @endcan
                                    @endif
                                </td>
                            </tr>
                        @empty
                            <tr><td colspan="8" class="text-center">Ei mash-e kono overtime entry nai</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</x-default-layout>