<?php

namespace App\Models\Lift;

use App\Models\FinanceAccount;
use Illuminate\Database\Eloquent\Model;

class LiftJob extends Model
{
    protected $table = 'lift_service_jobs';
    protected $guarded = ['id'];
    protected $casts = ['scheduled_date' => 'date', 'completed_date' => 'date'];

    public function unit()
    {
        return $this->belongsTo(LiftUnit::class, 'lift_unit_id');
    }

    public function customer()
    {
        return $this->belongsTo(FinanceAccount::class, 'customer_id');
    }

    public function contract()
    {
        return $this->belongsTo(LiftContract::class, 'contract_id');
    }

    public function parts()
    {
        return $this->hasMany(LiftJobPart::class, 'job_id');
    }

    public function bill()
    {
        return $this->belongsTo(LiftBill::class, 'bill_id');
    }
}
