<?php

namespace App\Models;

use App\Models\Concerns\BelongsToUser;
use App\Services\RecurrenceExpander;
use Illuminate\Database\Eloquent\Model;

class Event extends Model
{
    use BelongsToUser;

    public const DEFAULT_DURATION_MINUTES = 60;

    protected $fillable = [
        'title',
        'starts_at',
        'duration_minutes',
        'location',
        'notes',
        'recurrence',
        'recurrence_until',
        'reminder_minutes',
    ];

    protected $attributes = [
        'duration_minutes' => self::DEFAULT_DURATION_MINUTES,
        'recurrence' => RecurrenceExpander::NONE,
    ];

    protected function casts(): array
    {
        return [
            'user_id' => 'integer',
            'starts_at' => 'immutable_datetime',
            'duration_minutes' => 'integer',
            'recurrence_until' => 'immutable_date',
            'reminder_minutes' => 'integer',
        ];
    }
}
