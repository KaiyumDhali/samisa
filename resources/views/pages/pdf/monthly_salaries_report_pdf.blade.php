
<!DOCTYPE html>
<html lang="en">

<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>Perfume PLC.</title>
    
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css" integrity="sha384-xOolHFLEh07PJGoPkLv1IbcEPTNtaed2xpHsD9ESMhqIYd0nLMwNLD69Npy4HI+N" crossorigin="anonymous">

    <style>
        @page {
            size: Legal landscape;
        }
        /* .title_head{
            padding-right: 30% !important;
        } */
    </style>
</head>

<body style="font-size:10px">
    <table class="table table-borderless table-sm m-0">
        <tbody class="text-center">
            <tr>
                {{-- <td> --}}
                    {{-- <img src="assets/media/logos/default-dark.jpeg" alt="SEML" width="160px" height="70" /> --}}
                    {{-- @if($data['branch_id'] == 1)
                        <img src="assets/media/logos/default-dark.jpeg" alt="SEML" width="160px" height="70" />
                    @elseif($data['branch_id'] == 2)
                        <img src="assets/media/logos/default-dark.jpeg" alt="SEML" width="160px" height="70" />
                    @else
                        <img src="assets/media/logos/default-dark.jpeg" alt="SEML" width="160px" height="70" />
                    @endif --}}
                {{-- </td> --}}
                <td>
                    {{-- @if($data['branch_id'] == 1)
                        <h4>Perfume PLC.</h4>
                    @elseif($data['branch_id'] == 2)
                        <h4>Perfume PLC.</h4>
                    @else
                        <h4>Perfume PLC.</h4>
                    @endif --}}
                    <h4>Perfume PLC.</h4>
                    <h6>Employee Salary Sheet <br>
                        Month of {{ \Carbon\Carbon::parse($data['month'])->format('F, Y') }}
                    </h6>
                </td>
            </tr>
        </tbody>
    </table>

           @php
        $incomeHeads = $heads->where('head_type', 'Income')->values();
        $deductionHeads = $heads->where('head_type', 'Deduction')->values();
        $tot = ['basic' => 0, 'income' => 0, 'deduction' => 0, 'net' => 0];
        $headTot = [];
    @endphp
    <table class="table table-bordered table-striped table-sm table-hover">
        <thead class="text-light bg-secondary">
            <tr style="text-align: center; vertical-align: middle;">
                <th rowspan="2">ID</th>
                <th rowspan="2">Employee Name</th>
                <th colspan="4">Attendance</th>
                <th rowspan="2">Basic</th>
                <th colspan="{{ $incomeHeads->count() + 1 }}">Income</th>
                <th colspan="{{ $deductionHeads->count() + 1 }}">Deduction</th>
                <th rowspan="2">Net Payable</th>
                <th rowspan="2">Remarks</th>
            </tr>
            <tr style="text-align: center; vertical-align: middle;">
                <th>Work</th><th>Present</th><th>Leave</th><th>Absent</th>
                @foreach ($incomeHeads as $h)<th>{{ $h->head_name }}</th>@endforeach
                <th>Total Income</th>
                @foreach ($deductionHeads as $h)<th>{{ $h->head_name }}</th>@endforeach
                <th>Total Deduction</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($rows as $r)
                @php
                    $tot['basic'] += $r['basic_salary']; $tot['income'] += $r['income'];
                    $tot['deduction'] += $r['deduction']; $tot['net'] += $r['net_payble'];
                @endphp
                <tr>
                    <td>{{ $r['employee_code'] }}</td>
                    <td>{{ $r['employee_name'] }}</td>
                    <td class="text-right">{{ $r['working_days'] }}</td>
                    <td class="text-right">{{ $r['present_days'] }}</td>
                    <td class="text-right">{{ $r['leave_days'] }}</td>
                    <td class="text-right">{{ $r['absent_days'] }}</td>
                    <td class="text-right">{{ number_format($r['basic_salary'], 2) }}</td>
                    @foreach ($incomeHeads as $h)
                        @php $v = $r['amounts']['Income|' . $h->head_name] ?? 0; $headTot['Income|' . $h->head_name] = ($headTot['Income|' . $h->head_name] ?? 0) + $v; @endphp
                        <td class="text-right">{{ number_format($v, 2) }}</td>
                    @endforeach
                    <td class="text-right">{{ number_format($r['income'], 2) }}</td>
                    @foreach ($deductionHeads as $h)
                        @php $v = $r['amounts']['Deduction|' . $h->head_name] ?? 0; $headTot['Deduction|' . $h->head_name] = ($headTot['Deduction|' . $h->head_name] ?? 0) + $v; @endphp
                        <td class="text-right">{{ number_format($v, 2) }}</td>
                    @endforeach
                    <td class="text-right">{{ number_format($r['deduction'], 2) }}</td>
                    <td class="text-right"><b>{{ number_format($r['net_payble'], 2) }}</b></td>
                    <td>{{ $r['status'] == 1 ? 'Approved' : 'Pending' }}</td>
                </tr>
            @empty
                <tr class="text-center"><td colspan="20">No salary found for this month</td></tr>
            @endforelse
            @if (count($rows))
                <tr class="text-light bg-secondary">
                    <th colspan="6" class="text-center">Total BDT</th>
                    <th class="text-right">{{ number_format($tot['basic'], 2) }}</th>
                    @foreach ($incomeHeads as $h)<th class="text-right">{{ number_format($headTot['Income|' . $h->head_name] ?? 0, 2) }}</th>@endforeach
                    <th class="text-right">{{ number_format($tot['income'], 2) }}</th>
                    @foreach ($deductionHeads as $h)<th class="text-right">{{ number_format($headTot['Deduction|' . $h->head_name] ?? 0, 2) }}</th>@endforeach
                    <th class="text-right">{{ number_format($tot['deduction'], 2) }}</th>
                    <th class="text-right">{{ number_format($tot['net'], 2) }}</th>
                    <th></th>
                </tr>
            @endif
        </tbody>
    </table>
    
    <table class="table table-borderless pt-5 mt-5">
            <thead>
                <tr>
                    <th class="text-center" style="border-top: 1px solid">Prepared By</th>
                    <th></th>
                    <th></th>
                    <th></th>
                    <th class="text-center" style="border-top: 1px solid">HR & Admin</th>
                    <th></th>
                    <th></th>
                    <th></th>
                    <th class="text-center" style="border-top: 1px solid">Accounts & Finance</th>
                    <th></th>
                    <th></th>
                    <th></th>
                    <th class="text-center" style="border-top: 1px solid">Approved By</th>
                </tr>
            </thead>
            
    </table>

</body>

</html>
