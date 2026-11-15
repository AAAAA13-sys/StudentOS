<?php

namespace App\Support;

use Carbon\CarbonImmutable;
use DateTimeInterface;

/**
 * Strict ISO-8601 datetime parsing. Offsets are honoured and the result is
 * always UTC with whole seconds; a value without an offset is read as UTC.
 */
final class IsoDateTime
{
    private const PATTERN = '/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})(?::(\d{2})(?:\.\d{1,9})?)?(Z|[+-]\d{2}:?\d{2})?$/';

    public static function parse(mixed $value): ?CarbonImmutable
    {
        if (! is_string($value) || ! preg_match(self::PATTERN, $value, $m)) {
            return null;
        }

        [$year, $month, $day, $hour, $minute] = array_map('intval', array_slice($m, 1, 5));
        $second = (int) ($m[6] ?? 0);
        $offset = $m[7] ?? '';

        if (! checkdate($month, $day, $year) || $hour > 23 || $minute > 59 || $second > 59) {
            return null;
        }

        $offsetSeconds = 0;
        if ($offset !== '' && $offset !== 'Z') {
            $digits = str_replace(':', '', substr($offset, 1));
            $offsetHours = (int) substr($digits, 0, 2);
            $offsetMinutes = (int) substr($digits, 2, 2);
            if ($offsetHours > 14 || $offsetMinutes > 59) {
                return null;
            }
            $offsetSeconds = ($offsetHours * 3600 + $offsetMinutes * 60) * ($offset[0] === '-' ? -1 : 1);
        }

        return CarbonImmutable::create($year, $month, $day, $hour, $minute, $second, 'UTC')
            ->subSeconds($offsetSeconds);
    }

    public static function format(DateTimeInterface $value): string
    {
        return CarbonImmutable::instance($value)->utc()->format('Y-m-d\TH:i:s\Z');
    }
}
