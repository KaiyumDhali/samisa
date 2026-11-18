@php
    $runningDrBalance = 0;
    $runningCrBalance = 0;
    $rowsPerPage = 12;
@endphp

<!DOCTYPE html>
<html lang="en">

<head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>{{ $data['company_name'] }}</title>

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@4.6.2/dist/css/bootstrap.min.css"
        integrity="sha384-xOolHFLEh07PJGoPkLv1IbcEPTNtaed2xpHsD9ESMhqIYd0nLMwNLD69Npy4HI+N" crossorigin="anonymous">

    <style>
        .double-underline {
            border-bottom: 4px double;
        }

        .page-break {
            page-break-before: always;
        }

        .page-header {
            display: block;
            position: fixed;
            top: 0;
            width: 100%;
            text-align: center;
            margin-top: -40px;
        }
    </style>
</head>

<body style="font-size:12px">
    {{-- include header --}}
    @include('pages.pdf.partials.header_pdf')

    <div class="text-center">
        @if ($data['start_date'] == $data['end_date'])
            <h5 class="pb-0 mb-0 pt-0 pdf_title">Receive Report</h5>
            <p>{{ \Carbon\Carbon::parse($data['start_date'])->translatedFormat('d F Y') }}</p>
        @else
            <h5 class="pb-0 mb-0 pt-0 pdf_title">Date Wise Purchase Register</h5>
            <p>Form {{ \Carbon\Carbon::parse($data['start_date'])->translatedFormat('d F Y') }} to
                {{ \Carbon\Carbon::parse($data['end_date'])->translatedFormat('d F Y') }}</p>
        @endif
    </div>

    @php
        $currentRow = 1;
    @endphp

    <table class="table table-bordered table-striped table-sm table-hover pt-0">
        @if ($dateWiseReceiveSearch)
            <thead class="text-light bg-secondary">
                <tr class="text-uppercase text-center" style="font-size: 12px; font-weight: bold">
                    <th scope="col" class="text-center align-middle" width="65px">Receive Date</th>
                    <th scope="col" class="text-center align-middle" width="60px">Invoice</th>
                    <th scope="col" class="text-center align-middle" width="60px">Production No/Batch No</th>
                    <th scope="col" class="text-center align-middle" width="60px">Total Amount</th>
            </thead>

            <tbody>
                @php
                    $sum_total_amount = 0;
                @endphp

                @foreach ($dateWiseReceiveSearch as $dateWiseReceive)
                    @php
                        $total_amount = $dateWiseReceive->total_amount ? $dateWiseReceive->total_amount : 0;
                    @endphp
                    <tr>
                        {{-- <td>{{ $dateWisePurchase->stock_date }}</td> --}}
                        <td>{{ \Carbon\Carbon::parse($dateWiseReceive->stock_date)->format('d/m/Y') }}</td>
                        <td>{{ $dateWiseReceive->invoice_no }}</td>
                        <td>
                            <span
                                style="font-size: 12px; font-style: italic; font-weight: bold">{{ $dateWiseReceive->production_no }}</span>
                        </td>

                        <td style="text-align: right;">
                            {{ formatCurrency($dateWiseReceive->total_amount) }}
                        </td>

                    </tr>
                    @php
                        $sum_total_amount += $total_amount;
                        // $sum_discount += $discount;
                        // $sum_netPayable += $netPayable;
                    @endphp
                @endforeach

                <tr>
                    <td colspan="3" style="font-weight: bold; text-align: right;">Total:</td>
                    <td style="font-weight: bold; text-align: right;">
                        @if (!empty($sum_total_amount))
                            <span class="double-underline">{{ formatCurrency($sum_total_amount) }}</span>
                        @endif
                    </td>
                </tr>

            </tbody>
        @else
            <tr class="text-center">
                <td colspan="5">No Statistics History Found !!!</td>
            </tr>
        @endif
    </table>

    {{-- include footer --}}
    @include('pages.pdf.partials.footer_pdf')

</body>

</html>
