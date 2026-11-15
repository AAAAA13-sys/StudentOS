<?php

namespace App\Http\Controllers;

use App\Http\Resources\UserResource;
use App\Models\User;
use App\Support\CurrentUser;
use Firebase\JWT\JWT;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use RuntimeException;

class AuthController extends Controller
{
    private const MIN_SECRET_LENGTH = 32;

    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
        ]);

        $user = new User();
        $user->name = $data['name'];
        $user->email = strtolower(trim($data['email']));
        $user->password = Hash::make($data['password']);
        $user->save();

        $token = $this->issueToken($user);

        return response()->json([
            'user' => UserResource::make($user)->resolve($request),
            'token' => $token,
        ], 201);
    }

    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ]);

        $email = strtolower(trim($data['email']));
        $user = User::query()->where('email', $email)->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            return response()->json(['message' => 'Invalid credentials.'], 401);
        }

        $token = $this->issueToken($user);

        return response()->json([
            'user' => UserResource::make($user)->resolve($request),
            'token' => $token,
        ], 200);
    }

    public function me(Request $request): JsonResponse
    {
        $userId = app(CurrentUser::class)->idOrFail();
        $user = User::query()->findOrFail($userId);

        return response()->json([
            'user' => UserResource::make($user)->resolve($request),
        ], 200);
    }

    public function logout(): Response
    {
        return response()->noContent();
    }

    private function issueToken(User $user): string
    {
        $secret = (string) config('jwt.secret');
        if (strlen($secret) < self::MIN_SECRET_LENGTH) {
            throw new RuntimeException('JWT_SECRET is not configured or is shorter than 32 characters.');
        }

        $now = time();
        $ttl = (int) config('jwt.ttl_days', 7) * 86400;

        $payload = [
            'iss' => 'studentos-auth',
            'sub' => (string) $user->id,
            'email' => (string) $user->email,
            'name' => (string) $user->name,
            'iat' => $now,
            'exp' => $now + $ttl,
        ];

        return JWT::encode($payload, $secret, 'HS256');
    }
}
