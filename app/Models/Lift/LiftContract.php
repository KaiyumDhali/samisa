<?php

namespace App\Models\Lift;

use App\Models\FinanceAccount;
use Illuminate\Database\Eloquent\Model;

class LiftContract extends Model
{
    protected $table = 'lift_amc_contracts';
    protected $guarded = ['id'];
    protected $casts = ['start_date' => 'date', 'end_date' => 'date', 'next_bill_date' => 'date'];

    public const CYCLE_MONTHS = ['monthly' => 1, 'quarterly' => 3, 'half_yearly' => 6, 'yearly' => 12];

    public function customer()
    {
        return $this->belongsTo(FinanceAccount::class, 'customer_id');
    }

    public function units()
    {
        return $this->belongsToMany(LiftUnit::class, 'lift_amc_contract_units', 'contract_id', 'lift_unit_id');
    }

    public function jobs()
    {
        return $this->hasMany(LiftJob::class, 'contract_id');
    }

    public function bills()
    {
        return $this->hasMany(LiftBill::class, 'contract_id');
    }
}
