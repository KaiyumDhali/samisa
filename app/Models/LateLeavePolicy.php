<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LateLeavePolicy extends Model
{
    use HasFactory;

    protected $guarded = ['id', 'created_at', 'updated_at'];

    protected $casts = [
        'repeat_deduction' => 'boolean',
        'status' => 'boolean',
    ];

    public const LEAVE_TYPES = ['Casual', 'Sick', 'Annual', 'Special'];

    public const TYPE_COLUMN = [
        'Casual' => 'casual_leave',
        'Sick' => 'sick_leave',
        'Annual' => 'annual_leave',
        'Special' => 'special_leave',
    ];

    public static function current(): self
    {
        return static::where('status', 1)->orderByDesc('id')->first()
            ?? new static([
                'late_count' => 3,
                'deduct_days' => 1,
                'leave_type' => 'Casual',
                'fallback_leave_type' => null,
                'repeat_deduction' => true,
            ]);
    }

    public function daysFor(int $lateCount): int
    {
        if ($this->late_count < 1 || $lateCount < $this->late_count) {
            return 0;
        }
        $times = $this->repeat_deduction ? intdiv($lateCount, $this->late_count) : 1;
        return $times * $this->deduct_days;
    }
}