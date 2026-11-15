<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class HttpConventionsTest extends TestCase
{
    use RefreshDatabase;

    public function test_health_is_public_and_reports_ok(): void
    {
        $this->get('/api/finance/health')
            ->assertOk()
            ->assertExactJson(['status' => 'ok', 'service' => 'finance']);
    }

    public function test_health_reports_degraded_when_the_database_is_unreachable(): void
    {
        DB::shouldReceive('select')->once()->andThrow(new \RuntimeException('connection refused'));

        $this->get('/api/finance/health')
            ->assertStatus(503)
            ->assertExactJson(['status' => 'degraded', 'service' => 'finance']);
    }

    public function test_unknown_route_returns_json_404_even_without_accept_header(): void
    {
        $this->get('/api/finance/nope')
            ->assertNotFound()
            ->assertHeader('Content-Type', 'application/json')
            ->assertExactJson(['message' => 'Not found.']);

        $this->get('/')->assertNotFound()->assertExactJson(['message' => 'Not found.']);
    }

    public function test_non_numeric_id_is_not_found(): void
    {
        $this->as(self::USER_A)->getJson('/api/finance/transactions/abc')
            ->assertNotFound()
            ->assertExactJson(['message' => 'Not found.']);
    }

    public function test_categories_returns_the_seven_contract_strings(): void
    {
        $this->as(self::USER_A)->getJson('/api/finance/categories')
            ->assertOk()
            ->assertExactJson(['data' => [
                'Food', 'Transport', 'School', 'Entertainment', 'Allowance', 'Part-time Job', 'Other',
            ]]);
    }

    public function test_protected_routes_reject_a_missing_token(): void
    {
        foreach ([
            ['GET', '/api/finance/categories'],
            ['GET', '/api/finance/transactions'],
            ['POST', '/api/finance/transactions'],
            ['GET', '/api/finance/transactions/1'],
            ['PUT', '/api/finance/transactions/1'],
            ['DELETE', '/api/finance/transactions/1'],
            ['GET', '/api/finance/summary'],
        ] as [$method, $uri]) {
            $this->json($method, $uri)
                ->assertUnauthorized()
                ->assertExactJson(['message' => 'Unauthenticated.']);
        }
    }

    public function test_bad_tokens_are_rejected(): void
    {
        $bad = [
            'garbage' => 'not-a-jwt',
            'wrong secret' => $this->tokenFor(self::USER_A, [], 'another-secret-another-secret-0123456789'),
            'expired' => $this->tokenFor(self::USER_A, ['iat' => time() - 7200, 'exp' => time() - 3600]),
            'wrong issuer' => $this->tokenFor(self::USER_A, ['iss' => 'someone-else']),
            'non-numeric sub' => $this->tokenFor(self::USER_A, ['sub' => 'abc']),
        ];

        foreach ($bad as $label => $token) {
            $response = $this->withHeader('Authorization', 'Bearer '.$token)->getJson('/api/finance/transactions');

            $this->assertSame(401, $response->status(), "Token case [{$label}] was not rejected.");
            $response->assertExactJson(['message' => 'Unauthenticated.']);
        }
    }

    public function test_a_short_secret_is_refused_instead_of_accepting_tokens(): void
    {
        $short = 'too-short';
        $token = $this->tokenFor(self::USER_A, [], $short);
        config(['jwt.secret' => $short]);

        $response = $this->withHeader('Authorization', 'Bearer '.$token)->getJson('/api/finance/transactions');

        $response->assertStatus(500)->assertExactJson(['message' => 'Server Error']);
    }
}
