<x-default-layout>
    <style>
        .card .card-header { min-height: 40px; }
        .table> :not(caption)>*>* { padding: 0.3rem !important; }
        .bs-section td { background: #e8eef6; font-weight: 700; }
        .bs-total td { background: #d0dcec; font-weight: 700; }
    </style>

    <div id="kt_app_content" class="app-content flex-column-fluid my-5">
        <div id="kt_app_content_container" class="app-container">
            <div class="card card-flush">
                <div class="card-header align-items-center py-5 gap-2 gap-md-5">
                    <div class="card-title">
                        <h2>Balance Sheet</h2>
                    </div>
                    <div class="card-toolbar flex-row-fluid justify-content-end gap-3 align-items-end">
                        <form method="GET" action="{{ route('balance_sheet') }}" class="d-flex gap-3 align-items-end">
                            <div class="form-group">
                                <label for="as_on_date">{{ __('As on Date') }}</label>
                                <input id="as_on_date" type="date" name="as_on_date" value="{{ $asOnDate }}"
                                    class="form-control form-control-sm form-control-solid" />
                            </div>
                            <button type="submit" class="btn btn-sm btn-primary">Generate</button>
                        </form>
                        <a href="{{ route('balance_sheet_pdf', ['as_on_date' => $asOnDate]) }}" target="_blank"
                            class="btn btn-sm btn-light-danger">PDF Download</a>
                        <a href="{{ route('balance_sheet_excel', ['as_on_date' => $asOnDate]) }}"
                            class="btn btn-sm btn-light-success">Excel Download</a>
                    </div>
                </div>

                <div class="card-body pt-0">
                    <h4 class="text-center mb-1">Balance Sheet</h4>
                    <p class="text-center">As on {{ \Carbon\Carbon::parse($asOnDate)->format('d F Y') }}</p>

                    <table class="table table-bordered table-sm align-middle">
                        <thead>
                            <tr>
                                <th>Particulars</th>
                                <th class="text-end" style="width:220px">Amount (BDT)</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr class="bs-section"><td colspan="2">ASSETS</td></tr>
                            @if (count($report['fixed_assets']))
                                <tr><td colspan="2"><b>Fixed Assets</b></td></tr>
                                @foreach ($report['fixed_assets'] as $l)
                                    <tr><td class="ps-8">{{ $l['label'] }}</td><td class="text-end">{{ number_format($l['amount'], 2) }}</td></tr>
                                @endforeach
                                <tr><td><b>Total Fixed Assets</b></td><td class="text-end"><b>{{ number_format($report['total_fixed_assets'], 2) }}</b></td></tr>
                            @endif
                            <tr><td colspan="2"><b>Current Assets</b></td></tr>
                            @foreach ($report['current_assets'] as $l)
                                <tr><td class="ps-8">{{ $l['label'] }}</td><td class="text-end">{{ number_format($l['amount'], 2) }}</td></tr>
                            @endforeach
                            <tr><td><b>Total Current Assets</b></td><td class="text-end"><b>{{ number_format($report['total_current_assets'], 2) }}</b></td></tr>
                            <tr class="bs-total"><td>TOTAL ASSETS</td><td class="text-end">{{ number_format($report['total_assets'], 2) }}</td></tr>

                            <tr class="bs-section"><td colspan="2">LIABILITIES &amp; EQUITY</td></tr>
                            <tr><td colspan="2"><b>Liabilities</b></td></tr>
                            @foreach ($report['liabilities'] as $l)
                                <tr><td class="ps-8">{{ $l['label'] }}</td><td class="text-end">{{ number_format($l['amount'], 2) }}</td></tr>
                            @endforeach
                            <tr><td><b>Total Liabilities</b></td><td class="text-end"><b>{{ number_format($report['total_liabilities'], 2) }}</b></td></tr>
                            <tr><td colspan="2"><b>Equity</b></td></tr>
                            <tr><td class="ps-8">Total Income</td><td class="text-end">{{ number_format($report['total_income'], 2) }}</td></tr>
                            <tr><td class="ps-8">Less: Total Expenses</td><td class="text-end">({{ number_format($report['total_expense'], 2) }})</td></tr>
                            <tr><td><b>Net Profit (Retained Earnings)</b></td><td class="text-end"><b>{{ number_format($report['total_equity'], 2) }}</b></td></tr>
                            <tr class="bs-total"><td>TOTAL LIABILITIES &amp; EQUITY</td><td class="text-end">{{ number_format($report['total_liabilities_equity'], 2) }}</td></tr>
                        </tbody>
                    </table>

                    @if (abs($report['difference']) > 0.005)
                        <div class="alert alert-danger">Balance mile nai! Difference: {{ number_format($report['difference'], 2) }}</div>
                    @else
                        <div class="text-success fw-bold">&#10004; Balanced (Assets = Liabilities + Equity)</div>
                    @endif
                </div>
            </div>
        </div>
    </div>
</x-default-layout>
