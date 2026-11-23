<?php

namespace App\Services;

use App\Models\FinanceAccount;
use App\Models\FinanceTransaction;
use Illuminate\Support\Facades\DB;
use RuntimeException;

/**
 * Finance e entry deowar EKMATRO jayga (Lift module er jonno).
 *
 * Rule (apnar system er moto):
 *   finance_transactions.acid         => je account e entry
 *   finance_transactions.balance_type => 'Dr' / 'Cr'
 *   Prottek voucher e ekta Dr row + ekta Cr row, same amount => Dr = Cr shob somoy.
 *
 * Ei service DB::transaction er bhitore chalate hobe (caller ke).
 */
class FinancePostingService
{
    /** Shared voucher counter (invoiceno.voucher_no) — lock kore, jate duita voucher e same number na hoy */
    public function nextVoucherNo(string $prefix): string
    {
        $row = DB::table('invoiceno')->lockForUpdate()->first(['voucher_no']);
        if (!$row || $row->voucher_no === null) {
            throw new RuntimeException('invoiceno table e voucher_no counter paoa jayni.');
        }
        $no = (int) $row->voucher_no;
        DB::table('invoiceno')->update(['voucher_no' => $no + 1]);

        return $prefix . str_pad((string) $no, 6, '0', STR_PAD_LEFT);
    }

    /** Service Income account (Helpers.php er $GLOBALS['ServiceAccountID']) thik ache kina check kore */
    public function serviceAccountId(): int
    {
        $id = (int) ($GLOBALS['ServiceAccountID'] ?? 0);
        $acc = FinanceAccount::where('id', $id)->where('account_status', 1)->first();
        if (!$acc) {
            throw new RuntimeException("Service Account (ID: $id) paoa jayni. Finance > Accounts e Income group er under e account kholen, tarpor app/Helpers/Helpers.php e ServiceAccountID e shei ID din.");
        }
        $root = DB::table('finance_groups')->where('id', $acc->financegroup_id)->value('group_code');
        if (!$root || substr((string) $root, 0, 1) !== '3') {
            throw new RuntimeException("Service Account (ID: $id) Income group (3...) er under e nei. Income group e account khulun.");
        }
        return $id;
    }

    /**
     * 2-line voucher: Dr account + Cr account, same amount.
     * @return string voucher_no
     */
    public function postPair(array $p): string
    {
        $amount = round((float) $p['amount'], 2);
        if ($amount <= 0) {
            throw new RuntimeException('Voucher er amount 0 er cheye beshi hote hobe.');
        }
        if ((int) $p['dr_account_id'] === (int) $p['cr_account_id']) {
            throw new RuntimeException('Dr ar Cr account ek hote parbe na.');
        }

        $dr = FinanceAccount::where('id', $p['dr_account_id'])->where('account_status', 1)->first();
        $cr = FinanceAccount::where('id', $p['cr_account_id'])->where('account_status', 1)->first();
        if (!$dr || !$cr) {
            throw new RuntimeException('Finance account paoa jayni ba inactive.');
        }

        $voucherNo = $this->nextVoucherNo($p['prefix']);
        $base = [
            'company_code' => '01',
            'invoice_no' => $p['invoice_no'] ?? null,
            'voucher_no' => $voucherNo,
            'voucher_date' => $p['date'],
            'type' => $p['type'],
            'amount' => $amount,
            'payment_type' => $p['payment_type'] ?? null,
            'narration' => $p['narration'] ?? null,
            'transaction_date' => $p['date'],
            'transaction_by' => $p['done_by'],
            'done_by' => $p['done_by'],
            'updated_by' => $p['done_by'],
        ];

        FinanceTransaction::create($base + ['acid' => $dr->id, 'to_acc_name' => $cr->account_name, 'balance_type' => 'Dr']);
        FinanceTransaction::create($base + ['acid' => $cr->id, 'to_acc_name' => $dr->account_name, 'balance_type' => 'Cr']);

        // Safety check: ei voucher er Dr = Cr kina
        $sums = FinanceTransaction::where('voucher_no', $voucherNo)
            ->selectRaw("SUM(CASE WHEN balance_type='Dr' THEN amount ELSE 0 END) AS dr, SUM(CASE WHEN balance_type='Cr' THEN amount ELSE 0 END) AS cr")
            ->first();
        if (round((float) $sums->dr - (float) $sums->cr, 2) != 0.0) {
            throw new RuntimeException("Voucher $voucherNo balanced na (Dr ≠ Cr). Entry batil kora hoyeche.");
        }

        return $voucherNo;
    }
}
