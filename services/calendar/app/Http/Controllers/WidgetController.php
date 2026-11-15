<?php

namespace App\Http\Controllers;

use App\Services\OccurrenceFinder;
use App\Support\IsoDateTime;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;

class WidgetController extends Controller
{
    public function __invoke(OccurrenceFinder $finder): JsonResponse
    {
        $next = $finder->next(CarbonImmutable::now('UTC')->startOfSecond());

        return response()->json([
            'next_event' => $next === null ? null : [
                'id' => $next['event']->id,
                'title' => $next['event']->title,
                'starts_at' => IsoDateTime::format($next['start']),
                'location' => $next['event']->location,
            ],
        ]);
    }
}
