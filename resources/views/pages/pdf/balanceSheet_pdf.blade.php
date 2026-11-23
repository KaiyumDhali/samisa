<!DOCTYPE html>
<html lang="en">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <title>{{ $data['company_name'] }} - Balance Sheet</title>
    <style>
        body { font-family: DejaVu Sans, sans-serif; font-size: 11px; }
        table { width: 100%; border-collapse: collapse; }
        td, th { border: 1px solid #999; padding: 4px 6px; }
        .r { text-align: right; }
        .c { text-align: center; }
        .sec td { background: #e8eef6; font-weight: bold; }
        .tot td { background: #d0dcec; font-weight: bold; }
        .indent { padding-left: 22px; }
        .title { font-size: 13px; font-weight: bold; text-transform: uppercase; border: 1px solid #000; padding: 2px 6px; display: inline-block; }
        .head td { border: none; }
    </style>
</head>
<body>
    <table class="head">
        <tr class="c">
            <td>
                @if ($data['logo'])
                    <img src="{{ $data['logo'] }}" height="55" alt="logo" /><br>
                @endif
                <b style="font-size:15px; text-transform: uppercase;">{{ $data['company_name'] }}</b><br>
                {{ $data['company_address'] }}<br>
                {{ $data['factory_address'] }}<br>
                {{ $data['company_mobile'] }}<br><br>
                <span class="title">Balance Sheet</span><br>
                As on {{ \Carbon\Carbon::parse($report['as_on_date'])->format('d F Y') }}
            </td>
        </tr>
    </table>
    <br>
    <table>
        <thead>
            <tr><th>Particulars</th><th class="r" style="width:150px">Amount (BDT)</th></tr>
        </thead>
        <tbody>
            <tr class="sec"><td colspan="2">ASSETS</td></tr>
            @if (count($report['fixed_assets']))
                <tr><td colspan="2"><b>Fixed Assets</b></td></tr>
                @foreach ($report['fixed_assets'] as $l)
                    <tr><td class="indent">{{ $l['label'] }}</td><td class="r">{{ number_format($l['amount'], 2) }}</td></tr>
                @endforeach
                <tr><td><b>Total Fixed Assets</b></td><td class="r"><b>{{ number_format($report['total_fixed_assets'], 2) }}</b></td></tr>
            @endif
            <tr><td colspan="2"><b>Current Assets</b></td></tr>
            @foreach ($report['current_assets'] as $l)
                <tr><td class="indent">{{ $l['label'] }}</td><td class="r">{{ number_format($l['amount'], 2) }}</td></tr>
            @endforeach
            <tr><td><b>Total Current Assets</b></td><td class="r"><b>{{ number_format($report['total_current_assets'], 2) }}</b></td></tr>
            <tr class="tot"><td>TOTAL ASSETS</td><td class="r">{{ number_format($report['total_assets'], 2) }}</td></tr>

            <tr class="sec"><td colspan="2">LIABILITIES &amp; EQUITY</td></tr>
            <tr><td colspan="2"><b>Liabilities</b></td></tr>
            @foreach ($report['liabilities'] as $l)
                <tr><td class="indent">{{ $l['label'] }}</td><td class="r">{{ number_format($l['amount'], 2) }}</td></tr>
            @endforeach
            <tr><td><b>Total Liabilities</b></td><td class="r"><b>{{ number_format($report['total_liabilities'], 2) }}</b></td></tr>
            <tr><td colspan="2"><b>Equity</b></td></tr>
            <tr><td class="indent">Total Income</td><td class="r">{{ number_format($report['total_income'], 2) }}</td></tr>
            <tr><td class="indent">Less: Total Expenses</td><td class="r">({{ number_format($report['total_expense'], 2) }})</td></tr>
            <tr><td><b>Net Profit (Retained Earnings)</b></td><td class="r"><b>{{ number_format($report['total_equity'], 2) }}</b></td></tr>
            <tr class="tot"><td>TOTAL LIABILITIES &amp; EQUITY</td><td class="r">{{ number_format($report['total_liabilities_equity'], 2) }}</td></tr>
        </tbody>
    </table>
</body>
</html>
