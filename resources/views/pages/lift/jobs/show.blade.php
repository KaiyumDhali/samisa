
<x-default-layout>

    <div id="kt_app_content" class="app-content flex-column-fluid my-5">
        <div id="kt_app_content_container" class="app-container">

            @include('pages.lift._alerts')

            <div class="card card-flush mb-5">
                <div class="card-header align-items-center py-5">
                    <div class="card-title">
                        <h2>
                            Job {{ $job->job_no }}
                            <span class="badge badge-light-primary">{{ ucfirst($job->status) }}</span>
                        </h2>
                    </div>

                    <div class="card-toolbar gap-3">
                        <a href="{{ route('lift.jobs.index') }}" class="btn btn-sm btn-light">
                            Back
                        </a>

                        @can('write lift service')
                            @if ($job->status === 'scheduled')
                                <form method="POST"
                                      action="{{ route('lift.jobs.cancel', $job->id) }}"
                                      onsubmit="return confirm('Are you sure you want to cancel this job?')">
                                    @csrf
                                    <button class="btn btn-sm btn-light-danger">Cancel Job</button>
                                </form>
                            @endif
                        @endcan
                    </div>
                </div>

                <div class="card-body pt-0">
                    <div class="row g-4">

                        <div class="col-md-3">
                            <b>Customer</b><br>
                            {{ $job->customer->account_name ?? '' }}
                        </div>

                        <div class="col-md-3">
                            <b>Lift</b><br>
                            {{ $job->unit->site_name ?? '' }}<br>
                            <small>{{ $job->unit->site_address ?? '' }}</small>
                        </div>

                        <div class="col-md-2">
                            <b>Job Type</b><br>
                            {{ ucfirst(str_replace('_', ' ', $job->job_type)) }}
                        </div>

                        <div class="col-md-2">
                            <b>Scheduled Date</b><br>
                            {{ $job->scheduled_date->format('d-m-Y') }}
                        </div>

                        <div class="col-md-2">
                            <b>AMC Contract</b><br>
                            {{ $job->contract->contract_no ?? '—' }}
                        </div>

                        <div class="col-md-6">
                            <b>Problem / Complaint</b><br>
                            {{ $job->problem ?: '—' }}
                        </div>

                        <div class="col-md-3">
                            <b>Technician</b><br>
                            {{ $job->technician_name ?: '—' }}
                            {{ $job->technician_mobile }}
                        </div>

                    </div>
                </div>
            </div>

            @if ($job->status === 'completed')
                <div class="card card-flush mb-5">

                    <div class="card-header">
                        <div class="card-title">
                            <h4>Completed on {{ $job->completed_date?->format('d-m-Y') }}</h4>
                        </div>
                    </div>

                    <div class="card-body pt-0">

                        <p>
                            <b>Work Completed:</b>
                            {{ $job->work_done ?: '—' }}
                        </p>

                        @if ($job->parts->count())
                            <table class="table table-sm table-bordered">
                                <thead>
                                    <tr>
                                        <th>Part</th>
                                        <th class="text-end">Quantity</th>
                                        <th class="text-end">Unit Price</th>
                                        <th class="text-end">Total</th>
                                    </tr>
                                </thead>

                                <tbody>
                                    @foreach ($job->parts as $p)
                                        <tr>
                                            <td>{{ $p->product->product_name ?? $p->product_id }}</td>
                                            <td class="text-end">{{ $p->quantity + 0 }}</td>
                                            <td class="text-end">{{ number_format($p->unit_price, 2) }}</td>
                                            <td class="text-end">{{ number_format($p->total_amount, 2) }}</td>
                                        </tr>
                                    @endforeach
                                </tbody>
                            </table>
                        @endif

                        <div class="row">

                            <div class="col-md-4">

                                @if ($job->is_billable)
                                    <div>
                                        Service Charge:
                                        <b>{{ number_format($job->service_charge, 2) }}</b>
                                    </div>

                                    <div>
                                        Spare Parts:
                                        <b>{{ number_format($job->parts_total, 2) }}</b>
                                    </div>

                                    <div>
                                        Grand Total:
                                        <b>{{ number_format($job->service_charge + $job->parts_total, 2) }} ৳</b>
                                    </div>
                                @else
                                    <div class="text-muted">
                                        Non-Billable (Covered Under AMC) — No additional charges or bill will be generated. Spare parts have been deducted from stock.
                                    </div>
                                @endif

                            </div>

                            <div class="col-md-8">

                                @if ($job->bill_id)
                                    <div>
                                        Bill:
                                        <a href="{{ route('lift.bills.show', $job->bill_id) }}">
                                            <b>{{ $job->bill->bill_no }}</b>
                                        </a>
                                        ({{ ucfirst($job->bill->status) }})
                                    </div>

                                @elseif ($job->is_billable)

                                    @can('write lift service')
                                        <form method="POST"
                                              action="{{ route('lift.jobs.bill', $job->id) }}"
                                              class="d-flex align-items-end gap-3">

                                            @csrf

                                            <div>
                                                <label class="form-label mb-1">Bill Date</label>
                                                <input type="date"
                                                       name="bill_date"
                                                       value="{{ date('Y-m-d') }}"
                                                       class="form-control form-control-sm form-control-solid"
                                                       required>
                                            </div>

                                            <div>
                                                <label class="form-label mb-1">Discount</label>
                                                <input type="number"
                                                       step="0.01"
                                                       min="0"
                                                       name="discount"
                                                       value="0"
                                                       class="form-control form-control-sm form-control-solid">
                                            </div>

                                            <button class="btn btn-sm btn-primary"
                                                    onclick="return confirm('Generating this bill will create an entry in Finance. Do you want to continue?')">
                                                Generate Bill
                                            </button>

                                        </form>
                                    @endcan

                                @endif

                            </div>

                        </div>
                    </div>
                </div>
            @endif

            @if ($job->status === 'scheduled')
                @can('write lift service')

                    <div class="card card-flush">

                        <div class="card-header">
                            <div class="card-title">
                                <h4>Complete Service Job</h4>
                            </div>
                        </div>

                        <div class="card-body pt-0">

                            <form method="POST" action="{{ route('lift.jobs.complete', $job->id) }}">
                                @csrf

                                <div class="row g-4">

                                    <div class="col-md-3">
                                        <label class="form-label required">Completion Date</label>
                                        <input type="date"
                                               name="completed_date"
                                               class="form-control form-control-solid"
                                               required
                                               value="{{ old('completed_date', date('Y-m-d')) }}">
                                    </div>

                                    <div class="col-md-3">
                                        <label class="form-label">Technician Name</label>
                                        <input name="technician_name"
                                               class="form-control form-control-solid"
                                               value="{{ old('technician_name', $job->technician_name) }}">
                                    </div>

                                    <div class="col-md-3">
                                        <label class="form-label">Technician Mobile</label>
                                        <input name="technician_mobile"
                                               class="form-control form-control-solid"
                                               value="{{ old('technician_mobile', $job->technician_mobile) }}">
                                    </div>

                                    <div class="col-md-12">
                                        <label class="form-label">Work Completed / Service Details</label>
                                        <textarea name="work_done"
                                                  rows="2"
                                                  class="form-control form-control-solid">{{ old('work_done') }}</textarea>
                                    </div>

                                    <div class="col-md-3">
                                        <div class="form-check mt-4">
                                            <input class="form-check-input"
                                                   type="checkbox"
                                                   name="is_billable"
                                                   value="1"
                                                   id="is_billable"
                                                   @checked(old('is_billable', $job->job_type !== 'amc_visit'))>

                                            <label class="form-check-label" for="is_billable">
                                                <b>Billable</b> (Charge the customer)
                                            </label>
                                        </div>
                                    </div>

                                    <div class="col-md-3 billable-field">
                                        <label class="form-label">Service Charge (৳)</label>
                                        <input type="number"
                                               step="0.01"
                                               min="0"
                                               name="service_charge"
                                               class="form-control form-control-solid"
                                               value="{{ old('service_charge', 0) }}">
                                    </div>

                                </div>

                                <h6 class="mt-8">Spare Parts (Deduct from Stock)</h6>

                                <table class="table table-sm table-bordered" id="parts_table">
                                    <thead>
                                        <tr>
                                            <th>Product</th>
                                            <th style="width:170px">Warehouse</th>
                                            <th style="width:100px">Quantity</th>
                                            <th style="width:130px" class="billable-field">Unit Price (৳)</th>
                                            <th style="width:50px"></th>
                                        </tr>
                                    </thead>
                                    <tbody></tbody>
                                </table>

                                <button type="button" class="btn btn-sm btn-light-primary" id="add_part">
                                    + Add Spare Part
                                </button>

                                <div class="mt-8">
                                    <button class="btn btn-primary"
                                            onclick="return confirm('Completing this job will deduct the spare parts from stock. Do you want to continue?')">
                                        Complete Job
                                    </button>
                                </div>

                            </form>
                        </div>
                    </div>

                    <template id="part_row">
                        <tr>
                            <td>
                                <select class="form-select form-select-sm form-select-solid p-product"
                                        data-name="product_id">
                                    <option value="">Select Product</option>

                                    @foreach ($products as $p)
                                        <option value="{{ $p->id }}"
                                                data-price="{{ (float) $p->sales_price }}">
                                            {{ $p->product_name }}
                                        </option>
                                    @endforeach
                                </select>
                            </td>

                            <td>
                                <select class="form-select form-select-sm form-select-solid"
                                        data-name="warehouse_id">
                                    @foreach ($warehouses as $id => $name)
                                        <option value="{{ $id }}">{{ $name }}</option>
                                    @endforeach
                                </select>
                            </td>

                            <td>
                                <input type="number"
                                       step="0.01"
                                       min="0"
                                       class="form-control form-control-sm form-control-solid"
                                       data-name="quantity"
                                       value="1">
                            </td>

                            <td class="billable-field">
                                <input type="number"
                                       step="0.01"
                                       min="0"
                                       class="form-control form-control-sm form-control-solid p-price"
                                       data-name="unit_price"
                                       value="0">
                            </td>

                            <td>
                                <button type="button" class="btn btn-sm btn-light-danger py-1 rm">
                                    ×
                                </button>
                            </td>
                        </tr>
                    </template>

                    <script>
                        (function () {
                            const tbody = document.querySelector('#parts_table tbody');
                            const tpl = document.getElementById('part_row');
                            const billable = document.getElementById('is_billable');

                            let idx = 0;

                            function applyBillable() {
                                document.querySelectorAll('.billable-field').forEach(el => {
                                    el.style.display = billable.checked ? '' : 'none';
                                });
                            }

                            document.getElementById('add_part').addEventListener('click', () => {
                                const row = tpl.content.firstElementChild.cloneNode(true);

                                row.querySelectorAll('[data-name]').forEach(el => {
                                    el.name = 'parts[' + idx + '][' + el.dataset.name + ']';
                                });

                                idx++;

                                const prod = row.querySelector('.p-product');
                                const price = row.querySelector('.p-price');

                                prod.addEventListener('change', () => {
                                    price.value = prod.selectedOptions[0].dataset.price || 0;
                                });

                                row.querySelector('.rm').addEventListener('click', () => {
                                    row.remove();
                                });

                                tbody.appendChild(row);
                                applyBillable();
                            });

                            billable.addEventListener('change', applyBillable);

                            applyBillable();
                        })();
                    </script>

                @endcan
            @endif

        </div>
    </div>

</x-default-layout>
