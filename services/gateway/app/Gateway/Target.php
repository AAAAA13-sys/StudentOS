<?php

namespace App\Gateway;

/**
 * Where a request goes: one of the configured services and the exact path
 * that is both checked against the public allowlist and sent upstream.
 */
final class Target
{
    public function __construct(
        public readonly string $service,
        public readonly string $path,
        public readonly bool $isPublic,
    ) {}
}
