<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

/**
 * Balance Sheet — finance_transactions theke (system er nijer Dr/Cr rule onujayi).
 *
 *  finance_transactions.acid         => je account e entry post hoy
 *  finance_transactions.balance_type => 'Dr' ba 'Cr'
 *  finance_groups.group_code         => 1 Assets, 2 Expenses, 3 Income, 4 Liabilities
 *  100020001 = Account Receivable (customers), 400010001 = Account Payable (suppliers)
 */
class BalanceSheetService
{
    public function generate(string $asOnDate): array
    {
        $rows = DB::table('finance_accounts as fa')
            ->join('finance_groups as fg', 'fg.id', '=', 'fa.financegroup_id')
            ->leftJoin('finance_transactions as ft', function ($join) use ($asOnDate) {
                $join->on('ft.acid', '=', 'fa.id')->where('ft.voucher_date', '<=', $asOnDate);
            })
            ->groupBy('fa.id', 'fa.account_name', 'fg.group_code', 'fg.group_name')
            ->selectRaw("fa.id, fa.account_name, fg.group_code, fg.group_name,
                IFNULL(SUM(CASE WHEN ft.balance_type = 'Dr' THEN ft.amount ELSE 0 END), 0) AS total_dr,
                IFNULL(SUM(CASE WHEN ft.balance_type = 'Cr' THEN ft.amount ELSE 0 END), 0) AS total_cr")
            ->orderBy('fg.group_code')
            ->orderBy('fa.id')
            ->get();

        $fixedAssets = [];
        $currentAssets = [];
        $liabilities = [];
        $income = [];
        $expenses = [];

        $receivable = ['amount' => 0, 'count' => 0];
        $customerAdvance = ['amount' => 0, 'count' => 0];
        $payable = ['amount' => 0, 'count' => 0];
        $supplierAdvance = ['amount' => 0, 'count' => 0];

        foreach ($rows as $r) {
            $dr = (float) $r->total_dr;
            $cr = (float) $r->total_cr;
            $net = round($dr - $cr, 2); // Dr - Cr
            if (abs($net) < 0.005) {
                continue;
            }
            $code = (string) $r->group_code;
            $root = substr($code, 0, 1);

            if ($code === '100020001') {            // Customers
                if ($net > 0) { $receivable['amount'] += $net; $receivable['count']++; }
                else { $customerAdvance['amount'] += -$net; $customerAdvance['count']++; }
            } elseif ($code === '400010001') {      // Suppliers
                if ($net < 0) { $payable['amount'] += -$net; $payable['count']++; }
                else { $supplierAdvance['amount'] += $net; $supplierAdvance['count']++; }
            } elseif ($root === '1') {
                $line = ['label' => $r->group_name . ': ' . $r->account_name, 'amount' => $net];
                if (strpos($code, '10001') === 0) { $fixedAssets[] = $line; } else { $currentAssets[] = $line; }
            } elseif ($root === '4') {
                $liabilities[] = ['label' => $r->group_name . ': ' . $r->account_name, 'amount' => -$net];
            } elseif ($root === '3') {
                $income[] = ['label' => $r->account_name, 'amount' => -$net];
            } elseif ($root === '2') {
                $expenses[] = ['label' => $r->account_name, 'amount' => $net];
            }
        }

        if ($receivable['amount'] != 0) {
            $currentAssets[] = ['label' => 'Accounts Receivable (' . $receivable['count'] . ' customers)', 'amount' => round($receivable['amount'], 2)];
        }
        if ($supplierAdvance['amount'] != 0) {
            $currentAssets[] = ['label' => 'Advance to Suppliers (' . $supplierAdvance['count'] . ')', 'amount' => round($supplierAdvance['amount'], 2)];
        }
        if ($payable['amount'] != 0) {
            $liabilities[] = ['label' => 'Accounts Payable (' . $payable['count'] . ' suppliers)', 'amount' => round($payable['amount'], 2)];
        }
        if ($customerAdvance['amount'] != 0) {
            $liabilities[] = ['label' => 'Advance from Customers (' . $customerAdvance['count'] . ')', 'amount' => round($customerAdvance['amount'], 2)];
        }

        $sum = fn(array $a) => round(array_sum(array_column($a, 'amount')), 2);

        $totalFixed = $sum($fixedAssets);
        $totalCurrent = $sum($currentAssets);
        $totalAssets = round($totalFixed + $totalCurrent, 2);
        $totalLiabilities = $sum($liabilities);
        $totalIncome = $sum($income);
        $totalExpense = $sum($expenses);
        $netProfit = round($totalIncome - $totalExpense, 2);
        $totalEquity = $netProfit; // system e alada Capital/Equity account nei
        $totalLiabEquity = round($totalLiabilities + $totalEquity, 2);

        return [
            'as_on_date' => $asOnDate,
            'fixed_assets' => $fixedAssets,
            'current_assets' => $currentAssets,
            'liabilities' => $liabilities,
            'total_fixed_assets' => $totalFixed,
            'total_current_assets' => $totalCurrent,
            'total_assets' => $totalAssets,
            'total_liabilities' => $totalLiabilities,
            'total_income' => $totalIncome,
            'total_expense' => $totalExpense,
            'net_profit' => $netProfit,
            'total_equity' => $totalEquity,
            'total_liabilities_equity' => $totalLiabEquity,
            'difference' => round($totalAssets - $totalLiabEquity, 2),
        ];
    }
}
