<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class HealthAndAuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_health_is_public_and_reports_ok(): void
    {
        $this->get('/api/notes/health')
            ->assertOk()
            ->assertExactJson(['status' => 'ok', 'service' => 'notes']);
    }

    public function test_health_reports_degraded_when_the_database_is_down(): void
    {
        DB::shouldReceive('select')->once()->andThrow(new \RuntimeException('connection refused'));

        $this->get('/api/notes/health')
            ->assertStatus(503)
            ->assertExactJson(['status' => 'degraded', 'service' => 'notes']);
    }

    public function test_requests_without_a_token_are_rejected(): void
    {
        foreach ([['GET', '/api/notes'], ['POST', '/api/notes'], ['GET', '/api/notes/1'],
            ['PUT', '/api/notes/1'], ['DELETE', '/api/notes/1'], ['GET', '/api/notes/tags']] as [$method, $uri]) {
            $this->call($method, $uri)
                ->assertStatus(401)
                ->assertExactJson(['message' => 'Unauthenticated.']);
        }
    }

    public function test_malformed_token_is_rejected(): void
    {
        $this->withHeader('Authorization', 'Bearer not-a-jwt')
            ->get('/api/notes')
            ->assertStatus(401)
            ->assertExactJson(['message' => 'Unauthenticated.']);
    }

    public function test_token_signed_with_another_secret_is_rejected(): void
    {
        $token = $this->tokenFor(1, [], 'a-different-secret-a-different-secret-000');

        $this->withHeader('Authorization', 'Bearer '.$token)->get('/api/notes')->assertStatus(401);
    }

    public function test_expired_token_is_rejected(): void
    {
        $token = $this->tokenFor(1, ['iat' => time() - 7200, 'exp' => time() - 3600]);

        $this->withHeader('Authorization', 'Bearer '.$token)->get('/api/notes')->assertStatus(401);
    }

    public function test_token_from_another_issuer_is_rejected(): void
    {
        $token = $this->tokenFor(1, ['iss' => 'someone-else']);

        $this->withHeader('Authorization', 'Bearer '.$token)->get('/api/notes')->assertStatus(401);
    }

    public function test_token_with_a_non_numeric_subject_is_rejected(): void
    {
        $token = $this->tokenFor(1, ['sub' => 'abc']);

        $this->withHeader('Authorization', 'Bearer '.$token)->get('/api/notes')->assertStatus(401);
    }

    public function test_tokens_are_refused_when_the_secret_is_missing_or_short(): void
    {
        $token = $this->tokenFor(1);

        foreach (['', 'too-short'] as $secret) {
            config(['jwt.secret' => $secret]);

            $this->withHeader('Authorization', 'Bearer '.$token)
                ->get('/api/notes')
                ->assertStatus(500)
                ->assertExactJson(['message' => 'Server Error']);
        }
    }

    public function test_unknown_routes_return_json_404(): void
    {
        $this->get('/')->assertStatus(404)->assertExactJson(['message' => 'Not found.']);
        $this->get('/api/nope')->assertStatus(404)->assertExactJson(['message' => 'Not found.']);
        $this->asUser(1)->get('/api/notes/abc')->assertStatus(404)->assertExactJson(['message' => 'Not found.']);
    }
}
