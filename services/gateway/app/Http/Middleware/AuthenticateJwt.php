<?php

namespace App\Http\Middleware;

use App\Gateway\JsonError;
use Closure;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

/**
 * Requires a valid StudentOS JWT on every target that is not on the public
 * allowlist. A request that fails here is answered by the gateway and is
 * never sent upstream.
 */
class AuthenticateJwt
{
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->attributes->get(ResolveTarget::TARGET)->isPublic) {
            return $next($request);
        }

        $secret = (string) config('jwt.secret');

        if (strlen($secret) < (int) config('jwt.min_secret_length')) {
            Log::error('JWT_SECRET is missing or shorter than the required minimum; refusing to authenticate.');

            return JsonError::serverError();
        }

        $token = $request->bearerToken();

        if (! $token) {
            return JsonError::unauthenticated();
        }

        try {
            $claims = JWT::decode($token, new Key($secret, 'HS256'));
        } catch (\Throwable) {
            return JsonError::unauthenticated();
        }

        $subject = $claims->sub ?? null;

        if (($claims->iss ?? null) !== config('jwt.issuer')
            || ! is_numeric($claims->exp ?? null)
            || ! (is_string($subject) || is_int($subject))
            || ! ctype_digit((string) $subject)) {
            return JsonError::unauthenticated();
        }

        $request->attributes->set(AccessLog::USER_ID, (string) $subject);

        return $next($request);
    }
}
