<?php

namespace Tests;

use Firebase\JWT\JWT;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Illuminate\Testing\TestResponse;

abstract class TestCase extends BaseTestCase
{
    protected const USER_A = 1;

    protected const USER_B = 2;

    /** Mint a token the way the Auth Service does (CONTRACT section 3). */
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

    protected function as(int $userId): static
    {
        return $this->withHeader('Authorization', 'Bearer '.$this->tokenFor($userId));
    }

    protected function createTransaction(int $userId, array $overrides = []): TestResponse
    {
        return $this->as($userId)->postJson('/api/finance/transactions', array_merge([
            'type' => 'expense',
            'amount' => 120.50,
            'category' => 'Food',
            'occurred_on' => '2026-11-15',
            'note' => 'Lunch',
        ], $overrides));
    }
}
