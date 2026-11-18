@php
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
            font-size: 10px;
        }

        .footer-signature{
    width:100%;
}

.footer-signature table{
    width:100%;
    border-collapse:collapse;
}

.footer-signature td{
    width:50%;
}

.signature-left{
    text-align:left;
}

.signature-right{
    text-align:right;
}

.signature-line{
    display:inline-block;
    width:170px;
    border-top:1px solid #000;
    text-align:center;
    font-weight:bold;
    padding-top:3px;
}
.pdf_title{
    font-size:22px;
    font-weight:700;
    text-transform:uppercase;
}

.warning-notice-img {
    margin-top: 8px;
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

    <div class="text-center">
        <h5 class="pb-0 mb-0 pt-0 pdf_title">Delivery Challan</h5>
    </div>

    <!-- <h6 class="my-0">Customer Details</h6> -->
    <table style="font-size: 10px;  font-style:bold;">
        <thead>
            <tr>
                <td>Customer ID</td>
                <td>:</td>
                <td>{{$stocks[0]->customer_finance_account->id}}</td>
            </tr>
            <tr>
                <td scope="col">Customer Name</td>
                <td>:</td>
                <td>{{$stocks[0]->customer_finance_account->account_name}}</td>
            </tr>
            <tr>
                <td scope="col">Address</td>
                <td>:</td>
                <td>{{$stocks[0]->customer_finance_account->account_address}}</td>
            </tr>
            <tr>
                <td scope="col">Mobile No</td>
                <td>:</td>
                <td>{{$stocks[0]->customer_finance_account->account_mobile}}</td>
            </tr>
        </thead>
    </table>


    <table style="position: absolute; font-size: 10px; font-style:bold; margin-top: -70px;" align="right">
        <thead>
    <tr>
        <td colspan="2" style="padding:3px 0;"></td>
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
            Delivery Truck No :
        </td>
        <td style="text-align:right; padding:4px 0;">
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
</thead>
    </table>

<br>

    <p><b>Dear Sir,</b><br>Incompliance  with your orders reffered hereunder, please receive the following material which we hope you will find in conformity with you requirement.</p>


    <table class="table table-bordered table-striped table-sm table-hover">
        <!--begin::Table head-->

        <thead>
            <tr class="text-start text-uppercase text-center report-header">
                <th class="min-w-50px align-middle">SL</th>
                <th class="min-w-175px align-middle">Product Code</th>
                <th class="min-w-175px align-middle">Product Name</th>
                <th class="min-w-70px align-middle">Unit <br>(PCS/DZN)</th>
                <th class="min-w-70px align-middle">Total Quantity</th>
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
                    <td class="text-center">{{ $stock->stock_out_quantity }}</td>
                </tr>
            @endforeach
            <!--end::Products-->
        </tbody>
        <!--end::Table head-->
    </table>

    <p><b>Remarks: </b>{{$stocks[0]->remarks}} </p>


    <!-- <p class="text-capitalize"> <b style="text-transform: uppercase;">for {{ $data['company_name'] }}</b> </p> -->


    {{-- <div style="text-align: left; padding-top: 30px;">
        <div style="display: inline-block; width: 100px; padding-right: 20px">
            <p style="border-top: 1px solid #000000; font-weight: bold; text-align: center;">Prepared by </p>
        </div>
        <div style="display: inline-block; width: 100px; padding: 0px 20px;">
            <p style="border-top: 1px solid #000000; font-weight: bold; text-align: center;">Checked by</p>
        </div>
        <div style="display: inline-block; width: 100px; padding: 0px 20px;">
            <p style="border-top: 1px solid #000000; font-weight: bold; text-align: center;">Issued by</p>
        </div>
        <div style="display: inline-block; width: 100px; padding-left: 20px;">
            <p style="border-top: 1px solid #000000; font-weight: bold; text-align: center;">Delivered by</p>
        </div>
        <div style="display: inline-block; width: 120px; padding-left: 20px;">
            <p style="border-top: 1px solid #000000; font-weight: bold; text-align: center;">Received by</p>
        </div>
    </div> --}}

    {{-- <div style="display: flex; justify-content: space-between; align-items: center; padding-top: 30px;">
        <div style="display: inline-block; text-align: center; padding-right: 20px;">
            <p style="border-top: 1px solid #000000; font-weight: bold;">Prepared by</p>
        </div>
        <div style="display: inline-block; text-align: center; padding: 0 20px;">
            <p style="border-top: 1px solid #000000; font-weight: bold;">Checked by</p>
        </div>
        <div style="display: inline-block; text-align: center; padding: 0 20px;">
            <p style="border-top: 1px solid #000000; font-weight: bold;">Issued by</p>
        </div>
        <div style="display: inline-block; text-align: center; padding-left: 20px;">
            <p style="border-top: 1px solid #000000; font-weight: bold;">Delivered by</p>
        </div>
        <div style="display: inline-block; text-align: center; padding-left: 20px;">
            <p style="border-top: 1px solid #000000; font-weight: bold;">Received the above in order with good condition</p>
        </div>
    </div> --}}


    
    

    <footer>

    <p style="text-align:left;
              font-weight:bold;
              text-transform:uppercase;
              margin-bottom:50px;">
        FOR {{ strtoupper($data['company_name']) }}
    </p>

    <div class="footer-signature">
    <table>
        <tr>
            <td class="signature-left">
                <span class="signature-line">Prepared by</span>
            </td>

            <td class="signature-right">
                <span class="signature-line">Received by</span>
            </td>
        </tr>
    </table>
</div>

    <p style="text-align:center;
              font-weight:bold;
              margin-top:18px;">
        N. B: Please return back duly signed duplicate copy.
    </p>

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