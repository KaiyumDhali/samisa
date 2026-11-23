<?php

namespace App\Http\Controllers\Product;

use App\Http\Controllers\Controller;
use App\Models\CompanySetting;
use App\Models\Warehouse;
use App\Models\Stock;
use App\Models\Supplier;
use App\Models\SupplierLedger;
use App\Models\Customer;
use App\Models\CustomerLedger;
use App\Models\Product;
use App\Models\ProductType;
use App\Models\ProductCategory;
use App\Models\ProductSubCategory;
use App\Models\ProductBrand;
use App\Models\ProductColor;
use App\Models\ProductSize;
use App\Models\ProductUnit;
use App\Models\FinanceAccount;
use Illuminate\Http\Request;
use App\Models\FinanceTransaction;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;
use Dompdf\Dompdf;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Support\Facades\View;
use Validator;
use Auth;


class StockController extends Controller
{

    function __construct()
    {
        $this->middleware('permission:read stock report|write stock report|create stock report', ['only' => ['index', 'show']]);
        $this->middleware('permission:create stock report', ['only' => ['create', 'store']]);
        $this->middleware('permission:write stock report', ['only' => ['edit', 'update', 'destroy']]);
        $this->middleware('permission:read stock report', ['only' => ['stock']]);

        $this->middleware('permission:read finish product receive', ['only' => ['receiveInvoiceReport', 'receiveInvoiceDateSearch']]);
        $this->middleware('permission:create finish product receive', ['only' => ['finishProductReceive', 'finishProductReceiveStore']]);
        $this->middleware('permission:write finish product receive', ['only' => ['receiveInvoiceDetails', 'receiveInvoiceDetailsPdf', 'receiveInvoiceEdit', 'receiveInvoiceUpdate']]);
    }

    // Product Details
    public function warehouseWiseProductDetails($id, $warehouseId)
    {
        // Fetch the product details with present stock calculation
        $productDetails = DB::table('products as p')
            ->join('product_units as pu', 'pu.id', '=', 'p.unit_id')
            ->select(
                'p.id as product_id',
                'p.product_name',
                'p.product_code',
                'p.purchase_price',
                'p.sales_price',
                'p.pack_size',
                'pu.unit_name',
                DB::raw("
                (
                    SELECT 
                        COALESCE(SUM(s.stock_in_quantity), 0) - COALESCE(SUM(s.stock_out_quantity), 0)
                    FROM stocks as s
                    WHERE s.product_id = p.id AND s.warehouse_id = $warehouseId
                ) as present_stock
            ")
            )
            ->where('p.id', $id)
            ->first();
        return response()->json($productDetails);
    }
    // Product Details
    public function productDetails($id)
    {
        $productDetails = Product::select('products.id', 'products.product_name', 'products.product_code', 'products.unit_id', 'products.purchase_price', 'products.sales_price', 'products.pack_size')
            ->with('unit')
            ->withSum('productStock', 'stock_in_quantity') // "product_stock_sum_stock_in_quantity"
            ->withSum('productStock', 'stock_out_quantity') // "product_stock_sum_stock_out_quantity"
            ->where('id', $id)
            ->get();
        return response()->json($productDetails);
    }

    // Product stock
    public function stock()
    {
        // $stocks = Stock::with(['product','product.category', 'product.subCategory'])->groupBy('product_id')
        //         ->selectRaw('SUM(stock_in_quantity) as stock_in_quantity , product_id')
        //         ->selectRaw('SUM(stock_out_quantity) as stock_out_quantity , product_id')
        //         ->get();
        $stocks = Stock::with(['product', 'product.category', 'product.subCategory'])->groupBy('product_id')
            ->selectRaw('SUM(stock_in_quantity) - SUM(stock_out_quantity) as total_quantity, product_id')
            ->get();
        // $stocks = Stock::with(['product','product.category', 'product.subCategory'])
        // ->withSum('productStock','stock_in_quantity')
        // ->withSum('productStock','stock_out_quantity')
        //         ->get();
        // dd($stocks);
        // $stocks = Stock::with(['product','product.category', 'product.subCategory'])->groupBy('product_id')
        // ->selectRaw('SUM(stock_in_quantity) as total_quantity , product_id')->whereHas('product', function($q){
        //     $q->where('status','=',1);
        // })->get();
        // dd($stocks);
        return view('pages.product.stock.stocks', compact('stocks'));
    }
    public function stock_pdf()
    {

        $companySetting = CompanySetting::where('status', 1)->orderBy('id', 'desc')->first();
        $data['company_name'] = $companySetting->company_name;
        $data['company_logo_one'] = $companySetting->company_logo_one;

        $stocks = Stock::with(['product', 'product.category', 'product.subCategory'])->groupBy('product_id')
            ->selectRaw('SUM(stock_in_quantity) - SUM(stock_out_quantity) as total_quantity, product_id')
            ->get();

        // return view('pages.product.stock.stocks', compact('stocks'));

        $pdf = PDF::loadView('pages.pdf.stock_report_pdf', array('stocks' => $stocks, 'data' => $data));
        $pdf->setPaper('A4', 'landscape');
        return $pdf->stream(Carbon::now() . '-stocks_report.pdf');
    }

    // stock_report_material_wise
    public function stockReportMaterialWise()
    {
        $warehouses = Warehouse::where('status', 1)->get();
        $products = Product::where('status', 1)->get();
        $startDate = Carbon::now()->format('d-m-Y');
        $endDate = Carbon::now()->format('d-m-Y');
        return view('pages.product.stock.stock_report_material_wise', compact('products', 'warehouses', 'startDate', 'endDate'));
    }
    public function stockReportMaterialWiseSearch($startDate, $endDate, $warehouseId, $productId, $pdf)
    {
        // $stockReportMaterialWise = DB::connection()->select("CALL sp_StockReportMaterialWise(?, ?)", array($startDate, $endDate));
        $stockReportMaterialWise = DB::connection()->select("CALL sp_StockReportMaterialWise(?, ?, ?, ?)", array($startDate, $endDate, $warehouseId, $productId));
        if ($pdf == "list") {
            return response()->json($stockReportMaterialWise);
        }
        if ($pdf == "pdfurl") {
            $companySetting = CompanySetting::where('status', 1)->orderBy('id', 'desc')->first();
            $data['company_name'] = $companySetting->company_name;
            $data['company_address'] = $companySetting->company_address;
            $data['company_mobile'] = $companySetting->company_mobile;
            $data['company_logo_one'] = $companySetting->company_logo_one;
            $data['start_date'] = $startDate;
            $data['end_date'] = $endDate;
            $pdf = PDF::loadView('pages.pdf.stock_report_material_wise_pdf', array('stockReportMaterialWise' => $stockReportMaterialWise, 'data' => $data));
            // $pdf->setPaper('A4', 'landscape');
            return $pdf->stream(Carbon::now() . '-stock_report_material_wise_pdf.pdf');
        }
    }

    // stockReportFinishGoodWise
   public function stockReportFinishGoodWise()
{
    $startDate = Carbon::now()->format('d-m-Y');
    $endDate   = Carbon::now()->format('d-m-Y');

    $warehouses   = Warehouse::where('status', 1)->get();
    $products     = Product::where('status', 1)->get();
    $productTypes = ProductType::where('status', 1)->get(); // tomar model/table onujayi

    return view('pages.product.stock.stock_report_finish_good_wise',
        compact('startDate', 'endDate', 'warehouses', 'products', 'productTypes'));
}

public function stockReportFinishGoodWiseSearch($startDate, $endDate, $warehouseId, $productId, $typeId, $pdf)
{
    $stockReportFinishGoodWise = DB::connection()->select(
        "CALL sp_StockReportFinishGoodWise(?, ?, ?, ?, ?)",
        [$startDate, $endDate, $warehouseId, $productId, $typeId]
    );

    if ($pdf == "list") {
        return response()->json($stockReportFinishGoodWise);
    }

    if ($pdf == "pdfurl") {
            $companySetting = CompanySetting::where('status', 1)->orderBy('id', 'desc')->first();
            $data['company_name'] = $companySetting->company_name;
            $data['company_address'] = $companySetting->company_address;
            $data['company_mobile'] = $companySetting->company_mobile;
            $data['company_logo_one'] = $companySetting->company_logo_one;
            $data['start_date'] = $startDate;
            $data['end_date'] = $endDate;
            $pdf = PDF::loadView('pages.pdf.stock_report_finish_good_wise_pdf', array('stockReportFinishGoodWise' => $stockReportFinishGoodWise, 'data' => $data));
            // $pdf->setPaper('A4', 'landscape');
            return $pdf->stream(Carbon::now() . '-stock_report_finish_good_wise_pdf.pdf');
        }
    }

    // stockReportFinishGoodWise
    public function stockReportItemWise()
    {
        $startDate = Carbon::now()->format('d-m-Y');
        $endDate = Carbon::now()->format('d-m-Y');
        $products = Product::where('is_saleable', 1)->where('status', 1)->pluck('product_name', 'id')->all();

        return view('pages.product.stock.stock_report_item_wise', compact('products', 'startDate', 'endDate'));
    }
    public function stockReportItemWiseSearch($startDate, $endDate, $productID, $pdf)
    {
        $stockReportItemWise = DB::connection()->select("CALL sp_StockReportItemWise(?, ?, ?)", array($startDate, $endDate, $productID));

        if ($pdf == "list") {
            return response()->json($stockReportItemWise);
        }
        if ($pdf == "pdfurl") {
            $companySetting = CompanySetting::where('status', 1)->orderBy('id', 'desc')->first();
            $data['company_name'] = $companySetting->company_name;
            $data['company_address'] = $companySetting->company_address;
            $data['company_mobile'] = $companySetting->company_mobile;
            $data['company_logo_one'] = $companySetting->company_logo_one;
            $data['start_date'] = $startDate;
            $data['end_date'] = $endDate;
            $pdf = PDF::loadView('pages.pdf.stock_report_item_wise_pdf', array('stockReportItemWise' => $stockReportItemWise, 'data' => $data));
            // $pdf->setPaper('A4', 'landscape');
            return $pdf->stream(Carbon::now() . '-stock_report_item_wise_pdf.pdf');
        }
    }

    public function rawMaterialConsume()
    {
        $warehouses = Warehouse::where('status', 1)->get();
        $products = Product::where('type_id', 2)->where('status', 1)->get();

        return view('pages.production.raw_material_consume.raw_material_consume', compact('warehouses', 'products'));
    }


    public function rawMaterialConsumeStore(Request $request)
    {
        // dd($request->all());

        $validator = Validator::make($request->all(), [
            'stock_date' => 'required',
            'warehouse_id' => 'required',
            'table_product_id' => 'required',
        ]);

        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }

        $stock_date = $request->input('stock_date');
        $warehouse_id = $request->input('warehouse_id');
        $supplierInvoiceNo = $request->input('supplier_invoice_no');
        $remarks = $request->input('remarks');
        $done_by = Auth::user()->name;

        DB::beginTransaction();
        try {

            // get transferInvoice
            $consumeNo = DB::table('invoiceno')->first('consume_product_no');
            $getConsumeNo = $consumeNo->consume_product_no;
            $consumeInvoice = 'RMC' . str_pad($getConsumeNo, 6, '0', STR_PAD_LEFT);
            DB::table('invoiceno')->update([
                'consume_product_no' => $getConsumeNo + 1,
            ]);

            // get delivery_challan_no
            // $deliveryChallanNo = DB::table('invoiceno')->first('delivery_challan_no');
            // $getDeliveryChallanNo = $deliveryChallanNo->delivery_challan_no;
            // $deliveryChallanNumber = 'CHA' . str_pad($getDeliveryChallanNo, 6, '0', STR_PAD_LEFT);
            // DB::table('invoiceno')->update([
            //     'delivery_challan_no' => $getDeliveryChallanNo + 1,
            // ]);

            foreach ($request->get('table_product_id') as $key => $productId) {
                $consumeQuantity = $request->input('table_product_quantity')[$key];
                $consumePrice = $request->input('table_product_price')[$key];
                $consumePurchasePrice = $request->input('table_purchase_price')[$key];
                $consumeDiscount = 0;
                $consumeTotal = $request->input('table_product_cart_amount')[$key];

                $product = Product::find($productId);
                $productName = $product ? $product->product_name : 'Unknown Product';

                // Only update the sales_price for the specific product if it's different
                if ($product && $consumePurchasePrice != $product->purchase_price) {
                    DB::table('products')
                        ->where('id', $product->id) // Target the specific product by ID
                        ->update(['purchase_price' => $consumePurchasePrice]);
                }

                $consumeProductOut = new Stock();
                $consumeProductOut->warehouse_id = $warehouse_id;
                $consumeProductOut->stock_date = $stock_date;
                $consumeProductOut->stock_type = 'Out';
                $consumeProductOut->invoice_no = $consumeInvoice;
                $consumeProductOut->product_id = $productId;
                $consumeProductOut->supplier_invoice_no = $supplierInvoiceNo;
                $consumeProductOut->purchase_price = $consumePurchasePrice;

                $consumeProductOut->stock_in_quantity = 0;
                $consumeProductOut->stock_in_unit_price = 0;
                $consumeProductOut->stock_in_discount = 0;
                $consumeProductOut->stock_in_total_amount = 0;

                $consumeProductOut->stock_out_quantity = $consumeQuantity;
                $consumeProductOut->stock_out_unit_price = $consumePrice;
                $consumeProductOut->stock_out_discount = $consumeDiscount;
                $consumeProductOut->stock_out_total_amount = $consumeTotal;

                $consumeProductOut->remarks = $remarks;
                $consumeProductOut->status = 0;
                $consumeProductOut->done_by = $done_by;
                $consumeProductOut->save();
            }



            DB::commit();
        } catch (\Exception $e) {
            DB::rollback();
            return back()->withErrors(['error' => 'Ops ! Could Not add consume product history. DB transaction lost']);
        }
        return back()->with([
            'message' => 'Consume Product History Added Successfully!',
            'alert-type' => 'success',
            'invoice' => $consumeInvoice,
            // 'delivery_challan' => $deliveryChallanNumber,
        ]);
    }

    public function rawMaterialInvoiceReport()
    {
        return view('pages.production.raw_material_consume.raw_material_report_invoice_wise');
    }

    public function rawMaterialInvoiceDateSearch($startDate, $endDate, $pdf)
    {
        $inv = 'RMC';

        $query = Stock::selectRaw('stocks.invoice_no, MIN(stocks.stock_date) as stock_date, SUM(stocks.purchase_price * stocks.stock_out_quantity) as total_amount, MIN(stocks.supplier_invoice_no) as production_no')
            ->where('stocks.invoice_no', 'LIKE', '%' . $inv . '%');

        if ($startDate && $endDate) {
            // Assuming $startDate and $endDate are in the format 'YYYY-MM-DD'
            $query->whereRaw('DATE(stocks.stock_date) BETWEEN ? AND ?', [$startDate, $endDate]);
        }

        if ($pdf == "list") {
            $consumeInvoices = $query->groupBy('stocks.invoice_no')
                ->orderBy('stocks.invoice_no', 'ASC')
                ->get();
            return response()->json($consumeInvoices);
        }


        if ($pdf == "pdfurl") {
            $consumeInvoices = $query->groupBy('stocks.invoice_no')
                ->orderBy('stocks.invoice_no', 'ASC')
                ->get();
            $companySetting = CompanySetting::where('status', 1)->orderBy('id', 'desc')->first();
            $data['company_name'] = $companySetting->company_name;
            $data['company_address'] = $companySetting->company_address;
            $data['company_logo_one'] = $companySetting->company_logo_one;
            $data['company_mobile'] = $companySetting->company_mobile;

            $data['start_date'] = $startDate;
            $data['end_date'] = $endDate;
            $pdf = PDF::loadView('pages.pdf.consume_date_invoice_wise_report_pdf', array('dateWiseReceiveSearch' => $consumeInvoices, 'data' => $data));
            $pdf->setPaper('A4', 'portrait');
            return $pdf->stream(Carbon::now() . '-consume_date_invoice_wise_report_pdf.pdf');
        }
    }

    public function consumeInvoiceDetails($invoiceNo)
    {
        $stocks = Stock::with(['product', 'supplier_finance_account'])->where('invoice_no', $invoiceNo)->get();
        $supplier_ids = $stocks->pluck('supplier_id')->unique();
        $acid = $supplier_ids->first();
        // $supplierPayment = FinanceTransaction::where('invoice_no', $invoiceNo)->where('acid', $acid)->where('balance_type', 'Dr')->pluck('amount')->first();
        $supplierPayment = FinanceTransaction::where('invoice_no', $invoiceNo)->where('acid', $stocks[0]->supplier_id)->where('balance_type', 'Dr')->whereNotNull('payment_type')->where('payment_type', '!=', '')->pluck('amount')->first();
        $paymentNarration = FinanceTransaction::where('invoice_no', $invoiceNo)->where('acid', $acid)->where('balance_type', 'Dr')->pluck('narration')->first();

        return view('pages.production.raw_material_consume.raw_material_report_invoice_details', compact('stocks', 'supplierPayment', 'paymentNarration'));
    }

    public function consumeInvoiceDetailsPdf($invoices)
    {
        $companySetting = CompanySetting::where('status', 1)->orderBy('id', 'desc')->first();
        $data['company_name'] = $companySetting->company_name;
        $data['company_address'] = $companySetting->company_address;
        $data['company_logo_one'] = $companySetting->company_logo_one;
        $data['company_mobile'] = $companySetting->company_mobile;

        $stocks = Stock::with(['product', 'supplier_finance_account'])->where('invoice_no', $invoices)->get();
        $supplier_ids = $stocks->pluck('supplier_id')->unique();
        $acid = $supplier_ids->first();
        // $supplierPayment = FinanceTransaction::where('invoice_no', $invoices)->where('acid', $acid)->where('balance_type', 'Dr')->pluck('amount')->first();
        $supplierPayment = FinanceTransaction::where('invoice_no', $invoices)->where('acid', $stocks[0]->supplier_id)->where('balance_type', 'Dr')->whereNotNull('payment_type')->where('payment_type', '!=', '')->pluck('amount')->first();
        $paymentNarration = FinanceTransaction::where('invoice_no', $invoices)->where('acid', $acid)->where('balance_type', 'Dr')->pluck('narration')->first();

        $pdf = PDF::loadView('pages.pdf.consume_report_invoice_wise_pdf', array('stocks' => $stocks, 'invoices' => $invoices, 'supplierPayment' => $supplierPayment, 'paymentNarration' => $paymentNarration, 'data' => $data));
        $pdf->setPaper('A4', 'portrait');
        return $pdf->stream(Carbon::now() . '-consume_report_invoice_wise_pdf.pdf');
    }

    public function consumeInvoiceEdit($invoiceNo)
    {
        $warehouses = Warehouse::where('status', 1)->get();
        $products = Product::where('is_purchaseable', 1)->where('type_id', 2)->where('status', 1)->get();
        $units = ProductUnit::get();
        // $suppliers = Supplier::where('status', 1)->get();
        $supplierAccounts = FinanceAccount::where('account_status', 1)->where('account_group_code', '400010001')->get();
        $fromAccounts = FinanceAccount::where('account_status', 1)->where('account_group_code', 'like', '10002%')->whereNotIn('account_group_code', ['100020001'])->get();
        $stocks = Stock::with(['product', 'unit', 'supplier_finance_account'])->where('invoice_no', $invoiceNo)->get();
        $supplierFinance = FinanceTransaction::where('invoice_no', $invoiceNo)->where('acid', $stocks[0]->supplier_id)->select('voucher_no', 'voucher_date')->first();
        // $supplierPayment = FinanceTransaction::where('invoice_no', $invoiceNo)->where('acid', $stocks[0]->supplier_id)->where('balance_type', 'Dr')->select('to_acc_name', 'amount')->first();
        $supplierPayment = FinanceTransaction::where('invoice_no', $invoiceNo)->where('acid', $stocks[0]->supplier_id)->where('balance_type', 'Dr')->whereNotNull('payment_type')->where('payment_type', '!=', '')->select('to_acc_name', 'amount')->first();

        // dd($stocks);
        // dd($supplierAccounts);
        return view('pages.production.raw_material_consume.raw_material_invoice_edit', compact('invoiceNo', 'warehouses', 'stocks', 'products', 'units', 'supplierAccounts', 'fromAccounts', 'supplierPayment', 'supplierFinance'));
    }

    public function consumeInvoiceUpdate(Request $request, $invoiceNo)
    {
        // dd($invoiceNo);
        // dd($request->all());

        $validator = Validator::make($request->all(), [
            'stock_date' => 'required|date',
            'warehouse_id' => 'required|array',
            'table_product_id' => 'required|array',
            'table_product_id.*' => 'integer|exists:products,id',
            'table_product_quantity' => 'required|array',
            'table_product_quantity.*' => 'numeric|min:1',
            'table_product_price' => 'required|array',
            'table_product_price.*' => 'numeric|min:0',
        ]);

        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }


        $stock_date = $request->input('stock_date');
        // $warehouse_id = $request->input('warehouse_id');
        $supplierInvoiceNo = $request->input('supplier_invoice_no');
        $remarks = $request->input('remarks');
        $done_by = Auth::user()->name;
        $createdAt = $request->input('created_at');

        $invNo = $invoiceNo;


        DB::beginTransaction();
        try {
            // Delete multiple rows from the stocks table where invoice_no matches
            Stock::where('invoice_no', $invoiceNo)->delete();

            // Delete multiple rows from the finance_transactions table where invoice_no matches
            // FinanceTransaction::where('invoice_no', $invoiceNo)->delete();

            DB::commit(); // Commit the transaction if all deletions succeed
        } catch (\Exception $e) {
            DB::rollBack(); // Rollback the transaction if any error occurs
            // Log the error if needed or handle exceptions (optional)
        }
        DB::beginTransaction();
        try {

            if ($request->has('table_product_id') && is_array($request->input('table_product_id')) && count($request->input('table_product_id')) > 0) {
                foreach ($request->input('table_product_id') as $key => $table_product_id) {
                    if (!isset($request->input('table_product_id')[$key]) || !isset($request->input('warehouse_id')[$key])) {
                        continue; // Skip this iteration if keys are missing
                    }

                    $consumeOut = new Stock();
                    $product_id = $request->input('table_product_id')[$key];
                    $warehouseId = $request->input('warehouse_id')[$key];
                    $consumeQuantity = $request->input('table_product_quantity')[$key] ?? 0;
                    $consumePrice = $request->input('table_product_price')[$key] ?? 0;
                    $consumeDiscount = $request->input('table_product_discount')[$key] ?? 0;
                    $consumeTotal = $request->input('table_product_cart_amount')[$key] ?? 0;

                    $product = Product::find($product_id);
                    if ($product && $consumePrice != $product->purchase_price) {
                        DB::table('products')->where('id', $product->id)->update(['purchase_price' => $consumePrice]);
                    }

                    $consumeOut->warehouse_id = $warehouseId;
                    $consumeOut->stock_date = $stock_date;
                    $consumeOut->stock_type = 'Out';
                    $consumeOut->invoice_no = $invNo;
                    $consumeOut->product_id = $product_id;
                    $consumeOut->supplier_invoice_no = $supplierInvoiceNo;
                    $consumeOut->stock_out_quantity = $consumeQuantity;
                    $consumeOut->stock_out_unit_price = $consumePrice;
                    $consumeOut->stock_out_discount = $consumeDiscount;
                    $consumeOut->stock_out_total_amount = $consumeTotal;
                    $consumeOut->status = 1;
                    $consumeOut->remarks = $remarks;
                    $consumeOut->done_by = $done_by;
                    $consumeOut->created_at = $createdAt;

                    $consumeOut->save();
                }
            } else {
                return back()->withErrors(['message' => 'No consume product provided.']);
            }



            DB::commit();
        } catch (\Exception $e) {
            DB::rollback();
            return back()->withErrors(['error' => 'Ops ! Could Not Update consume product history. DB transaction lost']);
        }
        return back()->with([
            'message' => 'Consume Product History Updated Successfully!',
            'alert-type' => 'success',
            // 'invoice' => $invoiceNo
        ]);
    }


    public function finishProductReceive()
    {
        $warehouses = Warehouse::where('status', 1)->get();

        // dd($warehouses);

        $products = Product::where('type_id', 1)->where('status', 1)->get();

        return view('pages.production.finish_product_receive.finish_product_receive', compact('warehouses', 'products'));
    }

    


    public function finishProductReceiveStore(Request $request)
    {
        // dd($request->all());

        $validator = Validator::make($request->all(), [
            'stock_date' => 'required',
            // 'warehouse_id' => 'required',
            'table_product_id' => 'required',
        ]);

        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }

        $stock_date = $request->input('stock_date');
        // $warehouse_id = $request->input('warehouse_id');
        $supplierInvoiceNo = $request->input('supplier_invoice_no');
        $remarks = $request->input('remarks');
        $done_by = Auth::user()->name;

        DB::beginTransaction();
        try {

            // get transferInvoice
            $receiveNo = DB::table('invoiceno')->first('finish_product_no');
            $getReceiveNo = $receiveNo->finish_product_no;
            $receiveInvoice = 'FPR' . str_pad($getReceiveNo, 6, '0', STR_PAD_LEFT);
            DB::table('invoiceno')->update([
                'finish_product_no' => $getReceiveNo + 1,
            ]);

            // get delivery_challan_no
            // $deliveryChallanNo = DB::table('invoiceno')->first('delivery_challan_no');
            // $getDeliveryChallanNo = $deliveryChallanNo->delivery_challan_no;
            // $deliveryChallanNumber = 'CHA' . str_pad($getDeliveryChallanNo, 6, '0', STR_PAD_LEFT);
            // DB::table('invoiceno')->update([
            //     'delivery_challan_no' => $getDeliveryChallanNo + 1,
            // ]);

            foreach ($request->get('table_product_id') as $key => $productId) {
                $stockQuantity = $request->input('table_product_quantity')[$key];
                $stockPrice = $request->input('table_product_price')[$key];
                $stockPurchasePrice = $request->input('table_purchase_price')[$key];
                $stockDiscount = 0;
                $stockTotal = $request->input('table_product_cart_amount')[$key];

                $warehouse_id = $request->input('table_warehouse_id')[$key];

                $product = Product::find($productId);
                $productName = $product ? $product->product_name : 'Unknown Product';

                // Only update the sales_price for the specific product if it's different
                if ($product && $stockPrice != $product->sales_price) {
                    DB::table('products')
                        ->where('id', $product->id) // Target the specific product by ID
                        ->update(['sales_price' => $stockPrice]);
                }
                $finishProductIn = new Stock();
                $finishProductIn->warehouse_id = $warehouse_id;
                $finishProductIn->stock_date = $stock_date;
                $finishProductIn->stock_type = 'In';
                $finishProductIn->invoice_no = $receiveInvoice;
                $finishProductIn->product_id = $productId;
                $finishProductIn->supplier_invoice_no = $supplierInvoiceNo;
                $finishProductIn->purchase_price = $stockPurchasePrice;
                $finishProductIn->stock_in_quantity = $stockQuantity;
                $finishProductIn->stock_in_unit_price = $stockPrice;
                $finishProductIn->stock_in_discount = $stockDiscount;
                $finishProductIn->stock_in_total_amount = $stockTotal;
                $finishProductIn->stock_out_quantity = 0;
                $finishProductIn->remarks = $remarks;
                $finishProductIn->status = 0;
                $finishProductIn->done_by = $done_by;
                $finishProductIn->save();
            }



            DB::commit();
        } catch (\Exception $e) {
            DB::rollback();
            return back()->withErrors(['error' => 'Ops ! Could Not add finish product receive history. DB transaction lost']);
        }
        return back()->with([
            'message' => 'Finish Product Receive History Added Successfully!',
            'alert-type' => 'success',
            'invoice' => $receiveInvoice,
            // 'delivery_challan' => $deliveryChallanNumber,
        ]);
    }


    public function receiveInvoiceReport()
    {
        return view('pages.production.finish_product_receive.receive_report_invoice_wise');
    }

    public function receiveInvoiceDateSearch($startDate, $endDate, $pdf)
    {
        $inv = 'FPR';

        // $query = Stock::selectRaw('stocks.invoice_no, stocks.supplier_id, fa.account_name, MIN(stocks.stock_date) as stock_date, SUM(stocks.stock_in_discount) as total_discount, MIN(stocks.vat_amount) as vat_amount, MIN(stocks.inv_discount) as inv_discount, SUM(stocks.stock_in_total_amount) as total_amount')
        //     ->join('finance_accounts as fa', function ($join) {
        //         $join->on('stocks.supplier_id', '=', 'fa.id')
        //             ->where('fa.account_group_code', '=', '400010001'); // Account Payable code 400010001 use supplier
        //     })
        //     ->where('stocks.invoice_no', 'LIKE', '%' . $inv . '%');

        $query = Stock::selectRaw('stocks.invoice_no, MIN(stocks.stock_date) as stock_date, SUM(stocks.stock_in_total_amount) as total_amount, MIN(stocks.supplier_invoice_no) as production_no')
            ->where('stocks.invoice_no', 'LIKE', '%' . $inv . '%');

        if ($startDate && $endDate) {
            // Assuming $startDate and $endDate are in the format 'YYYY-MM-DD'
            $query->whereRaw('DATE(stocks.stock_date) BETWEEN ? AND ?', [$startDate, $endDate]);
        }

        if ($pdf == "list") {
            $receiveInvoices = $query->groupBy('stocks.invoice_no')
                ->orderBy('stocks.invoice_no', 'ASC')
                ->get();
            return response()->json($receiveInvoices);
        }


        if ($pdf == "pdfurl") {
            $receiveInvoices = $query->groupBy('stocks.invoice_no')
                ->orderBy('stocks.invoice_no', 'ASC')
                ->get();
            $companySetting = CompanySetting::where('status', 1)->orderBy('id', 'desc')->first();
            $data['company_name'] = $companySetting->company_name;
            $data['company_address'] = $companySetting->company_address;
            $data['company_logo_one'] = $companySetting->company_logo_one;
            $data['company_mobile'] = $companySetting->company_mobile;

            $data['start_date'] = $startDate;
            $data['end_date'] = $endDate;
            $pdf = PDF::loadView('pages.pdf.receive_date_invoice_wise_report_pdf', array('dateWiseReceiveSearch' => $receiveInvoices, 'data' => $data));
            $pdf->setPaper('A4', 'portrait');
            return $pdf->stream(Carbon::now() . '-receive_date_invoice_wise_report_pdf.pdf');
        }
    }


    public function receiveInvoiceDetails($invoiceNo)
    {
        $stocks = Stock::with(['product', 'supplier_finance_account'])->where('invoice_no', $invoiceNo)->get();
        $supplier_ids = $stocks->pluck('supplier_id')->unique();
        $acid = $supplier_ids->first();
        // $supplierPayment = FinanceTransaction::where('invoice_no', $invoiceNo)->where('acid', $acid)->where('balance_type', 'Dr')->pluck('amount')->first();
        $supplierPayment = FinanceTransaction::where('invoice_no', $invoiceNo)->where('acid', $stocks[0]->supplier_id)->where('balance_type', 'Dr')->whereNotNull('payment_type')->where('payment_type', '!=', '')->pluck('amount')->first();
        $paymentNarration = FinanceTransaction::where('invoice_no', $invoiceNo)->where('acid', $acid)->where('balance_type', 'Dr')->pluck('narration')->first();

        return view('pages.production.finish_product_receive.receive_report_invoice_details', compact('stocks', 'supplierPayment', 'paymentNarration'));
    }

    public function receiveInvoiceDetailsPdf($invoices)
    {
        $companySetting = CompanySetting::where('status', 1)->orderBy('id', 'desc')->first();
        $data['company_name'] = $companySetting->company_name;
        $data['company_address'] = $companySetting->company_address;
        $data['company_logo_one'] = $companySetting->company_logo_one;
        $data['company_mobile'] = $companySetting->company_mobile;

        $stocks = Stock::with(['product', 'supplier_finance_account'])->where('invoice_no', $invoices)->get();
        $supplier_ids = $stocks->pluck('supplier_id')->unique();
        $acid = $supplier_ids->first();
        // $supplierPayment = FinanceTransaction::where('invoice_no', $invoices)->where('acid', $acid)->where('balance_type', 'Dr')->pluck('amount')->first();
        $supplierPayment = FinanceTransaction::where('invoice_no', $invoices)->where('acid', $stocks[0]->supplier_id)->where('balance_type', 'Dr')->whereNotNull('payment_type')->where('payment_type', '!=', '')->pluck('amount')->first();
        $paymentNarration = FinanceTransaction::where('invoice_no', $invoices)->where('acid', $acid)->where('balance_type', 'Dr')->pluck('narration')->first();

        $pdf = PDF::loadView('pages.pdf.receive_report_invoice_wise_pdf', array('stocks' => $stocks, 'invoices' => $invoices, 'supplierPayment' => $supplierPayment, 'paymentNarration' => $paymentNarration, 'data' => $data));
        $pdf->setPaper('A4', 'portrait');
        return $pdf->stream(Carbon::now() . '-purchase_report.pdf');
    }


    public function receiveInvoiceEdit($invoiceNo)
    {
        $warehouses = Warehouse::where('status', 1)->get();
        $products = Product::where('type_id', 1)->where('status', 1)->get();
        $units = ProductUnit::get();
        // $suppliers = Supplier::where('status', 1)->get();
        $supplierAccounts = FinanceAccount::where('account_status', 1)->where('account_group_code', '400010001')->get();
        $fromAccounts = FinanceAccount::where('account_status', 1)->where('account_group_code', 'like', '10002%')->whereNotIn('account_group_code', ['100020001'])->get();
        $stocks = Stock::with(['product', 'unit', 'supplier_finance_account'])->where('invoice_no', $invoiceNo)->get();
        $supplierFinance = FinanceTransaction::where('invoice_no', $invoiceNo)->where('acid', $stocks[0]->supplier_id)->select('voucher_no', 'voucher_date')->first();
        // $supplierPayment = FinanceTransaction::where('invoice_no', $invoiceNo)->where('acid', $stocks[0]->supplier_id)->where('balance_type', 'Dr')->select('to_acc_name', 'amount')->first();
        $supplierPayment = FinanceTransaction::where('invoice_no', $invoiceNo)->where('acid', $stocks[0]->supplier_id)->where('balance_type', 'Dr')->whereNotNull('payment_type')->where('payment_type', '!=', '')->select('to_acc_name', 'amount')->first();

        // dd($stocks);
        // dd($supplierAccounts);
        return view('pages.production.finish_product_receive.receive_invoice_edit', compact('invoiceNo', 'warehouses', 'stocks', 'products', 'units', 'supplierAccounts', 'fromAccounts', 'supplierPayment', 'supplierFinance'));
    }

    public function receiveInvoiceUpdate(Request $request, $invoiceNo)
    {
        // dd($invoiceNo);
        // dd($request->all());

        $validator = Validator::make($request->all(), [
            'stock_date' => 'required',
            // 'warehouse_id' => 'required',
            'table_product_id' => 'required',
        ]);

        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }


        $stock_date = $request->input('stock_date');
        // $warehouse_id = $request->input('warehouse_id');
        $supplierInvoiceNo = $request->input('supplier_invoice_no');
        $remarks = $request->input('remarks');
        $done_by = Auth::user()->name;
        $createdAt = $request->input('created_at');

        $purchaseNumber = $invoiceNo;

        DB::beginTransaction();
        try {
            // Delete multiple rows from the stocks table where invoice_no matches
            Stock::where('invoice_no', $invoiceNo)->delete();

            // Delete multiple rows from the finance_transactions table where invoice_no matches
            // FinanceTransaction::where('invoice_no', $invoiceNo)->delete();

            DB::commit(); // Commit the transaction if all deletions succeed
        } catch (\Exception $e) {
            DB::rollBack(); // Rollback the transaction if any error occurs
            // Log the error if needed or handle exceptions (optional)
        }

        try {
            foreach ($request->get('table_product_id') as $key => $productId) {
                $stockIn = new Stock();
                $warehouse_id = $request->input('table_warehouse_id')[$key];
                $stockQuantity = $request->input('table_product_quantity')[$key];
                $stockPrice = $request->input('table_product_price')[$key];
                $stockDiscount = $request->input('table_product_discount')[$key];
                // $stockTotal = ($stockQuantity * $stockPrice) - $stockDiscount;
                $stockTotal = $request->input('table_product_cart_amount')[$key];
                $product = Product::find($productId);
                $productName = $product ? $product->product_name : 'Unknown Product';

                // $warehouse_id = $request->input('table_warehouse_id');

                // Only update the purchase_price for the specific product if it's different
                if ($product && $stockPrice != $product->purchase_price) {
                    DB::table('products')
                        ->where('id', $product->id) // Target the specific product by ID
                        ->update(['purchase_price' => $stockPrice]);
                }

                $stockIn->warehouse_id = $warehouse_id;
                $stockIn->stock_date = $stock_date;
                $stockIn->stock_type = 'In';
                $stockIn->invoice_no = $invoiceNo;
                $stockIn->product_id = $request->input('table_product_id')[$key];
                // $stockIn->supplier_id = $supplierId;
                $stockIn->supplier_invoice_no = $supplierInvoiceNo;
                $stockIn->stock_in_quantity = $stockQuantity;
                $stockIn->stock_out_quantity = 0;
                $stockIn->stock_in_unit_price = $stockPrice;
                $stockIn->stock_in_discount = 0;
                $stockIn->stock_in_total_amount = $stockTotal;
                $stockIn->status = 1;
                $stockIn->remarks = $remarks;
                $stockIn->done_by = $done_by;
                $stockIn->created_at = $createdAt;
                $stockIn->save();
            }


            DB::commit();
        } catch (\Exception $e) {
            DB::rollback();
            return back()->withErrors(['error' => 'Ops ! Could Not add purchase history. DB transaction lost']);
        }
        return back()->with([
            'message' => 'Purchase History Added Successfully!',
            'alert-type' => 'success',
            // 'invoice' => $invoiceNo
        ]);
    }

    public function receiveInvoiceSingleRowDestroy($id)
    {

        // $stock = Stock::find($id);
        // $invoice_no = $stock->invoice_no;
        // $financeTransaction = FinanceTransaction::where('invoice_no', $invoice_no)->first();
        // dd($financeTransaction);
        // if ($stock) {
        //     $stock->delete();
        //     return back()->with([
        //         'message' => 'Successfully deleted!',
        //         'alert-type' => 'success'
        //     ]);
        // }

    }



    // public function warehouseWiseFinishProductList($warehouseId)
    // {
    //     $stockType = 'in';
    //     $products = DB::table('stocks as s')
    //         ->join('products as p', 'p.id', '=', 's.product_id')
    //         ->select('s.product_id', 'p.product_name', 'p.product_code')
    //         ->where('s.warehouse_id', $warehouseId)
    //         ->where('s.stock_type', $stockType)
    //         ->where('p.type_id',1)
    //         ->groupBy('s.product_id', 'p.product_name', 'p.product_code') 
    //         ->get();

    //     return response()->json($products);
    // }




}
