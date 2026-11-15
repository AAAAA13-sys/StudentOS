<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TransactionResource extends JsonResource
{
    private const TIMESTAMP_FORMAT = 'Y-m-d\TH:i:s\Z';

    public function toArray(Request $request): array
    {
        return [
            'id' => (int) $this->id,
            'type' => $this->type,
            'amount' => round((float) $this->amount, 2),
            'category' => $this->category,
            // Stored as a plain date; SQLite and PostgreSQL both return it with a Y-m-d prefix.
            'occurred_on' => substr((string) $this->occurred_on, 0, 10),
            'note' => $this->note,
            'created_at' => $this->created_at->utc()->format(self::TIMESTAMP_FORMAT),
            'updated_at' => $this->updated_at->utc()->format(self::TIMESTAMP_FORMAT),
        ];
    }
}
