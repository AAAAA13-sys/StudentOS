<?php

namespace App\Gateway;

use Illuminate\Http\JsonResponse;

/** The gateway's own error bodies: always JSON, never a stack trace. */
final class JsonError
{
    public static function make(int $status, string $message, array $headers = []): JsonResponse
    {
        return response()->json(['message' => $message], $status, $headers);
    }

    public static function notFound(): JsonResponse
    {
        return self::make(404, 'Not found.');
    }

    public static function unauthenticated(): JsonResponse
    {
        return self::make(401, 'Unauthenticated.');
    }

    public static function serverError(): JsonResponse
    {
        return self::make(500, 'Server error.');
    }

    public static function unavailable(): JsonResponse
    {
        return self::make(502, 'Service unavailable.');
    }
}
