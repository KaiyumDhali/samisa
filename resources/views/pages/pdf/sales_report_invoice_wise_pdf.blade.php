@php
    $imagePath = public_path(Storage::url($data['company_logo_one']));
    $imageDataUri = 'data:' . mime_content_type($imagePath) . ';base64,' . base64_encode(file_get_contents($imagePath));

    // Bengali warning notice (image, so conjuncts render correctly in dompdf)
    $noticePath = public_path('images/warning_notice.png');
    $noticeDataUri = file_exists($noticePath)
        ? 'data:image/png;base64,' . base64_encode(file_get_contents($noticePath))
        : null;
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

        footer {
            position: fixed;
            bottom: 14px; /* "Design and Developed By" footer er upore thakar jonno. aro upore tulte baran, niche namate komen */
            left: 0;
            width: 100%;
            text-align: left;
            padding-top: 10px;
            font-size: 12px;
        }

        .footer-signature {
            display: flex;
            justify-content: space-between;
            padding: 0 20px;
        }

        .footer-signature p {
            width: 130px;
            border-top: 1px solid #000;
            text-align: center;
            font-weight: bold;
        }

        .warning-notice-img {
            margin-top: 8px;
            padding: 0 20px;
        }

        .warning-notice-img img {
            width: 100%;
            height: auto;
        }

        {!! file_get_contents(resource_path('views/pdf/style.css')) !!}
        
    </style>

    {{-- <script>
        window.onload = function() {
            window.print();
            // Optionally close the tab after printing
            setTimeout(() => window.close(), 2000);
        };
    </script> --}}

</head>

<body style="font-size:10px">
    {{-- include header --}}
    @include('pages.pdf.partials.header_pdf')

    <div class="text-center py-0 my-0">

        @if ($productServiceDetail)
            <h5 class="py-0 my-0 pdf_title">Service Invoice</h5>
        @else
            <h5 class="py-0 my-0 pdf_title">Bill</h5>
        @endif
    </div>

    <table style="width: 100%">
        <tr>
            <td style="width: 50%">
                <h6 class="my-0">Customer Details</h6>
                <table style="font-size: 10px; font-style:bold;">
                    <thead>
                        <tr>
                            <td>Customer ID</td>
                            <td>:</td>
                            <td>{{ $stocks[0]->customer_finance_account->id }}</td>
                        </tr>
                        <tr>
                            <td scope="col">Customer Name</td>
                            <td>:</td>
                            <td>{{ $stocks[0]->customer_finance_account->account_name }}</td>
                        </tr>
                        <tr>
                            <td scope="col">Address</td>
                            <td>:</td>
                            <td>{{ $stocks[0]->customer_finance_account->account_address }}</td>
                        </tr>
                        <tr>
                            <td scope="col">Mobile No</td>
                            <td>:</td>
                            <td>{{ $stocks[0]->customer_finance_account->account_mobile }}</td>
                        </tr>
                    </thead>
                </table>
            </td>
            <td style="width: 50%">
                <table style="font-size: 10px; font-style:bold;" align="right">
                    <thead style="text-align: right;">
                        <tr>
                            <td style="width:50%; text-align:left; padding:4px 0; font-weight:bold;">
                                Invoice No :
                            </td>
                             <td style="width:50%; text-align:right; padding:4px 0;">
            <span style="
                display:inline-block;
                width:124px;
                height:20px;
                border:1px solid #000;
                vertical-align:middle;
            "></span>
        </td>
                        </tr>
                        <tr>
        <td style="width:50%; text-align:left; padding:4px 0; font-weight:bold;">
            Delivery Challan No :
        </td>
        <td style="width:50%; text-align:right; padding:4px 0;">
            <span style="
                display:inline-block;
                width:124px;
                height:20px;
                border:1px solid #000;
                vertical-align:middle;
            "></span>
        </td>
    </tr>
                        
                        <tr>
                            <td style="text-align:left; padding:4px 0; font-weight:bold;">
            Date :
        </td>
        <td style="text-align:left; padding:4px 0; font-weight:bold;">
            {{ \Carbon\Carbon::parse($stocks[0]->stock_date)->format('d-m-Y') }}
        </td>
                        </tr>
                        @if ($productServiceDetail)
                            <tr>
                                <td scope="col" style="text-align: right; font-weight: bold;">
                                    Service Product : {{ $productServiceDetail->product_name }}
                                </td>
                            </tr>
                            <tr>
                                <td scope="col" style="text-align: right; font-weight: bold;">
                                    Service Location : {{ $productServiceDetail->service_location }}
                                </td>
                            </tr>
                        @endif

                    </thead>
                </table>
                
            </td>
        </tr>
    </table>



    <table class="table table-bordered table-striped table-sm table-hover pt-3">
        <!--begin::Table head-->
        <thead>
            <tr class="text-start text-uppercase text-center report-header">
                <th class="min-w-50px">SL</th>
                <th class="min-w-175px">Product ID</th>
                <th class="min-w-175px">Product Name</th>
                <th class="min-w-70px">Unit</th>
                <th class="min-w-70px">Quantity</th>
                <th class="min-w-100px">Unit Price</th>
                <th class="min-w-100px">Discount</th>
                <th class="min-w-100px ">Total Amount</th>
            </tr>
        </thead>
        <!--end::Table head-->
        <!--begin::Table body-->
        <tbody class="fw-semibold text-gray-600">
            <!--begin::Products-->
            <span class="d-none">{{ $initialTotal = 0, $initialDiscount = 0 }}</span>
            @foreach ($stocks as $stock)
                <tr class="text-center">
                    <td class="">{{ $loop->iteration }}</td>
                    <td class="">{{ $stock->product_id }}</td>
                    <td class="text-left">{{ $stock->product->product_name }}</td>
                    <td class="text-center">{{ $stock->product->unit->unit_name }}</td>
                    <td class="">{{ $stock->stock_out_quantity }}</td>
                    <td class="text-right">
                        {{ formatCurrency($stock->stock_out_unit_price) }}</td>
                    <td class="text-right">
                        {{ formatCurrency($stock->stock_out_discount) }}</td>
                    <td class="text-right">
                        {{ formatCurrency($productTotal = $stock->stock_out_total_amount) }}
                    </td>
                    <span
                        class="d-none text-right">{{ $initialTotal = $initialTotal + $productTotal, $initialDiscount = $initialDiscount + $stock->stock_out_discount }}</span>
                </tr>
            @endforeach
            <!--end::Products-->
            <!--begin::Subtotal-->
            <tr class="" style="font-size:10px">
                <td colspan="7" class="" style="text-align: right; font-weight: bold;">Subtotal</td>
                <td colspan="7" class="text-right" style="font-weight: bold;">
                    {{ formatCurrency($initialTotal) }}
                </td>
            </tr>
            <!--end::Subtotal-->
            <!--begin::VAT-->

            <tr style="font-size:10px">
                <td colspan="7" class="" style="text-align: right; font-weight: bold;">INV Discount</td>
                <td colspan="7" class="text-right" style="font-weight: bold;">0.00</td>
            </tr>
            <!--end::VAT-->
            <!--begin::Grand total-->
            <tr style="font-size:10px">
                <td colspan="7" class="" style="text-align: right; font-weight: bold;">Net Amount (Taka)</td>
                <td colspan="7" class="text-right" style="font-weight: bold;">
                    {{ formatCurrency($initialTotal) }}</td>
            </tr>
            @php
                $available = $ledger_with_balance[0]->running_balance ?? 0;
                $paidAmount = 0;
                $dueAmount = 0;

                if ($available >= 0) {
                    $paidAmount = $initialTotal;
                    $dueAmount = 0;
                } else {
                    if (abs($available) <= $initialTotal) {
                        $dueAmount = abs($available);
                        $paidAmount = $initialTotal - abs($available);
                    } else {
                        $dueAmount = $initialTotal;
                        $paidAmount = 0;
                    }
                }
            @endphp
            <tr style="font-size:10px">
                <td colspan="7" class="" style="text-align: right; font-weight: bold;">Paid Amount</td>
                <td colspan="7" class="text-right" style="font-weight: bold;">
                    {{ formatCurrency($paidAmount) }} </td>
            </tr>
            <tr style="font-size:10px">
                <td colspan="7" class="" style="text-align: right; font-weight: bold;">Due Amount (Taka)</td>
                <td colspan="7" class="text-right" style="font-weight: bold;">
                    <span class="double-underline">{{ formatCurrency($dueAmount) }}
                        </spam>
                </td>
            </tr>
            <!--end::Grand total-->
        </tbody>
        <!--end::Table head-->
    </table>
   
    <p><b>In Words: {{ numberToWord($initialTotal) }}</b> </p>

    {{-- @if ($stocks[0]->remarks)
        <p><b>Remarks: </b>{{$stocks[0]->remarks}} </p>
    @endif --}}

   @if ($customerPayment)
    <p><b>Narration:</b> {{ preg_replace('/^Invoice:\S+,\s*/i', '', $paymentNarration) }}</p>
@else
    @if ($stocks[0]->remarks)
        <p><b>Remarks: </b>{{ $stocks[0]->remarks }} </p>
    @endif
@endif

    <br>


    {{-- <div style="text-align: left; padding-top: 30px;">
        <div style="display: inline-block; width: 130px; padding-right: 20px">
            <p style="border-top: 1px solid #000000; font-weight: bold; text-align: center;">Authorised Signature </p>
        </div>
        <div style="display: inline-block; width: 130px; padding: 0px 20px; float: right;">
            <p style="border-top: 1px solid #000000; font-weight: bold; text-align: center;">Customer Signature</p>
        </div>

    </div> --}}




    <footer>
        <p class="text-capitalize"> <b style="text-transform: uppercase;">for {{ $data['company_name'] }}</b> </p>
        <br>
        <br>
        <div class="footer-signature pb-1">
            <p style="display: inline-block; width: 130px;">Authorised Signature</p>
            <p style="display: inline-block; width: 130px; float: right;">Customer Signature</p>
        </div>

        {{-- Warning notice (image) - signature er niche --}}
        @if ($noticeDataUri)
            <div class="warning-notice-img">
                <img src="{{ $noticeDataUri }}" alt="সতর্কবার্তা">
            </div>
        @endif
    </footer>

    {{-- include footer --}}
    @include('pages.pdf.partials.footer_pdf')
</body>

</html>