<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Customer extends Model
{
    use HasFactory;

    public function customerLedger(){
        return $this->hasMany(CustomerLedger::class, 'customer_id');
    }

    protected $guarded = ['id', 'created_at', 'updated_at'];

}
