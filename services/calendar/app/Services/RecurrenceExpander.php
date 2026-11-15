<?php

namespace App\Services;

use Carbon\CarbonImmutable;
use DateTimeInterface;

/**
 * Pure recurrence arithmetic, always in UTC.
 *
 * Occurrence n is computed from the base start (never chained), so a monthly
 * event on the 31st yields Jan 31, Feb 28/29, Mar 31 rather than drifting.
 */
final class RecurrenceExpander
{
    public const NONE = 'none';

    public const DAILY = 'daily';

    public const WEEKLY = 'weekly';

    public const MONTHLY = 'monthly';

    public const RECURRENCES = [self::NONE, self::DAILY, self::WEEKLY, self::MONTHLY];

    /** Hard ceiling on occurrences produced by one call, whatever the window. */
    public const MAX_OCCURRENCES = 1000;

    private const DAY_SECONDS = 86400;

    /**
     * Occurrence starts with $from <= start < $to, ascending.
     *
     * @param  DateTimeInterface|null  $until  inclusive last day (UTC calendar date); ignored for non-recurring events
     * @param  int|null  $limit  stop after this many occurrences
     * @return list<CarbonImmutable>
     */
    public function expand(
        DateTimeInterface $start,
        string $recurrence,
        ?DateTimeInterface $until,
        DateTimeInterface $from,
        DateTimeInterface $to,
        ?int $limit = null,
    ): array {
        $start = CarbonImmutable::instance($start)->utc();
        $from = CarbonImmutable::instance($from)->utc();
        $to = CarbonImmutable::instance($to)->utc();

        if ($to <= $from) {
            return [];
        }

        if (! in_array($recurrence, [self::DAILY, self::WEEKLY, self::MONTHLY], true)) {
            return $start >= $from && $start < $to ? [$start] : [];
        }

        $max = min($limit ?? self::MAX_OCCURRENCES, self::MAX_OCCURRENCES);
        $lastAllowed = $until === null
            ? null
            : CarbonImmutable::parse($until->format('Y-m-d').' 23:59:59', 'UTC');

        $occurrences = [];
        for ($n = $this->firstIndex($start, $recurrence, $from); count($occurrences) < $max; $n++) {
            $occurrence = $this->occurrence($start, $recurrence, $n);

            if ($occurrence >= $to || ($lastAllowed !== null && $occurrence > $lastAllowed)) {
                break;
            }
            if ($occurrence >= $from) {
                $occurrences[] = $occurrence;
            }
        }

        return $occurrences;
    }

    private function occurrence(CarbonImmutable $start, string $recurrence, int $n): CarbonImmutable
    {
        return match ($recurrence) {
            self::DAILY => $start->addDays($n),
            self::WEEKLY => $start->addWeeks($n),
            default => $start->addMonthsNoOverflow($n),
        };
    }

    /**
     * Index of the first occurrence that can be >= $from, found arithmetically
     * so an event that started years ago costs no extra iterations.
     */
    private function firstIndex(CarbonImmutable $start, string $recurrence, CarbonImmutable $from): int
    {
        if ($from <= $start) {
            return 0;
        }

        if ($recurrence === self::MONTHLY) {
            $months = ($from->year - $start->year) * 12 + ($from->month - $start->month);

            // One month early: the day-of-month/time may fall before $from's; the loop skips it.
            return max(0, $months - 1);
        }

        $step = $recurrence === self::WEEKLY ? 7 * self::DAY_SECONDS : self::DAY_SECONDS;

        return intdiv($from->getTimestamp() - $start->getTimestamp() + $step - 1, $step);
    }
}
