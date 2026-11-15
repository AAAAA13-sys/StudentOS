<?php

namespace Tests;

use Firebase\JWT\JWT;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    /**
     * Mint a token the way the Auth Service does (CONTRACT section 3).
     *
     * @param  array<string, mixed>  $overrides
     */
    protected function tokenFor(int $userId, array $overrides = [], ?string $secret = null): string
    {
        $claims = array_merge([
            'iss' => 'studentos-auth',
            'sub' => (string) $userId,
            'email' => "user{$userId}@example.com",
            'name' => "User {$userId}",
            'iat' => time(),
            'exp' => time() + 3600,
        ], $overrides);

        return JWT::encode($claims, $secret ?? config('jwt.secret'), 'HS256');
    }

    /** Send the following requests as the given user. */
    protected function asUser(int $userId): static
    {
        return $this->withHeader('Authorization', 'Bearer '.$this->tokenFor($userId));
    }
}
