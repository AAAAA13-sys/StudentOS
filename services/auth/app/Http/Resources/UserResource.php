<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => (int) $this->id,
            'name' => (string) $this->name,
            'email' => (string) $this->email,
            'created_at' => $this->created_at?->toIso8601ZuluString() ?? $this->created_at?->format('Y-m-d\TH:i:s\Z'),
        ];
    }
}
