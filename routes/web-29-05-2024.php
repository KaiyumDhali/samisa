<?php

use App\Http\Controllers\Apps\PermissionManagementController;
use App\Http\Controllers\Apps\RoleManagementController;
use App\Http\Controllers\Apps\UserManagementController;
use App\Http\Controllers\Auth\SocialiteController;
use App\Http\Controllers\DashboardController;
use Illuminate\Support\Facades\Route;

// Product order
use App\Http\Controllers\Production\CostSheetController;
use App\Http\Controllers\Production\ProductOrderController;

use App\Http\Controllers\Production\ProductionBillOfMatrialController;
use App\Http\Controllers\Production\FinalProductionController;

use App\Http\Controllers\Production\RequisitionController;
//Purchase
use App\Http\Controllers\Product\PurchaseController;
//Sales
use App\Http\Controllers\Product\SalesController;
// Product
use App\Http\Controllers\Product\StockController;
use App\Http\Controllers\Product\ProductController;
use App\Http\Controllers\Product\ProductSettingsController;
use App\Http\Controllers\Product\ProductTypeController;
use App\Http\Controllers\Product\ProductFragranceController;
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
use App\Http\Controllers\Customer\CustomerTypeController;
use App\Http\Controllers\Customer\CustomerLedgerController;
// Employee
use App\Http\Controllers\Employee\EmpTypeController;
use App\Http\Controllers\Employee\EmpSectionController;
use App\Http\Controllers\Employee\EmpLineController;
use App\Http\Controllers\Employee\EmpGradeController;
use App\Http\Controllers\Employee\EmpSalarySectionController;
use App\Http\Controllers\Employee\EmpQuiteTypeController;

use App\Http\Controllers\Employee\CompanySettingController;
use App\Http\Controllers\Employee\EmpBranchController;
use App\Http\Controllers\Employee\EmpDepartmentController;
use App\Http\Controllers\Employee\EmpDesignationController;
use App\Http\Controllers\Employee\EmployeeController;
use App\Http\Controllers\Employee\EmployeeEducationController;
use App\Http\Controllers\Employee\EmployeeJobHistoryController;
use App\Http\Controllers\Employee\EmployeeJobResponsibilityController;
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
use App\Http\Controllers\Payroll\PayrollHeadController;
use App\Http\Controllers\Payroll\PayrollFormulaController;
use App\Http\Controllers\Payroll\PayrollController;

use App\Http\Controllers\Payroll\EmployeeSalaryController;
use App\Http\Controllers\Payroll\PayslipTypeController;
use App\Http\Controllers\Payroll\IncomeHeadController;
use App\Http\Controllers\Payroll\IncomeController;

use App\Http\Controllers\Payroll\DeductionController;
use App\Http\Controllers\Payroll\DeductionHeadController;

use App\Http\Controllers\Payroll\AllowanceOptionController;
use App\Http\Controllers\Payroll\AllowanceController;
use App\Http\Controllers\Payroll\CommissionController;
use App\Http\Controllers\Payroll\LoanOptionController;
use App\Http\Controllers\Payroll\LoanController;
use App\Http\Controllers\Payroll\OtherPaymentController;
use App\Http\Controllers\Payroll\OvertimeController;
use App\Http\Controllers\Payroll\SetSalaryController;
use App\Http\Controllers\Payroll\MonthlySalaryController;
use App\Http\Controllers\Payroll\PayslipController;
//HR Admin Setup
use App\Http\Controllers\Hradmin\WorkTimeController;
use App\Http\Controllers\Hradmin\BreakTimeController;
use App\Http\Controllers\Hradmin\LateTimeController;
use App\Http\Controllers\Hradmin\WeekendDayController;
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
    Route::get('/ceo/notifications', [CEOController::class, 'getNotifications'])->name('ceo.notifications');

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
        
        Route::get('sales_search_pdf/{data}', [SalesController::class, 'salesSearchPdf'])->name('sales_search_pdf');

        Route::resource('purchase', PurchaseController::class);
        Route::get('supplierDetails/{id}', [PurchaseController::class, 'supplierDetails']);
        Route::get('purchase_report', [PurchaseController::class, 'purchase_report'])->name('purchase_report');
        Route::get('purchase_date_search/{startDate}/{endDate}', [PurchaseController::class, 'purchaseDateSearch'])->name('purchase_date_search');
        Route::post('purchase_search', [PurchaseController::class, 'purchaseSearch'])->name('purchase_search');
        
        Route::get('purchase_search_pdf/{data}', [PurchaseController::class, 'purchaseSearchPdf'])->name('purchase_search_pdf');
        Route::get('stock_report', [StockController::class, 'stock'])->name('stock_report');
        Route::get('stock_report_pdf', [StockController::class, 'stock_pdf'])->name('stock_report_pdf');

        Route::resource('cost_sheet', CostSheetController::class);
        Route::resource('product_order', ProductOrderController::class);
        Route::get('product_order_image_destroy/{id}', [ProductOrderController::class, 'imageDestroy'])->name('product_order.image_destroy');
        Route::get('allColor', [ProductOrderController::class, 'allColor'])->name('allColor');
        Route::get('/get-colors', 'ProductOrderController@allColor');

        Route::resource('products', ProductController::class);
        Route::resource('product_type', ProductTypeController::class);
        Route::resource('product_fragrance', ProductFragranceController::class);

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
        Route::get('billofmaterials/productDetails/{id}', [ProductionBillOfMatrialController::class, 'billOfMatrialProductDetails']);
        // Route::get('billofmaterials/productionDetails/{id}', [FinalProductionController::class, 'productionDetails']);
        Route::get('billofmaterials_pdf/{id}', [ProductionBillOfMatrialController::class, 'billOfMaterialsPdf'])->name('billofmaterials_pdf');

        Route::get('billOfMatrialProductDetails/{id}', [ProductionBillOfMatrialController::class, 'billOfMatrialProductDetails'])->name('billOfMatrialProductDetails');
        Route::get('productDetailsDestroy/{id}', [ProductionBillOfMatrialController::class, 'fileDestroy'])->name('productDetailsDestroy.file_destroy');

        Route::resource('finalproductions', FinalProductionController::class);
        Route::get('productionDetails/{id}', [FinalProductionController::class, 'productionDetails']);

        Route::get('finalproduction_report', [FinalProductionController::class, 'finalProductionReport'])->name('production.finalproduction_report');
        Route::get('invoice_date_search/{startDate}/{endDate}', [FinalProductionController::class, 'invoiceDateSearch'])->name('invoice_date_search');
        
        Route::post('finalproduction_report_search', [FinalProductionController::class, 'finalProductionReportSearch'])->name('finalproduction_report_search');
        
        Route::get('finalproduction_report_search_pdf/{data}', [FinalProductionController::class, 'finalProductionReportSearchPdf'])->name('finalproduction_report_search_pdf');
        
        // RequisitionController
        Route::resource('requisitions', RequisitionController::class);
        Route::get('requisitionDetails/{invoiceNo}', [RequisitionController::class, 'requisitionDetails'])->name('requisitionDetails');
        Route::post('additional_requisition_store', [RequisitionController::class, 'additionalRequisitionStore'])->name('additional_requisition_store');

        Route::get('requisition_list', [RequisitionController::class, 'requisitionList'])->name('production.requisition_list');
        Route::get('requisition_invoice_date_search/{startDate}/{endDate}', [RequisitionController::class, 'invoiceDateSearch'])->name('requisition_invoice_date_search');
        
        Route::get('requisition_approved_list', [RequisitionController::class, 'requisitionApprovedList'])->name('production.requisition_approved_list');
        Route::get('requisition_invoice_approved_date_search/{startDate}/{endDate}', [RequisitionController::class, 'invoiceApprovedDateSearch'])->name('requisition_invoice_approved_date_search');

        Route::get('requisition_invoice_report_search/{invoiceNo}', [RequisitionController::class, 'requisitionInvoiceReportSearch'])->name('requisition_invoice_report_search');
        Route::get('requisition_invoice_report_status_approved/{invoiceNo}/{statusValueApproved}', [RequisitionController::class, 'requisitionInvoiceReportStatusApproved'])->name('requisition_invoice_report_status_approved');
        
        Route::get('requisition_invoice_report_pdf/{data}', [RequisitionController::class, 'requisitionInvoiceReportPdf'])->name('requisition_invoice_report_pdf'); 
        
        // additionalRequisitionAdd
        Route::get('additional_requisition_add', [RequisitionController::class, 'additionalRequisitionAdd'])->name('additional_requisition_add');

    });

    // supplier pages
    Route::prefix('supplier')->group(function () {
        Route::resource('suppliers', SupplierController::class);
        Route::resource('supplier_ledgers', SupplierLedgerController::class);
        Route::get('supplierDetails/{id}', [SupplierLedgerController::class, 'supplierDetails'])->name('supplierDetails');
        Route::get('supplier_ledger_search/{startDate}/{endDate}/{supplierID}/{pdf}', [SupplierLedgerController::class, 'supplierLedgerSearch'])->name('supplier_ledger_search');

    });

    // customer pages
    Route::prefix('customer')->group(function () {
        Route::resource('customers', CustomerController::class);
        Route::resource('customer_type', CustomerTypeController::class);
        Route::resource('customer_ledgers', CustomerLedgerController::class);
        Route::get('customerDetails/{id}', [CustomerLedgerController::class, 'customerDetails'])->name('customerDetails');
        Route::get('customer_ledger_search/{startDate}/{endDate}/{customerID}/{pdf}', [CustomerLedgerController::class, 'customerLedgerSearch'])->name('customer_ledger_search');

    });

    // employee pages
    Route::prefix('employee')->group(function () {

        Route::resource('emp_company', CompanySettingController::class);
        Route::resource('emp_branch', EmpBranchController::class);
        Route::resource('emp_department', EmpDepartmentController::class);
        Route::resource('emp_designation', EmpDesignationController::class);

        Route::resource('employee_type', EmpTypeController::class);
        Route::resource('emp_section', EmpSectionController::class);
        Route::resource('emp_line', EmpLineController::class);
        Route::resource('emp_grade', EmpGradeController::class);
        Route::resource('emp_salary_section', EmpSalarySectionController::class);
        Route::resource('emp_quite_type', EmpQuiteTypeController::class);

        // Single Employee Profile
        Route::get('employeeProfile', [EmployeeController::class, 'employeeProfile'])->name('employee_profile');
        Route::get('employeeProfileLedger', [EmployeeLedgerController::class, 'employeeProfileLedger'])->name('employee_profile_ledger');
        Route::get('employee_profile_leave_entry', [EmployeeLeaveEntryController::class, 'employeeProfileLeaveEntry'])->name('employee_profile_leave_entry');

        // Admin Employee Profile
        Route::resource('employees', EmployeeController::class);
        Route::get('employees_search/{employeeCode}/{typeId}/{departmentId}/{sectionId}/{lineId}/{designationId}/{salarySectionId}/{pdf}', [EmployeeController::class, 'employeesSearch'])->name('employees_search');
        Route::resource('employee_education', EmployeeEducationController::class);
        Route::resource('employee_job_history', EmployeeJobHistoryController::class);
        Route::resource('employee_job_responsibility', EmployeeJobResponsibilityController::class);

        Route::get('branchEmployees/{id}', [EmployeeController::class, 'branchEmployees'])->name('branchEmployees');
        Route::get('branchDepartment/{id}', [EmployeeController::class, 'branchDepartment'])->name('branchDepartment');

        // Employee ledger
        Route::get('employeeDetails/{id}', [EmployeeLedgerController::class, 'employeeDetails'])->name('employeeDetails');
        Route::resource('employee_ledger', EmployeeLedgerController::class);
        Route::get('employee_ledger_search/{startDate}/{endDate}/{employeeID}/{pdf}', [EmployeeLedgerController::class, 'employeeLedgerSearch'])->name('employee_ledger_search');

        // Employee leave settings
        Route::resource('employee_leave_setting', EmployeeLeaveSettingsController::class);
        Route::get('allEmployeeLeaveSetting', [EmployeeLeaveSettingsController::class, 'allEmployeeLeaveSetting'])->name('allEmployeeLeaveSetting');
        Route::get('sectionWaiseSingleEmployee/{id}', [EmployeeLeaveSettingsController::class, 'sectionWaiseSingleEmployee'])->name('sectionWaiseSingleEmployee');
        Route::get('sectionDetails/{id}', [EmployeeLeaveSettingsController::class, 'sectionDetails'])->name('sectionDetails');
        Route::put('update_leave_settings/{editLeaveID}', [EmployeeLeaveSettingsController::class, 'updateLeaveSettings'])->name('update_leave_settings');

        Route::get('branchDetails/{id}', [EmployeeLeaveSettingsController::class, 'branchDetails'])->name('branchDetails');
        Route::get('employeeLeaveDetails/{id}', [EmployeeLeaveSettingsController::class, 'employeeLeaveDetails'])->name('employeeLeaveDetails');
        
        // Employee leave entry 
        Route::resource('employee_leave_entry', EmployeeLeaveEntryController::class);
        // Select Section show leave entry list and select employee list
        Route::get('leaveEntrySectionWiseEmployeeDetails/{id}', [EmployeeLeaveEntryController::class, 'leaveEntrySectionWiseEmployeeDetails'])->name('leaveEntrySectionWiseEmployeeDetails');
        // Select Employee show leave entry list 
        Route::get('employeeLeaveEntryDetails/{id}', [EmployeeLeaveEntryController::class, 'employeeLeaveEntryDetails'])->name('employeeLeaveEntryDetails');
        
        // Employee leave entry list
        Route::get('employee_leave_entry_list', [EmployeeLeaveEntryController::class, 'employeeLeaveEntryList'])->name('employee_leave_entry_list');
        // Employee leave entry list search
        Route::get('employee_leave_entry_list_search/{sectionID}/{employeeID}/{startDate}/{endDate}/{pdf}', [EmployeeLeaveEntryController::class, 'leaveEntryListSearch'])->name('employee_leave_entry_list_search');
        // Section wise employee list search
        Route::get('sectionWaisEmployee/{sectionID}', [EmployeeLeaveEntryController::class, 'sectionWaisEmployee'])->name('sectionWaisEmployee');
        // Employee leave entry list delete
        Route::delete('employee_leave_entry_list_destroy/{id}', [EmployeeLeaveEntryController::class, 'employeeLeaveEntryListDestroy'])->name('employee_leave_entry_list_destroy');
        
        // Final Leave Report
        Route::resource('leave_report', leaveReportController::class);
        Route::get('leave_report_search/{year}/{month}/{pdf}', [leaveReportController::class, 'leaveReport'])->name('leave_report_search');

        // Late of Leave Manage
        Route::get('late_of_leave', [leaveReportController::class, 'lateOFLeave'])->name('late_of_leave');
        Route::get('late_of_leave_report_search/{year}/{month}/{pdf}', [leaveReportController::class, 'lateOFLeaveReport'])->name('late_of_leave_report_search');
        Route::post('late_of_leave_add', [leaveReportController::class, 'addLateOFLeave'])->name('late_of_leave_add');

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
        // time table 
        Route::resource('work_time', WorkTimeController::class);
        Route::resource('late_time', LateTimeController::class);
        Route::resource('break_time', BreakTimeController::class);
        Route::resource('weekend_day', WeekendDayController::class);

        // manual  attendance input
        Route::get('manual_attendance_input', [AttendanceController::class, 'manualAttendanceInput'])->name('manual_attendance_input');
        Route::post('add_selected_employee', [AttendanceController::class, 'addSelectedEmployee'])->name('add_selected_employee');
        Route::get('employee_shorting/{employee_code}/{type_id}/{department_id}/{section_id}/{line_id}/{designation_id}/{salary_section_id}', [AttendanceController::class, 'employeeShorting'])->name('employee_shorting');

        // Monthly attendance time card
        Route::get('monthly_attendance_time_card', [AttendanceController::class, 'monthlyAttendanceTimeCard'])->name('monthly_attendance_time_card');
        Route::get('monthly_attendance_time_card_search/{month}/{pdf}', [AttendanceController::class, 'monthlyAttendanceTimeCardSearch'])->name('monthly_attendance_time_card_search');
        Route::get('monthly_attendance_time_card_search__/{month}/{pdf}', [AttendanceController::class, 'monthlyAttendanceTimeCardSearch'])->name('monthly_attendance_time_card_search__');

        // daily attendance summary search
        Route::get('daily_attendance_summary', [AttendanceController::class, 'dailyAttendanceSummary'])->name('daily_attendance_summary');
        Route::get('daily_attendance_summary_search/{sectionId}/{startDate}/{pdf}', [AttendanceController::class, 'dailyAttendanceSummarySearch'])->name('daily_attendance_summary_search');

        // present attendance search
        Route::get('present_attendance_list', [AttendanceController::class, 'presentAttendanceList'])->name('present_attendance_list');
        Route::get('present_attendance_search/{employeeCode}/{typeId}/{departmentId}/{sectionId}/{lineId}/{designationId}/{startDate}/{endDate}/{pdf}', [AttendanceController::class, 'presentAttendanceSearch'])->name('present_attendance_search');        
        
        // absent attendance search
        Route::get('absent_attendance_list', [AttendanceController::class, 'absentAttendanceList'])->name('absent_attendance_list');
        Route::get('absent_attendance_search/{employeeCode}/{typeId}/{departmentId}/{sectionId}/{lineId}/{designationId}/{startDate}/{endDate}/{pdf}', [AttendanceController::class, 'absentAttendanceSearch'])->name('absent_attendance_search');

        // attendance report
        Route::resource('attendance', AttendanceController::class);
        Route::get('daily_attendance_search/{employeeID}/{startDate}/{endDate}/{pdf}', [AttendanceController::class, 'dailyAttendanceSearch'])->name('daily_attendance_search');
        Route::get('code_wais_employee/{employeeCode}', [AttendanceController::class, 'codehWaisEmployee'])->name('code_wais_employee');
        Route::get('branch_wais_employee/{branchID}', [AttendanceController::class, 'branchWaisEmployee'])->name('branch_wais_employee');
        
        Route::get('all_employee_attendance_chart', [AttendanceController::class, 'allEmployeeAttendanceChart'])->name('all_employee_attendance_chart');

        Route::get('daily_all_attendance', [AttendanceController::class, 'dailyAllAttendance'])->name('daily_all_attendance');
        Route::get('single_employee_attendance_search/{employeeID}', [AttendanceController::class, 'singleEmployeeAttendanceSearch'])->name('single_employee_attendance_search');
        Route::get('single_employee_attendance_chart/{employeeID}', [AttendanceController::class, 'singleEmployeeAttendanceChart'])->name('single_employee_attendance_chart');
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
        Route::resource('payroll_head', PayrollHeadController::class);
        Route::resource('payroll_formulas', PayrollFormulaController::class);

        // Payroll input
        Route::resource('payroll', PayrollController::class);
        Route::post('payroll_employee_update', [PayrollController::class, 'payrollEmployeeUpdate'])->name('payroll_employee_update');
        Route::get('payroll_employee_edit/{employee_id}', [PayrollController::class, 'payrollEmployeeEdit'])->name('payroll_employee_edit');

        Route::resource('payslip_type', PayslipTypeController::class);
        Route::resource('income_head', IncomeHeadController::class);
        Route::resource('allowance_option', AllowanceOptionController::class);
        Route::resource('loan_option', LoanOptionController::class);
        Route::resource('deduction_head', DeductionHeadController::class);

        Route::resource('employee_salaries', EmployeeSalaryController::class);
        Route::resource('income', IncomeController::class);
        Route::resource('allowance', AllowanceController::class);
        Route::resource('commission', CommissionController::class);
        Route::resource('deduction', DeductionController::class);
        Route::resource('loan', LoanController::class);
        Route::resource('other_payment', OtherPaymentController::class);
        Route::resource('overtime', OvertimeController::class);

        Route::resource('set_salaries', SetSalaryController::class);
        Route::get('set_salaries_create/{id}', [SetSalaryController::class, 'setSalariesCreate'])->name('set_salaries.set_salaries_create');
        Route::resource('monthly_salaries', MonthlySalaryController::class);
        Route::get('monthly_salaries_list/{month}/{pdf}', [MonthlySalaryController::class, 'monthlySalariesList'])->name('monthly_salaries_list');
        // not need after
        Route::get('monthly_salaries/{branch_id}/{month}/{pdf}', [MonthlySalaryController::class, 'monthlySalaries'])->name('monthly_salaries');

        Route::resource('payslips', PayslipController::class);
        Route::get('/get-payslip/{employeeId}', [PayslipController::class, 'getPayslipData']);
        Route::get('/get-all-payslip/{employeeId}', [PayslipController::class, 'getAllPayslipData']);
        
        // Route::get('salary_sheet', [PayslipController::class,'salary_sheet'])->name('salary_sheet');
        
    });
});

Route::get('/error', function () {
    abort(500);
});

Route::get('/auth/redirect/{provider}', [SocialiteController::class, 'redirect']);

require __DIR__ . '/auth.php';
