<?php

namespace App\Http\Controllers\Finance;

use App\Http\Controllers\Controller;
use App\Models\CompanySetting;
use App\Services\BalanceSheetService;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use PhpOffice\PhpSpreadsheet\Spreadsheet;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Fill;
use PhpOffice\PhpSpreadsheet\Writer\Xlsx;

class BalanceSheetController extends Controller
{
    function __construct()
    {
        // Notun permission lagbe na — General Ledger er permission e cholbe
        $this->middleware('permission:read general ledger');
    }

    private function asOnDate(Request $request): string
    {
        try {
            return Carbon::parse($request->query('as_on_date', date('Y-m-d')))->format('Y-m-d');
        } catch (\Throwable $e) {
            return date('Y-m-d');
        }
    }

    // Menu click => page + report generate
    public function index(Request $request, BalanceSheetService $service)
    {
        $asOnDate = $this->asOnDate($request);
        $report = $service->generate($asOnDate);
        return view('pages.finance.report.balance_sheet', compact('report', 'asOnDate'));
    }

    public function pdf(Request $request, BalanceSheetService $service)
    {
        $asOnDate = $this->asOnDate($request);
        $report = $service->generate($asOnDate);

        $company = CompanySetting::where('status', 1)->orderBy('id', 'desc')->first();
        $data = [
            'company_name' => $company->company_name ?? '',
            'company_address' => $company->company_address ?? '',
            'factory_address' => $company->factory_address ?? '',
            'company_mobile' => $company->company_mobile ?? '',
            'logo' => $this->logoDataUri($company->company_logo_one ?? null),
        ];

        $pdf = Pdf::loadView('pages.pdf.balanceSheet_pdf', compact('report', 'data'));
        return $pdf->stream('balance-sheet-' . $asOnDate . '.pdf');
    }

    public function excel(Request $request, BalanceSheetService $service)
    {
        $asOnDate = $this->asOnDate($request);
        $r = $service->generate($asOnDate);
        $company = CompanySetting::where('status', 1)->orderBy('id', 'desc')->first();

        $ss = new Spreadsheet();
        $ws = $ss->getActiveSheet();
        $ws->setTitle('Balance Sheet');
        $ws->setCellValue('A1', $company->company_name ?? '');
        $ws->setCellValue('A2', 'BALANCE SHEET');
        $ws->setCellValue('A3', 'As on ' . Carbon::parse($asOnDate)->format('d F Y'));
        $ws->mergeCells('A1:B1'); $ws->mergeCells('A2:B2'); $ws->mergeCells('A3:B3');
        $ws->getStyle('A1:A3')->getFont()->setBold(true);
        $ws->getStyle('A1:A3')->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
        $ws->getStyle('A1')->getFont()->setSize(14);

        $row = 5;
        $ws->setCellValue("A$row", 'Particulars');
        $ws->setCellValue("B$row", 'Amount (BDT)');
        $ws->getStyle("A$row:B$row")->getFont()->setBold(true);
        $ws->getStyle("A$row:B$row")->getFill()->setFillType(Fill::FILL_SOLID)->getStartColor()->setRGB('D0DCEC');
        $row++;

        $section = function (string $title) use ($ws, &$row) {
            $ws->setCellValue("A$row", $title);
            $ws->getStyle("A$row:B$row")->getFont()->setBold(true);
            $row++;
        };
        $lines = function (array $items) use ($ws, &$row) {
            foreach ($items as $it) {
                $ws->setCellValue("A$row", '   ' . $it['label']);
                $ws->setCellValue("B$row", $it['amount']);
                $row++;
            }
        };
        $total = function (string $label, float $amount, bool $fill = false) use ($ws, &$row) {
            $ws->setCellValue("A$row", $label);
            $ws->setCellValue("B$row", $amount);
            $ws->getStyle("A$row:B$row")->getFont()->setBold(true);
            if ($fill) {
                $ws->getStyle("A$row:B$row")->getFill()->setFillType(Fill::FILL_SOLID)->getStartColor()->setRGB('E8EEF6');
            }
            $row++;
        };

        $section('ASSETS');
        if ($r['fixed_assets']) { $section('Fixed Assets'); $lines($r['fixed_assets']); $total('Total Fixed Assets', $r['total_fixed_assets']); }
        $section('Current Assets'); $lines($r['current_assets']); $total('Total Current Assets', $r['total_current_assets']);
        $total('TOTAL ASSETS', $r['total_assets'], true);
        $row++;
        $section('LIABILITIES & EQUITY');
        $section('Liabilities'); $lines($r['liabilities']); $total('Total Liabilities', $r['total_liabilities']);
        $section('Equity');
        $lines([
            ['label' => 'Total Income', 'amount' => $r['total_income']],
            ['label' => 'Less: Total Expenses', 'amount' => -$r['total_expense']],
        ]);
        $total('Net Profit (Retained Earnings)', $r['total_equity']);
        $total('TOTAL LIABILITIES & EQUITY', $r['total_liabilities_equity'], true);

        $ws->getStyle('B6:B' . $row)->getNumberFormat()->setFormatCode('#,##0.00;[Red]-#,##0.00');
        $ws->getColumnDimension('A')->setWidth(60);
        $ws->getColumnDimension('B')->setWidth(22);

        $filename = 'balance-sheet-' . $asOnDate . '.xlsx';
        return response()->streamDownload(function () use ($ss) {
            (new Xlsx($ss))->save('php://output');
        }, $filename, [
            'Content-Type' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ]);
    }

    private function logoDataUri(?string $path): ?string
    {
        if (!$path) {
            return null;
        }
        $full = public_path(Storage::url($path));
        if (!is_file($full)) {
            return null;
        }
        return 'data:' . mime_content_type($full) . ';base64,' . base64_encode(file_get_contents($full));
    }
}
