<?php

namespace App\Support;

use RuntimeException;

/**
 * Holds the authenticated user's id for the current request.
 * Only the JWT middleware sets it, and only from the token's `sub` claim.
 */
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
