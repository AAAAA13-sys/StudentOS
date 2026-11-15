<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class HealthController extends Controller
{
    public function __invoke(): JsonResponse
    {
        try {
            DB::select('SELECT 1');
        } catch (Throwable $e) {
            Log::error('Health check: database unreachable.', ['exception' => $e::class]);

            return response()->json(['status' => 'degraded', 'service' => 'calendar'], 503);
        }

        return response()->json(['status' => 'ok', 'service' => 'calendar']);
    }
}
