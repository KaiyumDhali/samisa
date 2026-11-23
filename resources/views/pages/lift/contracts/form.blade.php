
<x-default-layout>

    <div id="kt_app_content" class="app-content flex-column-fluid my-5">
        <div id="kt_app_content_container" class="app-container">

            @include('pages.lift._alerts')

            <div class="card card-flush">

                <div class="card-header">
                    <div class="card-title">
                        <h2>New AMC Contract</h2>
                    </div>
                </div>

                <div class="card-body">

                    <form method="POST" action="{{ route('lift.contracts.store') }}">
                        @csrf

                        <div class="row g-5">

                            <div class="col-md-4">
                                <label class="form-label required">Customer</label>

                                <select name="customer_id"
                                        id="customer_id"
                                        class="form-select form-select-solid"
                                        required data-control="select2" >

                                    <option value="">Select Customer</option>

                                    @foreach ($customers as $id => $name)
                                        <option value="{{ $id }}"
                                            @selected(old('customer_id') == $id)>
                                            {{ $name }}
                                        </option>
                                    @endforeach

                                </select>
                            </div>

                            <div class="col-md-8">
                                <label class="form-label required">Lifts Covered Under This Contract</label>

                                <div id="units_box" class="border rounded p-3 bg-light">
                                    Please select a customer first.
                                </div>
                            </div>

                            <div class="col-md-3">
                                <label class="form-label required">Start Date</label>

                                <input type="date"
                                       name="start_date"
                                       class="form-control form-control-solid"
                                       required
                                       value="{{ old('start_date', date('Y-m-d')) }}">
                            </div>

                            <div class="col-md-3">
                                <label class="form-label required">End Date</label>

                                <input type="date"
                                       name="end_date"
                                       class="form-control form-control-solid"
                                       required
                                       value="{{ old('end_date', date('Y-m-d', strtotime('+1 year -1 day'))) }}">
                            </div>

                            <div class="col-md-3">
                                <label class="form-label required">Billing Cycle</label>

                                <select name="billing_cycle" class="form-select form-select-solid" data-control="select2" >

                                    @foreach ([
                                        'monthly' => 'Monthly',
                                        'quarterly' => 'Quarterly (Every 3 Months)',
                                        'half_yearly' => 'Half-Yearly (Every 6 Months)',
                                        'yearly' => 'Yearly'
                                    ] as $k => $v)

                                        <option value="{{ $k }}"
                                            @selected(old('billing_cycle', 'monthly') == $k)>
                                            {{ $v }}
                                        </option>

                                    @endforeach

                                </select>
                            </div>

                            <div class="col-md-3">
                                <label class="form-label required">Fee Per Billing Cycle (৳)</label>

                                <input type="number"
                                       step="0.01"
                                       min="0.01"
                                       name="fee_per_cycle"
                                       class="form-control form-control-solid"
                                       required
                                       value="{{ old('fee_per_cycle') }}">
                            </div>

                            <div class="col-md-3">
                                <label class="form-label required">Visits Per Year (Per Lift)</label>

                                <input type="number"
                                       min="0"
                                       max="365"
                                       name="visits_per_year"
                                       class="form-control form-control-solid"
                                       required
                                       value="{{ old('visits_per_year', 12) }}">
                            </div>

                            <div class="col-md-9">
                                <label class="form-label">Terms & Conditions / Notes</label>

                                <input name="terms"
                                       class="form-control form-control-solid"
                                       value="{{ old('terms') }}">
                            </div>

                        </div>

                        <p class="text-muted mt-5 mb-0">
                            Saving this contract will automatically generate non-billable service visit jobs
                            for each covered lift throughout the contract period. Bills can be generated later
                            from the contract details page using the "Generate Bill" option.
                        </p>

                        <div class="mt-6">

                            <button class="btn btn-primary">
                                Save Contract
                            </button>

                            <a href="{{ route('lift.contracts.index') }}" class="btn btn-light">
                                Back
                            </a>

                        </div>

                    </form>

                </div>
            </div>

        </div>
    </div>

    <script>
        (function () {

            const sel = document.getElementById('customer_id');
            const box = document.getElementById('units_box');
            const url = "{{ url('lift-service/contracts/units-by-customer') }}/";

            const oldIds = @json(array_map('intval', (array) old('unit_ids', [])));

            function load() {

                if (!sel.value) {
                    box.textContent = 'Please select a customer first.';
                    return;
                }

                box.textContent = 'Loading lifts...';

                fetch(url + sel.value, {
                    headers: {
                        'Accept': 'application/json'
                    }
                })
                .then(r => r.json())
                .then(list => {

                    if (!list.length) {
                        box.textContent = 'No active lifts found for this customer. Please add a lift from the Lifts menu first.';
                        return;
                    }

                    box.innerHTML = '';

                    list.forEach(u => {

                        const id = 'u' + u.id;

                        const d = document.createElement('div');
                        d.className = 'form-check mb-1';

                        d.innerHTML =
                            '<input class="form-check-input" type="checkbox" name="unit_ids[]" value="' + u.id + '" id="' + id + '"' +
                            (oldIds.includes(u.id) ? ' checked' : '') +
                            '>' +
                            '<label class="form-check-label" for="' + id + '"></label>';

                        d.querySelector('label').textContent =
                            (u.lift_code ? u.lift_code + ' — ' : '') +
                            u.site_name +
                            (u.brand ? ' (' + u.brand + ')' : '');

                        box.appendChild(d);

                    });

                })
                .catch(() => {
                    box.textContent = 'Unable to load lifts. Please try again.';
                });

            }

            sel.addEventListener('change', load);

            load();

        })();
    </script>

</x-default-layout>
