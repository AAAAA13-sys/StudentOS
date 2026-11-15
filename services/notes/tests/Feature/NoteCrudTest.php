<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class NoteCrudTest extends TestCase
{
    use RefreshDatabase;

    public function test_create_returns_the_note_in_the_contract_shape(): void
    {
        $this->travelTo('2026-11-20 01:30:00');

        $response = $this->asUser(1)->postJson('/api/notes', [
            'title' => 'Lecture 3',
            'body' => 'Derivatives',
            'tags' => ['math', 'exam'],
        ]);

        $response->assertStatus(201)->assertExactJson(['data' => [
            'id' => $response->json('data.id'),
            'title' => 'Lecture 3',
            'body' => 'Derivatives',
            'tags' => ['exam', 'math'],
            'created_at' => '2026-11-20T01:30:00Z',
            'updated_at' => '2026-11-20T01:30:00Z',
        ]]);
        $this->assertIsInt($response->json('data.id'));
        $this->assertDatabaseHas('notes', ['id' => $response->json('data.id'), 'user_id' => 1]);
        $this->assertDatabaseHas('note_tags', ['note_id' => $response->json('data.id'), 'user_id' => 1, 'tag' => 'math']);
    }

    public function test_create_defaults_body_and_tags_and_works_without_a_json_accept_header(): void
    {
        $this->asUser(1)->post('/api/notes', ['title' => '  Only a title  '])
            ->assertStatus(201)
            ->assertJsonPath('data.title', 'Only a title')
            ->assertJsonPath('data.body', '')
            ->assertJsonPath('data.tags', []);
    }

    public function test_body_may_be_an_empty_string_and_is_stored_verbatim(): void
    {
        $this->asUser(1)->postJson('/api/notes', ['title' => 'Empty', 'body' => ''])
            ->assertStatus(201)->assertJsonPath('data.body', '');

        $this->asUser(1)->postJson('/api/notes', ['title' => 'Spaced', 'body' => "  indented\n"])
            ->assertStatus(201)->assertJsonPath('data.body', "  indented\n");
    }

    public function test_user_id_in_the_payload_is_ignored(): void
    {
        $id = $this->asUser(1)->postJson('/api/notes', ['title' => 'Mine', 'user_id' => 2])->json('data.id');

        $this->assertDatabaseHas('notes', ['id' => $id, 'user_id' => 1]);
        $this->asUser(2)->getJson('/api/notes')->assertExactJson(['data' => []]);
    }

    public function test_create_validation_failures(): void
    {
        $this->asUser(1);

        $this->postJson('/api/notes', [])->assertStatus(422)->assertJsonValidationErrors(['title']);
        $this->postJson('/api/notes', ['title' => '   '])->assertStatus(422)->assertJsonValidationErrors(['title']);
        $this->postJson('/api/notes', ['title' => str_repeat('a', 201)])->assertStatus(422)->assertJsonValidationErrors(['title']);
        $this->postJson('/api/notes', ['title' => ['x']])->assertStatus(422)->assertJsonValidationErrors(['title']);
        $this->postJson('/api/notes', ['title' => 'T', 'body' => null])->assertStatus(422)->assertJsonValidationErrors(['body']);
        $this->postJson('/api/notes', ['title' => 'T', 'body' => 5])->assertStatus(422)->assertJsonValidationErrors(['body']);
        $this->postJson('/api/notes', ['title' => 'T', 'body' => str_repeat('a', 100001)])->assertStatus(422)->assertJsonValidationErrors(['body']);
        $this->postJson('/api/notes', ['title' => 'T', 'tags' => 'math'])->assertStatus(422)->assertJsonValidationErrors(['tags']);
        $this->postJson('/api/notes', ['title' => 'T', 'tags' => ['a' => 'math']])->assertStatus(422)->assertJsonValidationErrors(['tags']);
        $this->postJson('/api/notes', ['title' => 'T', 'tags' => [1]])->assertStatus(422)->assertJsonValidationErrors(['tags.0']);
        $this->postJson('/api/notes', ['title' => 'T', 'tags' => [str_repeat('a', 31)]])->assertStatus(422)->assertJsonValidationErrors(['tags']);
        $this->postJson('/api/notes', ['title' => 'T', 'tags' => array_map(fn ($i) => "tag{$i}", range(1, 21))])->assertStatus(422)->assertJsonValidationErrors(['tags']);

        $this->assertSame(0, DB::table('notes')->count());
        $this->assertSame(0, DB::table('note_tags')->count());
    }

    public function test_limits_are_inclusive(): void
    {
        $this->asUser(1)->postJson('/api/notes', [
            'title' => str_repeat('a', 200),
            'body' => str_repeat('b', 100000),
            'tags' => array_merge([str_repeat('c', 30)], array_map(fn ($i) => "tag{$i}", range(1, 19))),
        ])->assertStatus(201)->assertJsonCount(20, 'data.tags');
    }

    public function test_tags_are_normalised_on_write(): void
    {
        $response = $this->asUser(1)->postJson('/api/notes', [
            'title' => 'Tags',
            'tags' => ['  Math ', 'MATH', 'math', '', '   ', 'Exam', 'ÉCOLE', '2026'],
        ]);

        $response->assertStatus(201);
        $this->assertSame(['2026', 'exam', 'math', 'école'], $response->json('data.tags'));
        $this->assertSame(4, DB::table('note_tags')->count());
    }

    public function test_show_returns_the_note(): void
    {
        $id = $this->asUser(1)->postJson('/api/notes', ['title' => 'Show me', 'tags' => ['b', 'a']])->json('data.id');

        $this->getJson("/api/notes/{$id}")
            ->assertOk()
            ->assertJsonPath('data.id', $id)
            ->assertJsonPath('data.title', 'Show me')
            ->assertJsonPath('data.tags', ['a', 'b']);
    }

    public function test_show_unknown_id_is_404(): void
    {
        $this->asUser(1)->getJson('/api/notes/999')->assertStatus(404)->assertExactJson(['message' => 'Not found.']);
        $this->getJson('/api/notes/999999999999999999')->assertStatus(404);
        $this->getJson('/api/notes/99999999999999999999')->assertStatus(404);
    }

    public function test_update_is_partial_and_bumps_updated_at(): void
    {
        $this->travelTo('2026-11-20 01:30:00');
        $id = $this->asUser(1)->postJson('/api/notes', ['title' => 'Old', 'body' => 'Body', 'tags' => ['math']])->json('data.id');

        $this->travelTo('2026-11-21 08:00:00');
        $this->putJson("/api/notes/{$id}", ['title' => 'New'])
            ->assertOk()
            ->assertExactJson(['data' => [
                'id' => $id,
                'title' => 'New',
                'body' => 'Body',
                'tags' => ['math'],
                'created_at' => '2026-11-20T01:30:00Z',
                'updated_at' => '2026-11-21T08:00:00Z',
            ]]);

        $this->travelTo('2026-11-22 08:00:00');
        $this->putJson("/api/notes/{$id}", ['body' => ''])
            ->assertOk()
            ->assertJsonPath('data.title', 'New')
            ->assertJsonPath('data.body', '')
            ->assertJsonPath('data.updated_at', '2026-11-22T08:00:00Z');
    }

    public function test_update_replaces_tags_and_bumps_updated_at(): void
    {
        $this->travelTo('2026-11-20 01:30:00');
        $id = $this->asUser(1)->postJson('/api/notes', ['title' => 'T', 'tags' => ['math', 'exam']])->json('data.id');

        $this->travelTo('2026-11-21 08:00:00');
        $this->putJson("/api/notes/{$id}", ['tags' => ['Exam', 'physics']])
            ->assertOk()
            ->assertJsonPath('data.tags', ['exam', 'physics'])
            ->assertJsonPath('data.updated_at', '2026-11-21T08:00:00Z');

        $this->putJson("/api/notes/{$id}", ['tags' => []])->assertOk()->assertJsonPath('data.tags', []);
        $this->assertSame(0, DB::table('note_tags')->count());
    }

    public function test_update_validation_failures_leave_the_note_unchanged(): void
    {
        $id = $this->asUser(1)->postJson('/api/notes', ['title' => 'Keep', 'body' => 'Body', 'tags' => ['math']])->json('data.id');

        $this->putJson("/api/notes/{$id}", ['title' => ''])->assertStatus(422)->assertJsonValidationErrors(['title']);
        $this->putJson("/api/notes/{$id}", ['title' => str_repeat('a', 201)])->assertStatus(422)->assertJsonValidationErrors(['title']);
        $this->putJson("/api/notes/{$id}", ['body' => null])->assertStatus(422)->assertJsonValidationErrors(['body']);
        $this->putJson("/api/notes/{$id}", ['tags' => null])->assertStatus(422)->assertJsonValidationErrors(['tags']);
        $this->putJson("/api/notes/{$id}", ['title' => 'Changed', 'tags' => [str_repeat('a', 31)]])->assertStatus(422)->assertJsonValidationErrors(['tags']);

        $this->getJson("/api/notes/{$id}")
            ->assertJsonPath('data.title', 'Keep')
            ->assertJsonPath('data.body', 'Body')
            ->assertJsonPath('data.tags', ['math']);
    }

    public function test_update_unknown_id_is_404(): void
    {
        $this->asUser(1)->putJson('/api/notes/999', ['title' => 'X'])->assertStatus(404)->assertExactJson(['message' => 'Not found.']);
    }

    public function test_delete_removes_the_note_and_its_tags(): void
    {
        $id = $this->asUser(1)->postJson('/api/notes', ['title' => 'Bye', 'tags' => ['math']])->json('data.id');

        $response = $this->deleteJson("/api/notes/{$id}");
        $response->assertStatus(204);
        $this->assertSame('', $response->getContent());

        $this->getJson("/api/notes/{$id}")->assertStatus(404);
        $this->deleteJson("/api/notes/{$id}")->assertStatus(404);
        $this->assertSame(0, DB::table('notes')->count());
        $this->assertSame(0, DB::table('note_tags')->count());
    }
}
