<x-default-layout>
    @role('employee')
        @php
            $employeeData = \App\Models\Employee::where('user_id', auth()->user()->id)->first();
            if ($employeeData) {
                $employeeID = $employeeData->id;
                $employeeCode = $employeeData->employee_code;
                $employeeName = $employeeData->employee_name;
                $employeeBranch = $employeeData->branch_id;
                $employeePhoto = $employeeData->photo;
            } else {
                $employeeID = null;
                $employeeCode = null;
                $employeeName = null;
                $employeeBranch = null;
                $employeePhoto = null;
            }
        @endphp

        {{-- @include('pages.dashboards.employee', ['chartData' => json_encode($chartData)]) --}}
        @include('pages/dashboards/employee')
    @else

    @php
    $currentDate = now()->toDateString();

    $coustomerCount = \App\Models\Customer::where('status', 1)->get()->count();
    $supplierCount = \App\Models\Supplier::where('status', 1)->get()->count();
    $employeeCount = \App\Models\Employee::where('status', 1)->get()->count();
    $productCount = \App\Models\Product::where('status', 1)->count();
    $totalSalesCount = \App\Models\Stock::sum('stock_out_total_amount');
    $todaySalesCount = \App\Models\Stock::whereDate('stock_date', $currentDate)->sum('stock_out_total_amount');
    $totalPurchaseCount = \App\Models\Stock::sum('stock_in_total_amount');
    $todayPurchaseCount = \App\Models\Stock::whereDate('stock_date', $currentDate)->sum('stock_in_total_amount');


    $orderCount = \App\Models\ProductOrder::count();
    $orderApprovedCount = \App\Models\ProductOrder::where('status', 1)->count();
    $orderPendingCount = \App\Models\ProductOrder::where('status', 0)->count();

    // $orderList = \App\Models\Order::get();
    // $orderListCurrentDate = \App\Models\ProductOrder::with('customer')->withSum('orderdetail', 'stock_out_total_amount')->whereDate('order_date', $currentDate)->orderBy('id', 'desc')->get();

    // $todayTotalSum = 0;
    // foreach ($orderListCurrentDate as $productOrder) {
    //     $todayTotalSum += $productOrder->orderdetail_sum_stock_out_total_amount;
    // }
    // $todayTotalSum;
    // $orderList = \App\Models\ProductOrder::with('customer')->withSum('orderdetail', 'stock_out_total_amount')->orderBy('id', 'desc')->limit(5)->get();    
    @endphp


    @section('title')
    Dashboard
    @endsection

    {{-- @section('breadcrumbs')
        {{ Breadcrumbs::render('dashboard') }}
    @endsection --}}
    
    <!--begin::Row-->
    <div class="row g-5 g-xl-10 mb-5 mb-xl-10">
        <!--begin::Col-->
        <div class="col-md-6 col-lg-6 col-xl-6 col-xxl-3 mb-md-5 mb-xl-10">
            @include('partials/widgets/cards/logo')
            @include('partials/widgets/cards/total_customer')
        </div>
        <!--end::Col-->
        <!--begin::Col-->
        <div class="col-md-6 col-lg-6 col-xl-6 col-xxl-3 mb-md-5 mb-xl-10">
            @include('partials/widgets/cards/total_products')
            @include('partials/widgets/cards/total_supplier')
        </div>
        <!--end::Col-->
        
        <!--begin::Col-->
        <div class="col-md-6 col-lg-6 col-xl-6 col-xxl-3 mb-md-5 mb-xl-10">
            @include('partials/widgets/cards/today_sales')
            @include('partials/widgets/cards/total_sales')
        </div>
        <!--end::Col-->
        <!--begin::Col-->
        <div class="col-md-6 col-lg-6 col-xl-6 col-xxl-3 mb-md-5 mb-xl-10">
            @include('partials/widgets/cards/today_purchase')
            @include('partials/widgets/cards/total_purchase')
        </div>
        <!--end::Col-->
        <!--begin::Col-->
        <div class="col-xxl-6">
            @include('partials/widgets/charts/product_sales_this_month')
        </div>
        <div class="col-xxl-6">
            @include('partials/widgets/charts/_widget-36')
            {{-- @include('partials/widgets/charts/pie_chart_all_employee_report') --}}
            {{-- @include('partials/widgets/charts/product_sales') --}}
        </div>
        <!--end::Col-->
    </div>
    <!--end::Row-->

    <!--begin::Row-->
    <div class="row g-5 g-xl-10 mb-5 mb-xl-10">
        <!--begin::Col-->
        <div class="col-xl-12">
            @include('partials/widgets/tables/product_stock_finish_good')
        </div>
        <div class="col-xl-12">
            {{-- @include('partials/widgets/tables/attendance_report') --}}
            {{-- @include('partials/widgets/tables/product_order_list') --}}
            {{-- @include('partials/widgets/tables/_widget-14') --}}
        </div>
        <!--end::Col-->
    </div>
    <!--end::Row-->

    @endrole
    
    
    @push('scripts')
    <script>
        am5.ready(function () {

            // Create root element
            // https://www.amcharts.com/docs/v5/getting-started/#Root_element
            var root = am5.Root.new("kt_amcharts_1");

            // Set themes
            // https://www.amcharts.com/docs/v5/concepts/themes/
            root.setThemes([
                am5themes_Animated.new(root)
            ]);

            // Create chart
            // https://www.amcharts.com/docs/v5/charts/xy-chart/
            var chart = root.container.children.push(am5xy.XYChart.new(root, {
                panX: false,
                panY: false,
                wheelX: "panX",
                wheelY: "zoomX",
                layout: root.verticalLayout
            }));

            // Add legend
            // https://www.amcharts.com/docs/v5/charts/xy-chart/legend-xy-series/
            var legend = chart.children.push(
                am5.Legend.new(root, {
                    centerX: am5.p50,
                    x: am5.p50
                })
            );

            var data = [...]

            // Create axes
            // https://www.amcharts.com/docs/v5/charts/xy-chart/axes/
            var xAxis = chart.xAxes.push(am5xy.CategoryAxis.new(root, {
                categoryField: "year",
                renderer: am5xy.AxisRendererX.new(root, {
                    cellStartLocation: 0.1,
                    cellEndLocation: 0.9
                }),
                tooltip: am5.Tooltip.new(root, {})
            }));

            xAxis.data.setAll(data);

            var yAxis = chart.yAxes.push(am5xy.ValueAxis.new(root, {
                renderer: am5xy.AxisRendererY.new(root, {})
            }));

            // Add series
            // https://www.amcharts.com/docs/v5/charts/xy-chart/series/
            function makeSeries(name, fieldName) {
                var series = chart.series.push(am5xy.ColumnSeries.new(root, {
                    name: name,
                    xAxis: xAxis,
                    yAxis: yAxis,
                    valueYField: fieldName,
                    categoryXField: "year"
                }));

                series.columns.template.setAll({
                    tooltipText: "{name}, {categoryX}:{valueY}",
                    width: am5.percent(90),
                    tooltipY: 0
                });

                series.data.setAll(data);

                // Make stuff animate on load
                // https://www.amcharts.com/docs/v5/concepts/animations/
                series.appear();

                series.bullets.push(function () {
                    return am5.Bullet.new(root, {
                        locationY: 0,
                        sprite: am5.Label.new(root, {
                            text: "{valueY}",
                            fill: root.interfaceColors.get("alternativeText"),
                            centerY: 0,
                            centerX: am5.p50,
                            populateText: true
                        })
                    });
                });

                legend.data.push(series);
            }

            makeSeries("Europe", "europe");
            makeSeries("North America", "namerica");
            makeSeries("Asia", "asia");
            makeSeries("Latin America", "lamerica");
            makeSeries("Middle East", "meast");
            makeSeries("Africa", "africa");


            // Make stuff animate on load
            // https://www.amcharts.com/docs/v5/concepts/animations/
            chart.appear(1000, 100);

        }); // end am5.ready()
    </script>
@endpush 
    
</x-default-layout>



