<?php

namespace App\Http\Middleware;

use App\Gateway\JsonError;
use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Symfony\Component\HttpFoundation\Response;

/** Limits POST /api/auth/login and POST /api/auth/register per client IP. */
class ThrottleAuthEntry
{
    private const THROTTLED_PATHS = ['/api/auth/login', '/api/auth/register'];

    public function handle(Request $request, Closure $next): Response
    {
        $target = $request->attributes->get(ResolveTarget::TARGET);

        if ($request->method() !== 'POST' || ! in_array($target->path, self::THROTTLED_PATHS, true)) {
            return $next($request);
        }

        $key = 'auth-entry|'.$target->path.'|'.$request->ip();
        $maxAttempts = (int) config('gateway.auth_throttle.max_attempts');

        if (RateLimiter::tooManyAttempts($key, $maxAttempts)) {
            return JsonError::make(429, 'Too many requests.', [
                'Retry-After' => RateLimiter::availableIn($key),
            ]);
        }

        RateLimiter::hit($key, (int) config('gateway.auth_throttle.decay_seconds'));

        return $next($request);
    }
}
