<?php

namespace App\Services;

use App\Models\Event;
use Carbon\CarbonImmutable;
use Illuminate\Database\Eloquent\Builder;

/**
 * Turns stored events into concrete occurrences inside a time window.
 * All queries go through Event's tenant scope.
 */
class OccurrenceFinder
{
    public const MAX_WINDOW_DAYS = 366;

    public function __construct(private readonly RecurrenceExpander $expander) {}

    /**
     * Every occurrence with $from <= start < $to, ordered by start then event id.
     *
     * @return list<array{event: Event, start: CarbonImmutable}>
     */
    public function between(CarbonImmutable $from, CarbonImmutable $to): array
    {
        $occurrences = [];

        $candidates = Event::query()
            ->where('starts_at', '<', $to)
            ->where(function (Builder $query) use ($from): void {
                $query->where('starts_at', '>=', $from)
                    ->orWhere(fn (Builder $recurring) => $this->stillRecurring($recurring, $from));
            })
            ->orderBy('starts_at')
            ->orderBy('id')
            ->get();

        foreach ($candidates as $event) {
            foreach ($this->expand($event, $from, $to) as $start) {
                $occurrences[] = ['event' => $event, 'start' => $start];
            }
        }

        usort($occurrences, fn (array $a, array $b): int => [$a['start']->getTimestamp(), $a['event']->id]
            <=> [$b['start']->getTimestamp(), $b['event']->id]);

        return $occurrences;
    }

    /**
     * The earliest occurrence starting at or after $now, looking ahead MAX_WINDOW_DAYS.
     *
     * @return array{event: Event, start: CarbonImmutable}|null
     */
    public function next(CarbonImmutable $now): ?array
    {
        $to = $now->addDays(self::MAX_WINDOW_DAYS);

        $single = Event::query()
            ->where('recurrence', RecurrenceExpander::NONE)
            ->where('starts_at', '>=', $now)
            ->where('starts_at', '<', $to)
            ->orderBy('starts_at')
            ->orderBy('id')
            ->first();

        $best = $single ? ['event' => $single, 'start' => $single->starts_at] : null;

        $recurring = Event::query()
            ->where('starts_at', '<', $to)
            ->where(fn (Builder $query) => $this->stillRecurring($query, $now))
            ->orderBy('id')
            ->get();

        foreach ($recurring as $event) {
            $start = $this->expand($event, $now, $to, 1)[0] ?? null;

            if ($start !== null && ($best === null || $start < $best['start'])) {
                $best = ['event' => $event, 'start' => $start];
            }
        }

        return $best;
    }

    /** Recurring events whose series has not ended before the day of $from. */
    private function stillRecurring(Builder $query, CarbonImmutable $from): void
    {
        $query->where('recurrence', '!=', RecurrenceExpander::NONE)
            ->where(function (Builder $until) use ($from): void {
                $until->whereNull('recurrence_until')
                    ->orWhere('recurrence_until', '>=', $from->format('Y-m-d'));
            });
    }

    /** @return list<CarbonImmutable> */
    private function expand(Event $event, CarbonImmutable $from, CarbonImmutable $to, ?int $limit = null): array
    {
        return $this->expander->expand(
            $event->starts_at,
            $event->recurrence,
            $event->recurrence_until,
            $from,
            $to,
            $limit,
        );
    }
}
