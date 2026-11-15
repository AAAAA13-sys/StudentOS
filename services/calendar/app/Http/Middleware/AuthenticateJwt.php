<?php

namespace App\Http\Middleware;

use Closure;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
use Illuminate\Http\Request;
use RuntimeException;
use Symfony\Component\HttpFoundation\Response;

class AuthenticateJwt
{
    public function handle(Request $request, Closure $next): Response
    {
        $secret = (string) config('jwt.secret');
        if (strlen($secret) < (int) config('jwt.min_secret_length', 32)) {
            // Fail closed with a 500: a weak or missing secret must never validate tokens.
            throw new RuntimeException('JWT_SECRET is missing or shorter than 32 characters.');
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
        app(\App\Support\CurrentUser::class)->set((int) $claims->sub);

        return $next($request);
    }
}
