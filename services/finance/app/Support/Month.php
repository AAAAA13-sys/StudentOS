<?php

namespace App\Support;

use Carbon\CarbonImmutable;

/**
 * A calendar month expressed as a half-open date range [start, end),
 * so filtering is the same indexable comparison on PostgreSQL and SQLite.
 */
final class Month
{
    public const PATTERN = '/^(19|2\d)\d{2}-(0[1-9]|1[0-2])$/';

    private function __construct(
        public readonly string $label,
        public readonly string $start,
        public readonly string $end,
    ) {}

    public static function fromLabel(string $label): self
    {
        $first = CarbonImmutable::createFromFormat('!Y-m-d', $label.'-01', 'UTC');

        return new self($label, $first->format('Y-m-d'), $first->addMonthNoOverflow()->format('Y-m-d'));
    }

    public static function current(): self
    {
        return self::fromLabel(CarbonImmutable::now('UTC')->format('Y-m'));
    }
}
