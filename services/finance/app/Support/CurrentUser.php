<?php

namespace App\Support;

use LogicException;

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
            throw new LogicException('No authenticated user is set for this request.');
        }

        return $this->id;
    }
}
