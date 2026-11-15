<?php

namespace App\Http\Controllers;

use App\Http\Resources\EventResource;
use App\Models\Event;
use App\Rules\IsoDateTimeRule;
use App\Services\OccurrenceFinder;
use App\Services\RecurrenceExpander;
use App\Support\IsoDateTime;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class EventController extends Controller
{
    public function index(Request $request, OccurrenceFinder $finder): JsonResponse
    {
        if (! $request->has('from') && ! $request->has('to')) {
            $events = Event::query()->orderBy('starts_at')->orderBy('id')->get();

            return response()->json(['data' => EventResource::collection($events)->resolve($request)]);
        }

        $range = $request->validate([
            'from' => ['bail', 'required', new IsoDateTimeRule],
            'to' => ['bail', 'required', new IsoDateTimeRule],
        ]);

        $from = IsoDateTime::parse($range['from']);
        $to = IsoDateTime::parse($range['to']);

        if ($to <= $from) {
            throw ValidationException::withMessages(['to' => ['The to field must be after from.']]);
        }
        if ($to->getTimestamp() - $from->getTimestamp() > OccurrenceFinder::MAX_WINDOW_DAYS * 86400) {
            throw ValidationException::withMessages([
                'to' => ['The range between from and to must not exceed '.OccurrenceFinder::MAX_WINDOW_DAYS.' days.'],
            ]);
        }

        $data = array_map(
            fn (array $occurrence): array => EventResource::make($occurrence['event'])->resolve($request)
                + ['occurrence_start' => IsoDateTime::format($occurrence['start'])],
            $finder->between($from, $to),
        );

        return response()->json(['data' => $data]);
    }

    public function store(Request $request): JsonResponse
    {
        $event = new Event($this->attributes($request, null));
        $event->save();

        return $this->respond($request, $event, 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        return $this->respond($request, Event::query()->findOrFail((int) $id));
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $event = Event::query()->findOrFail((int) $id);
        $event->fill($this->attributes($request, $event));
        $event->save();

        return $this->respond($request, $event);
    }

    public function destroy(string $id): Response
    {
        Event::query()->findOrFail((int) $id)->delete();

        return response()->noContent();
    }

    private function respond(Request $request, Event $event, int $status = 200): JsonResponse
    {
        return response()->json(['data' => EventResource::make($event)->resolve($request)], $status);
    }

    /**
     * Validated, normalised attributes. With an existing event the update is
     * partial: only the fields present in the request are validated and changed.
     *
     * @return array<string, mixed>
     */
    private function attributes(Request $request, ?Event $existing): array
    {
        $partial = $existing !== null;
        $required = $partial ? ['sometimes', 'required'] : ['required'];
        $defaulted = $partial ? ['sometimes', 'required'] : ['nullable'];
        $optional = $partial ? ['sometimes', 'nullable'] : ['nullable'];

        $data = $request->validate([
            'title' => [...$required, 'string', 'max:150'],
            'starts_at' => ['bail', ...$required, new IsoDateTimeRule],
            'duration_minutes' => [...$defaulted, 'integer', 'between:1,1440'],
            'location' => [...$optional, 'string', 'max:150'],
            'notes' => [...$optional, 'string', 'max:5000'],
            'recurrence' => [...$defaulted, 'string', Rule::in(RecurrenceExpander::RECURRENCES)],
            'recurrence_until' => [...$optional, 'date_format:Y-m-d'],
            'reminder_minutes' => [...$optional, 'integer', 'between:0,10080'],
        ]);

        if (array_key_exists('starts_at', $data)) {
            $data['starts_at'] = IsoDateTime::parse($data['starts_at']);
        }
        foreach (['duration_minutes', 'reminder_minutes'] as $integer) {
            if (isset($data[$integer])) {
                $data[$integer] = (int) $data[$integer];
            }
        }
        if (! $partial) {
            $data['duration_minutes'] ??= Event::DEFAULT_DURATION_MINUTES;
            $data['recurrence'] ??= RecurrenceExpander::NONE;
        }

        // Cross-field rules are checked against the event as it will be stored.
        $startsAt = $data['starts_at'] ?? $existing?->starts_at;
        $recurrence = $data['recurrence'] ?? $existing?->recurrence;
        $until = array_key_exists('recurrence_until', $data)
            ? $data['recurrence_until']
            : $existing?->recurrence_until?->format('Y-m-d');

        if ($recurrence === RecurrenceExpander::NONE) {
            $data['recurrence_until'] = null;
        } elseif ($until !== null && $until < $startsAt->format('Y-m-d')) {
            throw ValidationException::withMessages([
                'recurrence_until' => ['The recurrence until field must be on or after the date of starts at.'],
            ]);
        }

        return $data;
    }
}
