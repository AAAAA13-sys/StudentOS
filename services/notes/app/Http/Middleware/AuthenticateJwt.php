<?php

namespace App\Http\Middleware;

use App\Support\CurrentUser;
use Closure;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Http\Request;
use RuntimeException;
use Symfony\Component\HttpFoundation\Response;

class AuthenticateJwt
{
    private const MIN_SECRET_LENGTH = 32;

    public function handle(Request $request, Closure $next): Response
    {
        $secret = (string) config('jwt.secret');
        if (strlen($secret) < self::MIN_SECRET_LENGTH) {
            // A missing or weak secret must never accept tokens: fail the request (500).
            throw new RuntimeException('JWT_SECRET is not configured or is shorter than 32 characters.');
        }

        $token = $request->bearerToken();
        if (! $token) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }
        try {
            $claims = JWT::decode($token, new Key($secret, 'HS256'));
        } catch (\Throwable $e) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }
        if (($claims->iss ?? null) !== 'studentos-auth' || ! ctype_digit((string) ($claims->sub ?? ''))) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }
        app(CurrentUser::class)->set((int) $claims->sub);

        return $next($request);
    }
}
