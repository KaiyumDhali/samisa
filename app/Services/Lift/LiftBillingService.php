<?php

namespace App\Services\Lift;

use App\Models\FinanceAccount;
use App\Models\Lift\LiftBill;
use App\Models\Lift\LiftBillPayment;
use App\Models\Lift\LiftContract;
use App\Models\Lift\LiftJob;
use App\Models\Lift\LiftJobPart;
use App\Models\Lift\LiftUnit;
use App\Models\Stock;
use App\Services\FinancePostingService;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use RuntimeException;

/**
 * Lift Service er shob business logic ar finance entry.
 *
 * Finance rule:
 *   Bill banale        : Customer Dr  /  Service Account Cr      (voucher 01LB......, type LB)
 *   Taka pele          : Cash/Bank Dr /  Customer Cr             (voucher 01CR......, type CR)  <- Received Voucher er moto
 *   Bill cancel        : Service Account Dr / Customer Cr        (voucher 01LB......, type LB)
 * Spare parts stock theke 'Out' hoy (Sales er moto); parts er dam bill e jog hoy, tai Service Account e jay.
 */
class LiftBillingService
{
    public const RECEIVE_GROUP_CODES = ['100020002', '100020003', '100020004']; // Cash, Mobile Bank, Bank

    public function __construct(private FinancePostingService $finance)
    {
    }

    // ------------------------------------------------------------------ AMC contract

    public function createContract(array $d, array $unitIds, string $by): LiftContract
    {
        $unitIds = array_values(array_unique(array_map('intval', $unitIds)));
        if (!$unitIds) {
            throw new RuntimeException('Kombokhomo ekta lift select korun.');
        }
        if (Carbon::parse($d['end_date'])->lt(Carbon::parse($d['start_date']))) {
            throw new RuntimeException('End date start date er age hote parbe na.');
        }
        if (!isset(LiftContract::CYCLE_MONTHS[$d['billing_cycle']])) {
            throw new RuntimeException('Billing cycle thik na.');
        }
        $ok = LiftUnit::whereIn('id', $unitIds)->where('customer_id', $d['customer_id'])->where('status', 1)->count();
        if ($ok !== count($unitIds)) {
            throw new RuntimeException('Select kora lift gulo ei customer er na ba inactive.');
        }

        return DB::transaction(function () use ($d, $unitIds, $by) {
            $c = LiftContract::create([
                'customer_id' => $d['customer_id'],
                'start_date' => $d['start_date'],
                'end_date' => $d['end_date'],
                'billing_cycle' => $d['billing_cycle'],
                'fee_per_cycle' => round((float) $d['fee_per_cycle'], 2),
                'visits_per_year' => (int) $d['visits_per_year'],
                'next_bill_date' => $d['start_date'],
                'status' => 'active',
                'terms' => $d['terms'] ?? null,
                'done_by' => $by,
            ]);
            $c->update(['contract_no' => 'AMC' . str_pad((string) $c->id, 6, '0', STR_PAD_LEFT)]);
            $c->units()->sync($unitIds);
            $this->generateVisits($c, $unitIds, $by);
            return $c;
        });
    }

    /** Contract period e visits_per_year onujayi scheduled AMC visit job banay (prottek lift er jonno) */
    private function generateVisits(LiftContract $c, array $unitIds, string $by): void
    {
        $perYear = (int) $c->visits_per_year;
        if ($perYear <= 0) {
            return;
        }
        $start = Carbon::parse($c->start_date);
        $end = Carbon::parse($c->end_date);
        $days = (int) $start->diffInDays($end) + 1;
        $interval = 365 / $perYear;
        $n = (int) floor($days / $interval);

        for ($i = 0; $i < $n; $i++) {
            $date = $start->copy()->addDays((int) round($interval * ($i + 0.5)));
            if ($date->gt($end)) {
                break;
            }
            foreach ($unitIds as $unitId) {
                $job = LiftJob::create([
                    'lift_unit_id' => $unitId,
                    'customer_id' => $c->customer_id,
                    'contract_id' => $c->id,
                    'job_type' => 'amc_visit',
                    'scheduled_date' => $date->toDateString(),
                    'status' => 'scheduled',
                    'is_billable' => 0,
                    'problem' => 'AMC routine visit (' . $c->contract_no . ')',
                    'done_by' => $by,
                ]);
                $job->update(['job_no' => 'LSJ' . str_pad((string) $job->id, 6, '0', STR_PAD_LEFT)]);
            }
        }
    }

    public function createContractBill(int $contractId, string $billDate, string $by): LiftBill
    {
        return DB::transaction(function () use ($contractId, $billDate, $by) {
            $c = LiftContract::lockForUpdate()->findOrFail($contractId);
            if ($c->status !== 'active') {
                throw new RuntimeException('Contract active na.');
            }
            if (!$c->next_bill_date || $c->next_bill_date->gt($c->end_date)) {
                throw new RuntimeException('Ei contract er shob period er bill deya hoye geche.');
            }

            $from = $c->next_bill_date->copy();
            $months = LiftContract::CYCLE_MONTHS[$c->billing_cycle];
            $fullTo = $from->copy()->addMonthsNoOverflow($months)->subDay();
            $to = $fullTo->gt($c->end_date) ? $c->end_date->copy() : $fullTo;

            $amount = (float) $c->fee_per_cycle;
            if ($to->lt($fullTo)) { // shesh period chhoto hole din onupate
                $amount = round($amount * ((int) $from->diffInDays($to) + 1) / ((int) $from->diffInDays($fullTo) + 1), 2);
            }

            $bill = $this->createBill([
                'bill_date' => $billDate,
                'customer_id' => $c->customer_id,
                'bill_type' => 'amc',
                'contract_id' => $c->id,
                'period_from' => $from->toDateString(),
                'period_to' => $to->toDateString(),
                'service_amount' => $amount,
                'parts_amount' => 0,
                'discount' => 0,
                'remarks' => 'AMC ' . $c->contract_no . ' : ' . $from->format('d-m-Y') . ' to ' . $to->format('d-m-Y'),
            ], $by);

            $c->update(['next_bill_date' => $to->copy()->addDay()->toDateString()]);
            return $bill;
        });
    }

    // ------------------------------------------------------------------ Service job

    public function createJob(array $d, string $by): LiftJob
    {
        $unit = LiftUnit::where('id', $d['lift_unit_id'])->where('status', 1)->first();
        if (!$unit) {
            throw new RuntimeException('Lift paoa jayni ba inactive.');
        }
        return DB::transaction(function () use ($d, $unit, $by) {
            $job = LiftJob::create([
                'lift_unit_id' => $unit->id,
                'customer_id' => $unit->customer_id,
                'contract_id' => $d['contract_id'] ?: null,
                'job_type' => $d['job_type'],
                'scheduled_date' => $d['scheduled_date'],
                'technician_name' => $d['technician_name'] ?? null,
                'technician_mobile' => $d['technician_mobile'] ?? null,
                'problem' => $d['problem'] ?? null,
                'status' => 'scheduled',
                'is_billable' => 0,
                'done_by' => $by,
            ]);
            $job->update(['job_no' => 'LSJ' . str_pad((string) $job->id, 6, '0', STR_PAD_LEFT)]);
            return $job;
        });
    }

    /**
     * Job complete: parts stock theke 'Out', charge hishab. Finance entry hoy na — bill alada step.
     * $parts = [ ['product_id'=>, 'warehouse_id'=>, 'quantity'=>, 'unit_price'=>], ... ]
     */
    public function completeJob(int $jobId, array $d, array $parts, string $by): LiftJob
    {
        return DB::transaction(function () use ($jobId, $d, $parts, $by) {
            $job = LiftJob::lockForUpdate()->findOrFail($jobId);
            if ($job->status !== 'scheduled') {
                throw new RuntimeException('Ei job ager e complete/cancel hoye geche.');
            }
            $billable = !empty($d['is_billable']);
            $serviceCharge = $billable ? round((float) ($d['service_charge'] ?? 0), 2) : 0.0;
            if ($serviceCharge < 0) {
                throw new RuntimeException('Service charge minus hote pare na.');
            }
            $date = $d['completed_date'];
            $partsTotal = 0.0;

            foreach ($parts as $p) {
                $pid = (int) ($p['product_id'] ?? 0);
                $qty = round((float) ($p['quantity'] ?? 0), 2);
                if (!$pid || $qty <= 0) {
                    continue; // khali row
                }
                $wid = (int) ($p['warehouse_id'] ?? 0);
                $price = $billable ? round((float) ($p['unit_price'] ?? 0), 2) : 0.0;
                if ($price < 0) {
                    throw new RuntimeException('Part er dam minus hote pare na.');
                }

                // product row lock => ek-i somoy e duita job eki stock dui bar niye jete parbe na
                $product = DB::table('products')->where('id', $pid)->lockForUpdate()->first();
                if (!$product) {
                    throw new RuntimeException("Product (ID: $pid) paoa jayni.");
                }
                $avail = (float) Stock::where('product_id', $pid)->where('warehouse_id', $wid)
                    ->selectRaw('IFNULL(SUM(stock_in_quantity),0) - IFNULL(SUM(stock_out_quantity),0) AS q')->value('q');
                if ($qty > $avail + 0.0001) {
                    throw new RuntimeException("Stock kom: {$product->product_name} — ache $avail, lagbe $qty.");
                }
                $cost = (float) (Stock::where('product_id', $pid)->max('stock_in_unit_price') ?: ($product->purchase_price ?? 0));
                $total = round($qty * $price, 2);

                $out = new Stock();
                $out->warehouse_id = $wid;
                $out->stock_date = $date;
                $out->stock_type = 'Out';
                $out->delivery_challan_no = $job->job_no;
                $out->invoice_no = $job->job_no;      // LSJ...  (sales report er INV% e dhukbe na)
                $out->customer_id = $job->customer_id;
                $out->product_id = $pid;
                $out->purchase_price = $cost;
                $out->stock_in_quantity = 0;
                $out->stock_out_quantity = $qty;
                $out->stock_out_unit_price = $price;
                $out->stock_out_discount = 0;
                $out->stock_out_total_amount = $total;
                $out->status = 1;
                $out->remarks = 'Lift service ' . $job->job_no;
                $out->done_by = $by;
                $out->save();

                LiftJobPart::create([
                    'job_id' => $job->id, 'product_id' => $pid, 'warehouse_id' => $wid,
                    'quantity' => $qty, 'unit_price' => $price, 'purchase_price' => $cost, 'total_amount' => $total,
                ]);
                $partsTotal += $total;
            }

            $job->update([
                'status' => 'completed',
                'completed_date' => $date,
                'work_done' => $d['work_done'] ?? null,
                'technician_name' => $d['technician_name'] ?? $job->technician_name,
                'technician_mobile' => $d['technician_mobile'] ?? $job->technician_mobile,
                'is_billable' => $billable ? 1 : 0,
                'service_charge' => $serviceCharge,
                'parts_total' => round($partsTotal, 2),
            ]);
            return $job;
        });
    }

    public function cancelJob(int $jobId): void
    {
        DB::transaction(function () use ($jobId) {
            $job = LiftJob::lockForUpdate()->findOrFail($jobId);
            if ($job->status !== 'scheduled') {
                throw new RuntimeException('Shudhu scheduled job cancel kora jay.');
            }
            $job->update(['status' => 'cancelled']);
        });
    }

    public function createJobBill(int $jobId, string $billDate, float $discount, string $by): LiftBill
    {
        return DB::transaction(function () use ($jobId, $billDate, $discount, $by) {
            $job = LiftJob::lockForUpdate()->findOrFail($jobId);
            if ($job->status !== 'completed' || !$job->is_billable) {
                throw new RuntimeException('Shudhu complete kora billable job er bill hoy.');
            }
            if ($job->bill_id) {
                throw new RuntimeException('Ei job er bill ager e deya hoyeche.');
            }
            $discount = round($discount, 2);
            if ($discount < 0 || $discount > round($job->service_charge + $job->parts_total, 2)) {
                throw new RuntimeException('Discount thik na.');
            }

            $bill = $this->createBill([
                'bill_date' => $billDate,
                'customer_id' => $job->customer_id,
                'bill_type' => 'job',
                'job_id' => $job->id,
                'service_amount' => (float) $job->service_charge,
                'parts_amount' => (float) $job->parts_total,
                'discount' => $discount,
                'remarks' => 'Service job ' . $job->job_no,
            ], $by);

            $job->update(['bill_id' => $bill->id]);
            return $bill;
        });
    }

    // ------------------------------------------------------------------ Bill + finance

    /** DB::transaction er bhitore-i dakte hobe */
    private function createBill(array $b, string $by): LiftBill
    {
        $total = round((float) $b['service_amount'] + (float) $b['parts_amount'] - (float) $b['discount'], 2);
        if ($total <= 0) {
            throw new RuntimeException('Bill er total 0 er cheye beshi hote hobe.');
        }
        $serviceAccId = $this->finance->serviceAccountId();
        $customer = FinanceAccount::where('id', $b['customer_id'])->where('account_status', 1)->first();
        if (!$customer) {
            throw new RuntimeException('Customer account paoa jayni.');
        }

        $bill = LiftBill::create($b + ['total_amount' => $total, 'paid_amount' => 0, 'status' => 'unpaid', 'done_by' => $by]);
        $billNo = 'LSB' . str_pad((string) $bill->id, 6, '0', STR_PAD_LEFT);

        $narration = "Lift Bill:$billNo, Customer:{$customer->account_name}, " . ($b['remarks'] ?? '');
        $voucherNo = $this->finance->postPair([
            'prefix' => '01LB',
            'type' => 'LB',
            'date' => $b['bill_date'],
            'dr_account_id' => $customer->id,   // customer pabe
            'cr_account_id' => $serviceAccId,   // service income
            'amount' => $total,
            'invoice_no' => $billNo,
            'narration' => $narration,
            'done_by' => $by,
        ]);

        $bill->update(['bill_no' => $billNo, 'voucher_no' => $voucherNo]);
        return $bill->refresh();
    }

    public function receivePayment(int $billId, float $amount, int $receiveAccountId, string $date, ?string $remarks, string $by): LiftBillPayment
    {
        return DB::transaction(function () use ($billId, $amount, $receiveAccountId, $date, $remarks, $by) {
            $bill = LiftBill::lockForUpdate()->findOrFail($billId);
            if ($bill->status === 'cancelled') {
                throw new RuntimeException('Cancelled bill e taka neya jay na.');
            }
            $amount = round($amount, 2);
            $due = round($bill->total_amount - $bill->paid_amount, 2);
            if ($amount <= 0 || $amount > $due + 0.005) {
                throw new RuntimeException("Amount thik na. Baki ache: $due");
            }

            $recv = FinanceAccount::where('id', $receiveAccountId)->where('account_status', 1)->first();
            if (!$recv || !in_array((string) $recv->account_group_code, self::RECEIVE_GROUP_CODES, true)) {
                throw new RuntimeException('Cash / Mobile Bank / Bank account select korun.');
            }
            $groupName = DB::table('finance_groups')->where('id', $recv->financegroup_id)->value('group_name');
            $customer = FinanceAccount::find($bill->customer_id);
            $fmt = number_format($amount, 2);

            $voucherNo = $this->finance->postPair([
                'prefix' => '01CR',
                'type' => 'CR',
                'date' => $date,
                'dr_account_id' => $recv->id,        // cash/bank e taka dhukbe
                'cr_account_id' => $bill->customer_id, // customer er pabo komlo
                'amount' => $amount,
                'payment_type' => $groupName,
                'invoice_no' => $bill->bill_no,
                'narration' => "{$recv->account_name} Received From: {$customer->account_name}, Lift Bill:{$bill->bill_no}, Received Amount:$fmt TK " . ($remarks ?? ''),
                'done_by' => $by,
            ]);

            $payment = LiftBillPayment::create([
                'bill_id' => $bill->id, 'payment_date' => $date, 'amount' => $amount,
                'receive_account_id' => $recv->id, 'voucher_no' => $voucherNo, 'remarks' => $remarks, 'done_by' => $by,
            ]);

            $paid = round($bill->paid_amount + $amount, 2);
            $bill->update([
                'paid_amount' => $paid,
                'status' => abs($paid - $bill->total_amount) < 0.005 ? 'paid' : 'partial',
            ]);
            return $payment;
        });
    }

    /** Taka na pele bill cancel + ulto voucher. Contract bill hole shudhu shesh bill cancel kora jabe */
    public function cancelBill(int $billId, string $date, string $by): LiftBill
    {
        return DB::transaction(function () use ($billId, $date, $by) {
            $bill = LiftBill::lockForUpdate()->findOrFail($billId);
            if ($bill->status !== 'unpaid' || (float) $bill->paid_amount > 0) {
                throw new RuntimeException('Jei bill e taka neya hoyeche ba already cancel, seta cancel kora jay na.');
            }

            $contract = null;
            if ($bill->bill_type === 'amc') {
                $contract = LiftContract::lockForUpdate()->findOrFail($bill->contract_id);
                $latest = LiftBill::where('contract_id', $contract->id)->where('status', '!=', 'cancelled')->max('id');
                if ((int) $latest !== (int) $bill->id) {
                    throw new RuntimeException('Shudhu contract er shesh bill cancel kora jay.');
                }
            }

            $serviceAccId = $this->finance->serviceAccountId();
            $customer = FinanceAccount::find($bill->customer_id);
            $cancelVoucher = $this->finance->postPair([
                'prefix' => '01LB',
                'type' => 'LB',
                'date' => $date,
                'dr_account_id' => $serviceAccId,       // income ulte
                'cr_account_id' => $bill->customer_id,  // customer er pabo komlo
                'amount' => $bill->total_amount,
                'invoice_no' => $bill->bill_no,
                'narration' => "CANCELLED Lift Bill:{$bill->bill_no} (voucher {$bill->voucher_no}), Customer:{$customer->account_name}",
                'done_by' => $by,
            ]);

            $bill->update(['status' => 'cancelled', 'cancel_voucher_no' => $cancelVoucher]);

            if ($contract) {
                $contract->update(['next_bill_date' => $bill->period_from->toDateString()]);
            }
            if ($bill->bill_type === 'job' && $bill->job_id) {
                LiftJob::where('id', $bill->job_id)->update(['bill_id' => null]);
            }
            return $bill;
        });
    }
}
