<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

/**
 * Assigns the request id and writes one access line per request.
 *
 * The line holds method, path (no query string), status, duration, user id
 * and request id. It never holds a body, a token, or any header value other
 * than a validated request id.
 */
class AccessLog
{
    public const REQUEST_ID = 'gateway.request_id';

    public const USER_ID = 'gateway.user_id';

    public function handle(Request $request, Closure $next): Response
    {
        $startedAt = hrtime(true);

        $requestId = $this->requestId($request);
        $request->attributes->set(self::REQUEST_ID, $requestId);

        $response = $next($request);

        $response->headers->set('X-Request-Id', $requestId);

        Log::info(sprintf(
            'access method=%s path=%s status=%d duration_ms=%d user=%s request_id=%s',
            $request->method(),
            $this->loggablePath($request),
            $response->getStatusCode(),
            intdiv(hrtime(true) - $startedAt, 1_000_000),
            $request->attributes->get(self::USER_ID, '-'),
            $requestId,
        ));

        return $response;
    }

    /** A client-supplied id is kept only if it cannot break the log line. */
    private function requestId(Request $request): string
    {
        $supplied = $request->headers->get('X-Request-Id');

        if (is_string($supplied) && preg_match('/\A[A-Za-z0-9._-]{1,64}\z/', $supplied) === 1) {
            return $supplied;
        }

        return (string) Str::uuid();
    }

    /**
     * The still percent-encoded path, so it cannot carry spaces or newlines.
     * Braces are replaced because the log channel interpolates {placeholders}.
     */
    private function loggablePath(Request $request): string
    {
        $path = (string) preg_replace('/[^\x21-\x7A|~]/', '?', $request->getPathInfo());

        return strlen($path) > 200 ? substr($path, 0, 200).'...' : $path;
    }
}
