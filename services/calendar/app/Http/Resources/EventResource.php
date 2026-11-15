<?php

namespace App\Http\Resources;

use App\Models\Event;
use App\Support\IsoDateTime;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Event */
class EventResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'starts_at' => IsoDateTime::format($this->starts_at),
            'duration_minutes' => $this->duration_minutes,
            'location' => $this->location,
            'notes' => $this->notes,
            'recurrence' => $this->recurrence,
            'recurrence_until' => $this->recurrence_until?->format('Y-m-d'),
            'reminder_minutes' => $this->reminder_minutes,
            'created_at' => IsoDateTime::format($this->created_at),
            'updated_at' => IsoDateTime::format($this->updated_at),
        ];
    }
}
