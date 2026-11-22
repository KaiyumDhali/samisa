<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Overtime extends Model
{
    protected $fillable = [
        'employee_id',
        'overtime_month',
        'work_date',
        'source',
        'status',
        'punch_in',
        'punch_out',
        'approved_by',
        'approved_at',
        'title',
        'number_of_days',
        'hours',
        'rate',
        'created_by',
    ];

    protected $casts = [
        'work_date' => 'date',
    ];

    public function user()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function employee()
    {
        return $this->belongsTo(Employee::class, 'employee_id');
    }
}