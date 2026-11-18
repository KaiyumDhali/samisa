<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DailyProduction extends Model
{
    use HasFactory;

    protected $fillable = [
        'product_id',
        'production_quantity',
        'production_date',
        'daily_production_no',
        'remarks',
        'status',
        'done_by',
        'is_edited',
    ];

    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id');
    }
}
