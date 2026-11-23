<?php

namespace App\Models\Lift;

use App\Models\FinanceAccount;
use Illuminate\Database\Eloquent\Model;

class LiftBill extends Model
{
    protected $table = 'lift_bills';
    protected $guarded = ['id'];
    protected $casts = ['bill_date' => 'date', 'period_from' => 'date', 'period_to' => 'date'];

    public function customer()
    {
        return $this->belongsTo(FinanceAccount::class, 'customer_id');
    }

    public function contract()
    {
        return $this->belongsTo(LiftContract::class, 'contract_id');
    }

    public function job()
    {
        return $this->belongsTo(LiftJob::class, 'job_id');
    }

    public function payments()
    {
        return $this->hasMany(LiftBillPayment::class, 'bill_id');
    }

    public function getDueAmountAttribute(): float
    {
        return $this->status === 'cancelled' ? 0.0 : round($this->total_amount - $this->paid_amount, 2);
    }
}
