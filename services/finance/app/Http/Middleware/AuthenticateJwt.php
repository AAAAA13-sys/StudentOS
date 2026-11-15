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
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();
        if (! $token) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        $secret = config('jwt.secret');
        if (! is_string($secret) || strlen($secret) < (int) config('jwt.min_secret_length', 32)) {
            throw new RuntimeException('JWT_SECRET is missing or shorter than 32 characters; refusing to validate tokens.');
        }

        try {
            $claims = JWT::decode($token, new Key($secret, 'HS256'));
        } catch (\Throwable $e) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        if (($claims->iss ?? null) !== config('jwt.issuer') || ! ctype_digit((string) ($claims->sub ?? ''))) {
            return response()->json(['message' => 'Unauthenticated.'], 401);
        }

        app(CurrentUser::class)->set((int) $claims->sub);

        return $next($request);
    }
}
