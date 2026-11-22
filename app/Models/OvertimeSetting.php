<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OvertimeSetting extends Model
{
    protected $guarded = ['id'];

    protected $casts = [
        'count_holiday_work' => 'boolean',
    ];
}