<?php

namespace App\Models\Lift;

use App\Models\FinanceAccount;
use Illuminate\Database\Eloquent\Model;

class LiftBillPayment extends Model
{
    protected $table = 'lift_bill_payments';
    public $timestamps = false;
    protected $guarded = ['id'];
    protected $casts = ['payment_date' => 'date'];

    public function receiveAccount()
    {
        return $this->belongsTo(FinanceAccount::class, 'receive_account_id');
    }
}
