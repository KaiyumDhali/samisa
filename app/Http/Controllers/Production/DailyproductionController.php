<?php

namespace App\Http\Controllers\Production;

use App\Http\Controllers\Controller;
use App\Models\DamageProduct;
use Illuminate\Http\Request;
use App\Models\Supplier;
use App\Models\ProductType;
use App\Models\ProductCategory;
use App\Models\ProductSubCategory;
use App\Models\ProductBrand;
use App\Models\ProductSize;
use App\Models\ProductUnit;
use App\Models\DailyProduction;
use App\Models\Product;
use App\Http\Requests\ProductRequest;
use Illuminate\Support\Facades\Storage;
use Validator;
use App\Models\CustomerType;
use App\Models\CompanySetting;
use App\Models\Customer;
use App\Models\Warehouse;
use App\Models\Stock;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Date;
use Carbon\Carbon;
use Auth;
use Barryvdh\DomPDF\Facade\Pdf;
use App\Models\ProductService;
use App\Models\ProductServiceDetail;
use Illuminate\Support\Facades\View;
use App\Models\FinanceAccount;
use App\Models\FinanceTransaction;
use NumberFormatter;
use Rmunate\Utilities\SpellNumber;
use Illuminate\Pagination\LengthAwarePaginator;


class DailyProductionController extends Controller
{


    public function dailyProductionView(Request $request)
    {
        $products = Product::where('status', 1)->get();
        $startDate = $request->start_date ?? Carbon::now()->format('Y-m-d');
        $endDate = $request->end_date ?? Carbon::now()->format('Y-m-d');

        // Fetch and group production data filtered by date range
        $dailyProductions = DB::table('daily_productions')
            ->select('id', 'product_id', 'production_quantity', 'done_by', 'created_at', 'daily_production_no', 'production_date')
            ->whereBetween('production_date', [$startDate, $endDate])
            ->orderBy('id', 'desc')
            ->get();
            // ->groupBy('daily_production_no');

        // If AJAX request, return JSON response
        if ($request->ajax()) {
            return response()->json([
                'dailyProductions' => $dailyProductions,
                'products' => $products
            ]);
        }

        return view('pages.production.daily_production.daily_production', compact('products', 'startDate', 'endDate', 'dailyProductions'));
    }


    public function dailyProductionListSearch($startDate, $endDate, $productId, $pdf)
    {
        
        $dailyProductionDateWise = DB::connection()->select("CALL sp_DailyProductionDateWise(?, ?, ?)", array($startDate, $endDate, $productId));
       
        if ($pdf == "list") {
            return response()->json($dailyProductionDateWise);
        }
        if ($pdf == "pdfurl") {
            $companySetting = CompanySetting::where('status', 1)->orderBy('id', 'desc')->first();
            $data['company_name'] = $companySetting->company_name;
            $data['company_address'] = $companySetting->company_address;
            $data['company_mobile'] = $companySetting->company_mobile;
            $data['company_logo_one'] = $companySetting->company_logo_one;
            $data['start_date'] = $startDate;
            $data['end_date'] = $endDate;
            $pdf = PDF::loadView('pages.pdf.daily_production_report_date_wise_pdf', array('dailyProductionDateWise' => $dailyProductionDateWise, 'data' => $data));
            // $pdf->setPaper('A4', 'landscape');
            return $pdf->stream(Carbon::now() . '-recentstat.pdf');
        }
    }




    public function store(Request $request)
    {
        // dd($request->all());
        $validator = Validator::make($request->all(), [
            'production_date' => 'required',
            'table_product_id' => 'required',
        ]);

        if ($validator->fails()) {
            return back()->withErrors($validator)->withInput();
        }

        // get daily_production_no
        $dailyProductionNo = DB::table('invoiceno')->first('daily_production_no');
        $getDailyProductionNo = $dailyProductionNo->daily_production_no;
        $dailyProductionNo1 = 'DPN' . str_pad($getDailyProductionNo, 6, '0', STR_PAD_LEFT);
        DB::table('invoiceno')->update([
            'daily_production_no' => $getDailyProductionNo + 1,
        ]);


        foreach ($request->get('table_product_id') as $key => $product_id) {

            $dailyProduction = new DailyProduction();

            $dailyProduction->production_date = $request->input('production_date');
            $dailyProduction->daily_production_no = $dailyProductionNo1;
            $dailyProduction->product_id = $request->input('table_product_id')[$key];
            $dailyProduction->production_quantity = $request->input('table_product_quantity')[$key];
            $dailyProduction->remarks = $request->input('remarks');
            $dailyProduction->status = 1;
            $dailyProduction->is_edited = 0;
            $dailyProduction->done_by = Auth::user()->name;

            $dailyProduction->save();
        }

        return redirect()->route('daily_production_entry')->with([
            'message' => 'Production Data Added Successfully!',
            'alert-type' => 'success'
        ]);
    }
}
