<?php

namespace App\Gateway;

use Illuminate\Http\Request;

/**
 * Turns the path Laravel routed on into a Target, or null when the request
 * must not be forwarded at all.
 *
 * The allowlist decision and the upstream path are derived from the same
 * normalised string, so a request can never be judged public under one
 * spelling and forwarded under another.
 */
final class TargetResolver
{
    /** Exact "METHOD path" pairs that need no JWT, besides the health checks. */
    private const PUBLIC_ROUTES = [
        'POST /api/auth/register',
        'POST /api/auth/login',
    ];

    public function resolve(Request $request): ?Target
    {
        // Same string the router matches on: percent-decoded once, with
        // leading and trailing slashes trimmed.
        $decoded = $request->decodedPath();

        if (! mb_check_encoding($decoded, 'UTF-8')) {
            return null;
        }

        $segments = explode('/', $decoded);

        if (count($segments) < 2 || $segments[0] !== 'api') {
            return null;
        }

        $service = $segments[1];

        if (! in_array($service, $this->services(), true)) {
            return null;
        }

        foreach ($segments as $segment) {
            if (! $this->isSafeSegment($segment)) {
                return null;
            }
        }

        $path = '/'.implode('/', array_map('rawurlencode', $segments));

        return new Target($service, $path, $this->isPublic($request->method(), $path, $service));
    }

    /** @return list<string> */
    private function services(): array
    {
        return array_keys(config('services.upstreams', []));
    }

    /**
     * Rejects anything a downstream parser could reinterpret as a different
     * path: empty segments ("//"), dot segments, backslashes, control bytes.
     */
    private function isSafeSegment(string $segment): bool
    {
        if ($segment === '' || $segment === '.' || $segment === '..') {
            return false;
        }

        return preg_match('/[\\\\\x00-\x1F\x7F]/', $segment) !== 1;
    }

    private function isPublic(string $method, string $path, string $service): bool
    {
        if ($method === 'GET' && $path === "/api/{$service}/health") {
            return true;
        }

        return in_array("{$method} {$path}", self::PUBLIC_ROUTES, true);
    }
}
