<?php

namespace App\Support;

use RuntimeException;

class CurrentUser
{
    private ?int $id = null;

    public function set(int $id): void
    {
        $this->id = $id;
    }

    public function id(): ?int
    {
        return $this->id;
    }

    public function idOrFail(): int
    {
        if ($this->id === null) {
            throw new RuntimeException('No authenticated user for this request.');
        }

        return $this->id;
    }
}
