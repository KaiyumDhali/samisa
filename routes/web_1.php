<?php

use App\Http\Controllers\Apps\PermissionManagementController;
use App\Http\Controllers\Apps\RoleManagementController;
use App\Http\Controllers\Apps\UserManagementController;
use App\Http\Controllers\Auth\SocialiteController;
use App\Http\Controllers\DashboardController;
use Illuminate\Support\Facades\Route;
//Purchase
use App\Http\Controllers\Product\PurchaseController;
//Sales
use App\Http\Controllers\Product\SalesController;
// Product
use App\Http\Controllers\Product\ProductOrderController;
use App\Http\Controllers\Product\StockController;
use App\Http\Controllers\Product\ProductController;
use App\Http\Controllers\Product\ProductSettingsController;
use App\Http\Controllers\Production\ProductionBillOfMatrialController;
use App\Http\Controllers\Production\FinalProductionController;
use App\Http\Controllers\Product\CategoryController;
use App\Http\Controllers\Product\SubCategoryController;
use App\Http\Controllers\Product\BrandController;
use App\Http\Controllers\Product\ColorController;
use App\Http\Controllers\Product\SizeController;
use App\Http\Controllers\Product\UnitController;
// Supplier
use App\Http\Controllers\Supplier\SupplierController;
use App\Http\Controllers\Supplier\SupplierLedgerController;
// Customer
use App\Http\Controllers\Customer\CustomerController;
use App\Http\Controllers\Customer\CustomerLedgerController;
// Employee
use App\Http\Controllers\Employee\EmpBranchController;
use App\Http\Controllers\Employee\EmpDepartmentController;
use App\Http\Controllers\Employee\EmpDesignationController;
use App\Http\Controllers\Employee\EmployeeController;
use App\Http\Controllers\Employee\EmployeeEducationController;
use App\Http\Controllers\Employee\EmployeeJobHistoryController;
use App\Http\Controllers\Employee\EmployeeLedgerController;
// Employee Leave
use App\Http\Controllers\Employee\leaveReportController;
use App\Http\Controllers\Employee\EmployeeLeaveSettingsController;
use App\Http\Controllers\Employee\EmployeeLeaveEntryController;
use App\Http\Controllers\Employee\EmployeeLeaveApproveDeptController;
use App\Http\Controllers\Employee\EmployeeLeaveApproveHrController;
use App\Http\Controllers\Employee\EmployeeLeaveApproveManagController;
use App\Http\Controllers\Employee\EmployeeDelayinEarlyoutController;
// Performance
use App\Http\Controllers\Employee\PerformanceTypeController;
use App\Http\Controllers\Employee\EmployeePerformanceController;
// Payroll
use App\Http\Controllers\Payroll\EmployeeSalaryController;
use App\Http\Controllers\Payroll\PayslipTypeController;
use App\Http\Controllers\Payroll\AllowanceOptionController;
use App\Http\Controllers\Payroll\AllowanceController;
use App\Http\Controllers\Payroll\CommissionController;
use App\Http\Controllers\Payroll\LoanOptionController;
use App\Http\Controllers\Payroll\LoanController;
use App\Http\Controllers\Payroll\OtherPaymentController;
use App\Http\Controllers\Payroll\OvertimeController;
use App\Http\Controllers\Payroll\SetSalaryController;
use App\Http\Controllers\Payroll\PayslipController;
//HR Admin Setup
use App\Http\Controllers\Hradmin\AttendanceController;
use App\Http\Controllers\Hradmin\PromotionController;
use App\Http\Controllers\Hradmin\ResignationController;
use App\Http\Controllers\Hradmin\TerminationController;
use App\Http\Controllers\Hradmin\AnnouncementController;
use App\Http\Controllers\Hradmin\HolidayController;
use App\Http\Controllers\Hradmin\MeetingController;
use App\Http\Controllers\DownloadDB\DownloaddbController;

/*
  |--------------------------------------------------------------------------
  | Web Routes
  |--------------------------------------------------------------------------
  |
  | Here is where you can register web routes for your application. These
  | routes are loaded by the RouteServiceProvider within a group which
  | contains the "web" middleware group. Now create something great!
  |
 */

Route::middleware(['auth', 'verified'])->group(function () {

    Route::get('/', [DashboardController::class, 'index']);

    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    Route::name('user-management.')->group(function () {
        Route::resource('/user-management/users', UserManagementController::class);
        Route::resource('/user-management/roles', RoleManagementController::class);
        Route::resource('/user-management/permissions', PermissionManagementController::class);
    });

    // product pages
    Route::prefix('product')->group(function () {

        Route::get('productDetails/{id}', [StockController::class, 'productDetails']);

        Route::resource('sales', SalesController::class);
        Route::get('customerDetails/{id}', [SalesController::class, 'customerDetails']);
        Route::get('sales_report', [SalesController::class, 'sales_report'])->name('sales_report');
        Route::get('sales_date_search/{startDate}/{endDate}', [SalesController::class, 'salesDateSearch'])->name('sales_date_search');
        Route::post('sales_search', [SalesController::class, 'salesSearch'])->name('sales_search');

        Route::resource('purchase', PurchaseController::class);
        Route::get('supplierDetails/{id}', [PurchaseController::class, 'supplierDetails']);
        Route::get('purchase_report', [PurchaseController::class, 'purchase_report'])->name('purchase_report');
        Route::get('purchase_date_search/{startDate}/{endDate}', [PurchaseController::class, 'purchaseDateSearch'])->name('purchase_date_search');
        Route::post('purchase_search', [PurchaseController::class, 'purchaseSearch'])->name('purchase_search');

        Route::get('stock_report', [StockController::class, 'stock'])->name('stock_report');

        Route::resource('product_order', ProductOrderController::class);
        Route::get('product_order_image_destroy/{id}', [ProductOrderController::class, 'imageDestroy'])->name('product_order.image_destroy');
        Route::get('allColor', [ProductOrderController::class, 'allColor'])->name('allColor');
        Route::get('/get-colors', 'ProductOrderController@allColor');

        Route::resource('products', ProductController::class);
        Route::get('category', [CategoryController::class, 'index'])->name('categories.index');
        Route::get('category_create', [CategoryController::class, 'create'])->name('category_create.create');
        Route::post('categories_store', [CategoryController::class, 'store'])->name('categories_store.store');
        Route::get('category_edit/{id}', [CategoryController::class, 'edit'])->name('category_edit.edit');
        Route::POST('category_update/{id}', [CategoryController::class, 'update'])->name('category_update.update');
        Route::get('category_delete/{id}', [CategoryController::class, 'destroy'])->name('category_delete.destroy');

        Route::resource('sub_category', SubCategoryController::class);
        Route::resource('brands', BrandController::class);
        Route::resource('colors', ColorController::class);
        Route::resource('sizes', SizeController::class);
        Route::resource('units', UnitController::class);
    });

    // Production
    Route::prefix('production')->group(function () {
        Route::resource('billofmaterials', ProductionBillOfMatrialController::class);
        Route::get('billofmaterials/productDetails/{id}', [ProductionBillOfMatrialController::class, 'productDetails']);
        Route::get('billofmaterials/productionDetails/{id}', [FinalProductionController::class, 'productionDetails']);
        Route::get('productDetails/{id}', [ProductionBillOfMatrialController::class, 'productDetails'])->name('productDetails');
        Route::get('productDetailsDestroy/{id}', [ProductionBillOfMatrialController::class, 'fileDestroy'])->name('productDetailsDestroy.file_destroy');

        Route::resource('finalproductions', FinalProductionController::class);
        Route::get('productionDetails/{id}', [FinalProductionController::class, 'productionDetails']);

        Route::get('finalproduction_report', [FinalProductionController::class, 'finalProductionReport'])->name('production.finalproduction_report');
        Route::get('invoice_date_search/{startDate}/{endDate}', [FinalProductionController::class, 'invoiceDateSearch'])->name('invoice_date_search');
        Route::post('finalproduction_report_search', [FinalProductionController::class, 'finalProductionReportSearch'])->name('finalproduction_report_search');
    });

    // supplier pages
    Route::prefix('supplier')->group(function () {
        Route::resource('suppliers', SupplierController::class);
        Route::resource('supplier_ledgers', SupplierLedgerController::class);
        Route::get('supplierDetails/{id}', [SupplierLedgerController::class, 'supplierDetails'])->name('supplierDetails');
    });

    // customer pages
    Route::prefix('customer')->group(function () {
        Route::resource('customers', CustomerController::class);
        Route::resource('customer_ledgers', CustomerLedgerController::class);
        Route::get('customerDetails/{id}', [CustomerLedgerController::class, 'customerDetails'])->name('customerDetails');
    });

    // employee pages
    Route::prefix('employee')->group(function () {

        // Single Profile
        Route::get('employeeProfile', [EmployeeController::class, 'employeeProfile'])->name('employee_profile');
        Route::get('employeeProfileLedger', [EmployeeLedgerController::class, 'employeeProfileLedger'])->name('employee_profile_ledger');
        Route::get('employee_profile_leave_entry', [EmployeeLeaveEntryController::class, 'employeeProfileLeaveEntry'])->name('employee_profile_leave_entry');

        Route::resource('emp_branch', EmpBranchController::class);
        Route::resource('emp_department', EmpDepartmentController::class);
        Route::resource('emp_designation', EmpDesignationController::class);

        Route::resource('employees', EmployeeController::class);
        Route::get('branchEmployees/{id}', [EmployeeController::class, 'branchEmployees'])->name('branchEmployees');
        Route::get('branchDepartment/{id}', [EmployeeController::class, 'branchDepartment'])->name('branchDepartment');

        Route::get('employeeDetails/{id}', [EmployeeLedgerController::class, 'employeeDetails'])->name('employeeDetails');
        Route::resource('employee_ledger', EmployeeLedgerController::class);
        Route::get('employee_ledger_search/{startDate}/{endDate}/{employeeID}/{pdf}', [EmployeeLedgerController::class, 'employeeLedgerSearch'])->name('employee_ledger_search');

        Route::resource('employee_education', EmployeeEducationController::class);
        Route::resource('employee_job_history', EmployeeJobHistoryController::class);

        // employee leave
        Route::resource('employee_leave_setting', EmployeeLeaveSettingsController::class);
        Route::get('allEmployeeLeaveSetting', [EmployeeLeaveSettingsController::class, 'allEmployeeLeaveSetting'])->name('allEmployeeLeaveSetting');
        Route::get('employeeLeaveDetails/{id}', [EmployeeLeaveSettingsController::class, 'employeeLeaveDetails'])->name('employeeLeaveDetails');
        Route::get('branchDetails/{id}', [EmployeeLeaveSettingsController::class, 'branchDetails'])->name('branchDetails');
        Route::get('departmentEmployee/{id}', [EmployeeLeaveSettingsController::class, 'departmentEmployee'])->name('departmentEmployee');
        Route::get('departmentDetails/{id}', [EmployeeLeaveSettingsController::class, 'departmentDetails'])->name('departmentDetails');
        // Route::post('update_leave_settings/{editLeaveID}', [EmployeeLeaveSettingsController::class, 'updateLeaveSettings'])->name('update_leave_settings');
        Route::put('update_leave_settings/{editLeaveID}', [EmployeeLeaveSettingsController::class, 'updateLeaveSettings'])->name('update_leave_settings');

        Route::resource('employee_leave_entry', EmployeeLeaveEntryController::class);
        Route::get('employeeLeaveEntryDetails/{id}', [EmployeeLeaveEntryController::class, 'employeeLeaveEntryDetails'])->name('employeeLeaveEntryDetails');
        Route::get('leaveEntryBranchDetails/{id}', [EmployeeLeaveEntryController::class, 'leaveEntryBranchDetails'])->name('leaveEntryBranchDetails');

        Route::resource('leave_report', leaveReportController::class);
        Route::get('leave_report_search/{year}/{month}/{pdf}', [leaveReportController::class, 'leaveReport'])->name('leave_report_search');

        Route::resource('employee_leave_approve_dept', EmployeeLeaveApproveDeptController::class);
        Route::get('employee_leave_approve_dept_list', [EmployeeLeaveApproveDeptController::class, 'approvedIndex'])->name('employee_leave_approve_dept_list');

        Route::resource('employee_leave_approve_hr', EmployeeLeaveApproveHrController::class);
        Route::get('employee_leave_approve_hr_list', [EmployeeLeaveApproveHrController::class, 'approvedIndex'])->name('employee_leave_approve_hr_list');

        Route::resource('employee_leave_approve_manag', EmployeeLeaveApproveManagController::class);
        Route::get('employee_leave_approve_manag_list', [EmployeeLeaveApproveManagController::class, 'approvedIndex'])->name('employee_leave_approve_manag_list');

        Route::resource('emp_delayin_earlyout', EmployeeDelayinEarlyoutController::class);

        // performance
        Route::resource('performance_type', PerformanceTypeController::class);
        Route::resource('employee_performance', EmployeePerformanceController::class);
        Route::get('employeePerformanceBranchDetails/{id}', [EmployeePerformanceController::class, 'employeePerformanceBranchDetails'])->name('employeePerformanceBranchDetails');
        Route::get('employeePerformancType/{id}', [EmployeePerformanceController::class, 'employeePerformancType'])->name('employeePerformancType');
    });

    // hr admin pages
    Route::prefix('hradmin')->group(function () {
        Route::resource('attendance', AttendanceController::class);

        Route::get('daily_attendance_search/{branchID}/{employeeID}/{startDate}/{endDate}/{pdf}', [AttendanceController::class, 'dailyAttendanceSearch'])->name('daily_attendance_search');
        Route::get('branch_wais_employee/{branchID}', [AttendanceController::class, 'branchWaisEmployee'])->name('branch_wais_employee');

        Route::get('daily_all_attendance', [AttendanceController::class, 'dailyAllAttendance'])->name('daily_all_attendance');
        Route::get('single_employee_attendance_search/{employeeID}', [AttendanceController::class, 'singleEmployeeAttendanceSearch'])->name('single_employee_attendance_search');
        Route::get('single_employee_all_attendance_search', [AttendanceController::class, 'singleEmployeeAllAttendanceSearch'])->name('single_employee_all_attendance_search');

        Route::resource('promotion', PromotionController::class);
        Route::resource('resignation', ResignationController::class);
        Route::resource('termination', TerminationController::class);
        Route::resource('announcement', AnnouncementController::class);
        Route::get('single_employee_promotion/{employeeID}', [PromotionController::class, 'singleEmployeePromotion'])->name('single_employee_promotion');

        Route::get('single_employee_Announcement/{employeeID}', [AnnouncementController::class, 'single_employee_Announcement'])->name('single_employee_Announcement');

        Route::get('downloadAnnouncement/{file_path}', [AnnouncementController::class, 'downloadAnnouncement'])->name('downloadAnnouncement');

        Route::get('allEmpBranch', [AnnouncementController::class, 'allEmpBranch'])->name('allEmpBranch');
        Route::get('allEmpDepartment/{branchName}', [AnnouncementController::class, 'allEmpDepartment'])->name('allEmpDepartment');
        Route::get('allEmpDesignation', [AnnouncementController::class, 'allEmpDesignation'])->name('allEmpDesignation');
        Route::get('allEmployee', [AnnouncementController::class, 'allEmployee'])->name('allEmployee');
        Route::resource('holiday', HolidayController::class);
        Route::resource('meeting', MeetingController::class);
    });

    // download database
    Route::prefix('dbbackup')->group(function () {
        Route::resource('dbbackups', DownloaddbController::class);
        Route::get('download_db', [DownloaddbController::class, 'download_db'])->name('downloaddb.download_db');
        Route::get('downloadFile/{file_name}', [DownloaddbController::class, 'downloadFile'])->name('downloadFile');
        Route::get('db_destroy/{name}', [DownloaddbController::class, 'dbDestroy'])->name('db_destroy');
    });

    // payroll pages
    Route::prefix('payroll')->group(function () {
        Route::resource('payslip_type', PayslipTypeController::class);
        Route::resource('allowance_option', AllowanceOptionController::class);
        Route::resource('loan_option', LoanOptionController::class);

        Route::resource('employee_salaries', EmployeeSalaryController::class);
        Route::resource('allowance', AllowanceController::class);
        Route::resource('commission', CommissionController::class);
        Route::resource('loan', LoanController::class);
        Route::resource('other_payment', OtherPaymentController::class);
        Route::resource('overtime', OvertimeController::class);

        Route::resource('set_salaries', SetSalaryController::class);
        Route::get('set_salaries_create/{id}', [SetSalaryController::class, 'setSalariesCreate'])->name('set_salaries.set_salaries_create');
        Route::resource('payslips', PayslipController::class);
        Route::get('/get-payslip/{employeeId}', [PayslipController::class, 'getPayslipData']);
        Route::get('/get-all-payslip/{employeeId}', [PayslipController::class, 'getAllPayslipData']);
    });
});

Route::get('/error', function () {
    abort(500);
});

Route::get('/auth/redirect/{provider}', [SocialiteController::class, 'redirect']);

require __DIR__ . '/auth.php';
