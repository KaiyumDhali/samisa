
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
            bottom: 0;
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
    </style>

    {{-- <script>
        window.onload = function() {
            window.print();
            // Optionally close the tab after printing
            setTimeout(() => window.close(), 2000);
        };
    </script> --}}

</head>
<body style="font-size:12px">
{{-- include header --}}
@include('pages.pdf.partials.header_pdf')

<div class="text-center py-0 my-0">
    <h5 class="py-0 my-0 pdf_title">Stock Transfer Invoice</h5>

</div>

<table style="width: 100%">
    <tr>
    <td style="width: 50%">
                <h6 class="my-0">Stock Transfer Details</h6>
                <table style="font-size: 13px; font-style:bold;">
                    <thead>
                        <tr>
                            <td>From Warehouse</td>
                            <td>:</td>
                            <td>{{ $results[0]->from_warehouse_name ?? 'N/A' }}</td>
                        </tr>
                        <tr>
                            <td scope="col">To Warehouse</td>
                            <td>:</td>
                            <td>{{ $results[0]->to_warehouse_name ?? 'N/A' }}</td>
                        </tr>
                        
                    </thead>
                </table>
            </td>
            <td style="width: 50%">
                <table style="font-size: 13px; font-style:bold;" align="right">
                    <thead style="text-align: right;">
                        <tr>
                            <td>
                                Invoice No : ({{ $results[0]->invoice_no ?? 'N/A' }})
                            </td>
                        </tr>
                       
                        <tr>
                            <td scope="col" style="text-align: right; font-weight: bold;">Invoice Date :
                            {{ $results[0]->stock_date ?? 'N/A' }}</td>
                        </tr>
                        <!-- <tr>
                            <td scope="col" style="text-align: right; font-weight: bold;">Status :
                            {{ $results[0]->product_status == 1 ? 'Approved' : 'Pending' }}</td>
                        </tr> -->
                       

                    </thead>
                </table>
            </td>
    </tr>
</table>

    <table class="table table-bordered table-striped table-sm table-hover pt-3">
        <thead>
            <tr class="text-start text-uppercase text-center text-light bg-secondary ">
                <th>SL</th>
                <th>S. ID</th>
                <th>Status</th>
                <th>PID</th>
                <th>Product Name</th>
                <th>Quantity</th>
                <th>Price</th>
                <th>Total</th>
               
            </tr>
        </thead>
        <tbody class="fw-semibold text-gray-600">
        <span class="d-none">{{ $initialTotal = 0, $initialDiscount = 0 }}</span>
            @foreach ($results as $index => $result)
                <tr class="text-center">
                    <td>{{ $index + 1 }}</td>
                    <td>{{ $result->stock_id }}</td>
                    <td>{{ $result->product_status == 1 ? 'Approved' : 'Pending' }}</td>
                    <td>{{ $result->product_id }}</td>
                    <td class="text-left">{{ $result->product_name }}</td>
                    <td class="text-right">{{ $result->quantity }}</td>
                    <td class="text-right">{{ $result->unit_price }}</td>
                    <td class="text-right">{{ formatCurrency($productTotal = $result->total_amount) }}</td>

                    <span class="d-none text-right">{{ $initialTotal = $initialTotal + $productTotal }}</span>
                </tr>
            @endforeach

            <!--end::VAT-->
            <!--begin::Grand total-->
            <tr style="font-size:13px">
                <td colspan="6" class="" style="text-align: right; font-weight: bold;">Net Amount (Taka)</td>
                <td colspan="6" class="text-right" style="font-weight: bold;">
                    {{ formatCurrency($initialTotal) }}</td>
            </tr>
        </tbody>
    </table>
    <p><b>In Words : {{ numberToWord($initialTotal) }}</b> </p>
    @if (isset($results[0]->remarks) && $results[0]->remarks)
    <p><b>Remarks: </b>{{ $results[0]->remarks }}</p>
@endif


    <br>
    <p class="text-capitalize"> <b style="text-transform: uppercase;">for {{ $data['company_name'] }}</b> </p>

    {{-- <div style="text-align: left; padding-top: 30px;">
        <div style="display: inline-block; width: 130px; padding-right: 20px">
            <p style="border-top: 1px solid #000000; font-weight: bold; text-align: center;">Authorised Signature </p>
        </div>
        <div style="display: inline-block; width: 130px; padding: 0px 20px; float: right;">
            <p style="border-top: 1px solid #000000; font-weight: bold; text-align: center;">Customer Signature</p>
        </div>

    </div> --}}

    <footer>
        <div class="footer-signature pb-3">
            <p style="display: inline-block; width: 130px;">Authorised Signature</p>
            <p style="display: inline-block; width: 130px; float: right;">Received By</p>
        </div>
    </footer>

    {{-- include footer --}}
    @include('pages.pdf.partials.footer_pdf')
</body>
</html>
