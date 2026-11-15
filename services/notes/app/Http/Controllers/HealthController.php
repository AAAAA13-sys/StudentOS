<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class HealthController extends Controller
{
    public function __invoke(): JsonResponse
    {
        try {
            DB::select('SELECT 1');
        } catch (\Throwable $e) {
            report($e);

            return response()->json(['status' => 'degraded', 'service' => 'notes'], 503);
        }

        return response()->json(['status' => 'ok', 'service' => 'notes']);
    }
}
