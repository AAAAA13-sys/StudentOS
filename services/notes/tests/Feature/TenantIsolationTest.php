<?php

namespace Tests\Feature;

use App\Models\Note;
use App\Models\NoteTag;
use App\Support\CurrentUser;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TenantIsolationTest extends TestCase
{
    use RefreshDatabase;

    private int $noteOfA;

    protected function setUp(): void
    {
        parent::setUp();

        $this->noteOfA = $this->asUser(1)->postJson('/api/notes', [
            'title' => 'Secret plan',
            'body' => 'keyword-alpha inside',
            'tags' => ['private', 'shared-name'],
        ])->assertStatus(201)->json('data.id');
    }

    public function test_user_b_cannot_read_user_a_note(): void
    {
        $this->asUser(2)->getJson("/api/notes/{$this->noteOfA}")
            ->assertStatus(404)
            ->assertExactJson(['message' => 'Not found.']);
    }

    public function test_user_b_cannot_update_user_a_note(): void
    {
        $this->asUser(2)->putJson("/api/notes/{$this->noteOfA}", ['title' => 'Hijacked', 'tags' => ['pwned']])
            ->assertStatus(404)
            ->assertExactJson(['message' => 'Not found.']);

        $this->asUser(1)->getJson("/api/notes/{$this->noteOfA}")
            ->assertOk()
            ->assertJsonPath('data.title', 'Secret plan')
            ->assertJsonPath('data.tags', ['private', 'shared-name']);
    }

    public function test_user_b_cannot_delete_user_a_note(): void
    {
        $this->asUser(2)->deleteJson("/api/notes/{$this->noteOfA}")
            ->assertStatus(404)
            ->assertExactJson(['message' => 'Not found.']);

        $this->assertSame(1, DB::table('notes')->count());
        $this->assertSame(2, DB::table('note_tags')->count());
    }

    public function test_user_b_list_and_search_never_return_user_a_notes(): void
    {
        $this->asUser(2);

        $this->getJson('/api/notes')->assertOk()->assertExactJson(['data' => []]);
        $this->getJson('/api/notes?q=secret')->assertExactJson(['data' => []]);
        $this->getJson('/api/notes?q=keyword-alpha')->assertExactJson(['data' => []]);
        $this->getJson('/api/notes?q=private')->assertExactJson(['data' => []]);
        $this->getJson('/api/notes?tag=private')->assertExactJson(['data' => []]);
        $this->getJson('/api/notes?q=secret&tag=private')->assertExactJson(['data' => []]);
        $this->getJson('/api/notes/tags')->assertExactJson(['data' => []]);
    }

    public function test_each_user_only_sees_their_own_matches_for_the_same_keywords(): void
    {
        $noteOfB = $this->asUser(2)->postJson('/api/notes', [
            'title' => 'Secret plan',
            'body' => 'keyword-alpha inside',
            'tags' => ['shared-name', 'only-b'],
        ])->json('data.id');

        foreach (['', '?q=secret', '?q=keyword-alpha', '?q=shared', '?tag=shared-name', '?q=plan&tag=shared-name'] as $query) {
            $this->assertSame([$noteOfB], array_column($this->asUser(2)->getJson('/api/notes'.$query)->json('data'), 'id'), "B: {$query}");
            $this->assertSame([$this->noteOfA], array_column($this->asUser(1)->getJson('/api/notes'.$query)->json('data'), 'id'), "A: {$query}");
        }

        $this->asUser(2)->getJson('/api/notes/tags')->assertExactJson(['data' => ['only-b', 'shared-name']]);
        $this->asUser(1)->getJson('/api/notes/tags')->assertExactJson(['data' => ['private', 'shared-name']]);

        // B's tags never leak into A's note through the shared tag name.
        $this->asUser(1)->getJson("/api/notes/{$this->noteOfA}")->assertJsonPath('data.tags', ['private', 'shared-name']);
    }

    public function test_tenant_models_refuse_to_query_without_a_current_user(): void
    {
        $this->app->forgetScopedInstances();
        $this->assertNull(app(CurrentUser::class)->id());

        foreach ([fn () => Note::query()->count(), fn () => NoteTag::query()->count(), fn () => Note::create(['title' => 'x', 'body' => ''])] as $attempt) {
            try {
                $attempt();
                $this->fail('A tenant query ran without an authenticated user.');
            } catch (\RuntimeException $e) {
                $this->assertSame('No authenticated user in the current request.', $e->getMessage());
            }
        }
    }

    public function test_user_id_is_not_mass_assignable(): void
    {
        app(CurrentUser::class)->set(1);

        $note = Note::create(['title' => 'x', 'body' => '', 'user_id' => 99]);

        $this->assertSame(1, (int) DB::table('notes')->where('id', $note->id)->value('user_id'));
    }
}
