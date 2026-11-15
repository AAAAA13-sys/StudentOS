<?php

namespace App\Support;

use InvalidArgumentException;

/**
 * Exact two-decimal arithmetic on decimal strings such as "1320.50".
 * Uses bcmath when the extension is loaded, integer cents otherwise.
 */
final class Money
{
    /**
     * Turn a value read from the database or validated input into a
     * canonical two-decimal string.
     */
    public static function normalise(mixed $value): string
    {
        if (is_int($value)) {
            return $value.'.00';
        }

        if (is_string($value) && preg_match('/^(-?\d+)(?:\.(\d{1,2}))?$/', $value, $m) === 1) {
            return $m[1].'.'.str_pad($m[2] ?? '', 2, '0');
        }

        if (is_numeric($value)) {
            return sprintf('%.2F', (float) $value);
        }

        throw new InvalidArgumentException('Value is not a decimal amount.');
    }

    public static function add(string $a, string $b): string
    {
        return function_exists('bcadd')
            ? bcadd($a, $b, 2)
            : self::addWithCents($a, $b);
    }

    public static function subtract(string $a, string $b): string
    {
        return function_exists('bcsub')
            ? bcsub($a, $b, 2)
            : self::subtractWithCents($a, $b);
    }

    public static function addWithCents(string $a, string $b): string
    {
        return self::fromCents(self::toCents($a) + self::toCents($b));
    }

    public static function subtractWithCents(string $a, string $b): string
    {
        return self::fromCents(self::toCents($a) - self::toCents($b));
    }

    /** JSON number for a canonical two-decimal string. */
    public static function toNumber(string $amount): float
    {
        return round((float) $amount, 2);
    }

    private static function toCents(string $amount): int
    {
        return (int) str_replace('.', '', self::normalise($amount));
    }

    private static function fromCents(int $cents): string
    {
        $abs = abs($cents);

        return sprintf('%s%d.%02d', $cents < 0 ? '-' : '', intdiv($abs, 100), $abs % 100);
    }
}
