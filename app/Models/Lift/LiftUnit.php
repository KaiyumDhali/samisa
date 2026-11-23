<?php

namespace App\Models\Lift;

use App\Models\FinanceAccount;
use Illuminate\Database\Eloquent\Model;

class LiftUnit extends Model
{
    protected $table = 'lift_units';
    protected $guarded = ['id'];

    public function customer()
    {
        return $this->belongsTo(FinanceAccount::class, 'customer_id');
    }

    public function contracts()
    {
        return $this->belongsToMany(LiftContract::class, 'lift_amc_contract_units', 'lift_unit_id', 'contract_id');
    }

    public function jobs()
    {
        return $this->hasMany(LiftJob::class, 'lift_unit_id');
    }
}
