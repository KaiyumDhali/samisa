<?php

namespace App\Models\Lift;

use App\Models\Product;
use Illuminate\Database\Eloquent\Model;

class LiftJobPart extends Model
{
    protected $table = 'lift_job_parts';
    public $timestamps = false;
    protected $guarded = ['id'];

    public function product()
    {
        return $this->belongsTo(Product::class, 'product_id');
    }
}
