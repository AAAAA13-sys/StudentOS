<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class NoteSearchTest extends TestCase
{
    use RefreshDatabase;

    /** @param  array<int, string>  $tags */
    private function createNote(string $title, string $body = '', array $tags = []): int
    {
        return $this->postJson('/api/notes', ['title' => $title, 'body' => $body, 'tags' => $tags])
            ->assertStatus(201)
            ->json('data.id');
    }

    /** @return array<int, string> */
    private function titles(string $queryString = ''): array
    {
        $response = $this->getJson('/api/notes'.$queryString)->assertOk();
        $titles = array_column($response->json('data'), 'title');
        sort($titles);

        return $titles;
    }

    private function seedNotes(): void
    {
        $this->asUser(1);
        $this->createNote('Calculus Lecture', 'Limits and derivatives', ['math', 'exam']);
        $this->createNote('Shopping', 'Buy a calculator and paper', ['errands']);
        $this->createNote('History essay', 'Outline for the Rizal paper', ['history', 'mathematics-club']);
    }

    public function test_list_without_filters_returns_all_notes_with_tags(): void
    {
        $this->seedNotes();

        $response = $this->getJson('/api/notes')->assertOk()->assertJsonCount(3, 'data');
        $byTitle = array_column($response->json('data'), 'tags', 'title');
        $this->assertSame(['exam', 'math'], $byTitle['Calculus Lecture']);
        $this->assertSame(['errands'], $byTitle['Shopping']);
    }

    public function test_empty_list(): void
    {
        $this->asUser(1)->getJson('/api/notes')->assertOk()->assertExactJson(['data' => []]);
    }

    public function test_search_matches_title(): void
    {
        $this->seedNotes();

        $this->assertSame(['Calculus Lecture'], $this->titles('?q=Lecture'));
    }

    public function test_search_matches_body(): void
    {
        $this->seedNotes();

        $this->assertSame(['Calculus Lecture'], $this->titles('?q=derivatives'));
    }

    public function test_search_matches_tag_substring(): void
    {
        $this->seedNotes();

        $this->assertSame(['Shopping'], $this->titles('?q=errand'));
        $this->assertSame(['Calculus Lecture', 'History essay'], $this->titles('?q=math'));
    }

    public function test_search_matches_across_fields(): void
    {
        $this->seedNotes();

        // "calcul" is in one title and in another note's body.
        $this->assertSame(['Calculus Lecture', 'Shopping'], $this->titles('?q=calcul'));
    }

    public function test_search_is_case_insensitive(): void
    {
        $this->seedNotes();

        $this->assertSame(['Calculus Lecture'], $this->titles('?q=LECTURE'));
        $this->assertSame(['Calculus Lecture'], $this->titles('?q=dErIvAtIvEs'));
        $this->assertSame(['Shopping'], $this->titles('?q=ERRANDS'));
    }

    public function test_search_finds_non_ascii_text_as_typed(): void
    {
        $this->asUser(1);
        $this->createNote('Résumé tips', 'Señor García');

        $this->assertSame(['Résumé tips'], $this->titles('?q='.urlencode('Résumé')));
        $this->assertSame(['Résumé tips'], $this->titles('?q='.urlencode('García')));
    }

    public function test_search_treats_percent_and_underscore_literally(): void
    {
        $this->asUser(1);
        $this->createNote('Discount 50% off', 'plain');
        $this->createNote('snake_case names', 'plain');
        $this->createNote('Nothing special', 'plain');

        $this->assertSame(['Discount 50% off'], $this->titles('?q=%25'));
        $this->assertSame(['snake_case names'], $this->titles('?q=_'));
        $this->assertSame(['Discount 50% off'], $this->titles('?q=50%25'));
        $this->assertSame(['snake_case names'], $this->titles('?q=e_c'));
        $this->assertSame([], $this->titles('?q=N_thing'));
        $this->assertSame([], $this->titles('?q=Noth%25special'));
    }

    public function test_search_treats_backslash_and_quotes_literally(): void
    {
        $this->asUser(1);
        $this->createNote('Path C:\\Users', "it's a 'quoted' body");
        $this->createNote('Other', 'plain');

        $this->assertSame(['Path C:\\Users'], $this->titles('?q='.urlencode('C:\\U')));
        $this->assertSame(['Path C:\\Users'], $this->titles('?q='.urlencode('\\')));
        $this->assertSame(['Path C:\\Users'], $this->titles('?q='.urlencode("it's")));
        $this->assertSame([], $this->titles('?q='.urlencode("' OR 1=1 --")));
    }

    public function test_search_without_a_match_returns_an_empty_list(): void
    {
        $this->seedNotes();

        $this->getJson('/api/notes?q=zzz-nothing')->assertOk()->assertExactJson(['data' => []]);
    }

    public function test_blank_q_and_tag_are_ignored(): void
    {
        $this->seedNotes();

        $this->getJson('/api/notes?q=&tag=')->assertOk()->assertJsonCount(3, 'data');
        $this->getJson('/api/notes?q=%20%20')->assertOk()->assertJsonCount(3, 'data');
    }

    public function test_non_string_filters_are_rejected(): void
    {
        $this->asUser(1);

        $this->getJson('/api/notes?q[]=a')->assertStatus(422)->assertJsonValidationErrors(['q']);
        $this->getJson('/api/notes?tag[]=a')->assertStatus(422)->assertJsonValidationErrors(['tag']);
    }

    public function test_tag_filter_is_an_exact_match_after_normalisation(): void
    {
        $this->seedNotes();

        $this->assertSame(['Calculus Lecture'], $this->titles('?tag=math'));
        $this->assertSame(['Calculus Lecture'], $this->titles('?tag='.urlencode('  MATH ')));
        $this->assertSame([], $this->titles('?tag=mat'));
        $this->assertSame([], $this->titles('?tag=%25'));
        $this->assertSame([], $this->titles('?tag=unknown'));
    }

    public function test_q_and_tag_combine_with_and(): void
    {
        $this->seedNotes();
        $this->createNote('Algebra Lecture', 'Matrices', ['math']);

        $this->assertSame(['Algebra Lecture', 'Calculus Lecture'], $this->titles('?tag=math'));
        $this->assertSame(['Calculus Lecture'], $this->titles('?q=calculus&tag=math'));
        $this->assertSame(['Algebra Lecture', 'Calculus Lecture'], $this->titles('?q=lecture&tag=math'));
        $this->assertSame([], $this->titles('?q=calculus&tag=errands'));
    }

    public function test_notes_are_ordered_by_last_modified(): void
    {
        $this->asUser(1);
        $this->travelTo('2026-11-20 08:00:00');
        $first = $this->createNote('First');
        $this->travelTo('2026-11-20 09:00:00');
        $second = $this->createNote('Second');
        $this->travelTo('2026-11-20 10:00:00');
        $third = $this->createNote('Third');

        $this->assertSame([$third, $second, $first], array_column($this->getJson('/api/notes')->json('data'), 'id'));

        $this->travelTo('2026-11-20 11:00:00');
        $this->putJson("/api/notes/{$first}", ['body' => 'edited'])->assertOk();

        $this->assertSame([$first, $third, $second], array_column($this->getJson('/api/notes')->json('data'), 'id'));

        // A tag-only change also counts as a modification.
        $this->travelTo('2026-11-20 12:00:00');
        $this->putJson("/api/notes/{$second}", ['tags' => ['new']])->assertOk();

        $this->assertSame([$second, $first, $third], array_column($this->getJson('/api/notes')->json('data'), 'id'));
    }

    public function test_notes_modified_in_the_same_second_are_ordered_by_id_desc(): void
    {
        $this->asUser(1);
        $this->travelTo('2026-11-20 08:00:00');
        $a = $this->createNote('A');
        $b = $this->createNote('B');

        $this->assertSame([$b, $a], array_column($this->getJson('/api/notes')->json('data'), 'id'));
    }

    public function test_listing_does_not_run_a_query_per_note(): void
    {
        $this->asUser(1);
        foreach (range(1, 8) as $i) {
            $this->createNote("Note {$i}", 'body', ["tag{$i}", 'shared']);
        }

        DB::enableQueryLog();
        $this->getJson('/api/notes?q=note&tag=shared')->assertOk()->assertJsonCount(8, 'data');
        $queries = DB::getQueryLog();
        DB::disableQueryLog();

        $this->assertCount(2, $queries);
    }

    public function test_tags_list_is_distinct_and_sorted(): void
    {
        $this->seedNotes();
        $this->createNote('Another', '', ['Math', 'zoology', 'art']);

        $this->getJson('/api/notes/tags')
            ->assertOk()
            ->assertExactJson(['data' => ['art', 'errands', 'exam', 'history', 'math', 'mathematics-club', 'zoology']]);
    }

    public function test_tags_list_is_empty_without_notes_and_drops_removed_tags(): void
    {
        $this->asUser(1)->getJson('/api/notes/tags')->assertOk()->assertExactJson(['data' => []]);

        $id = $this->createNote('Tagged', '', ['temp', 'keep']);
        $this->putJson("/api/notes/{$id}", ['tags' => ['keep']])->assertOk();
        $this->getJson('/api/notes/tags')->assertExactJson(['data' => ['keep']]);

        $this->deleteJson("/api/notes/{$id}")->assertStatus(204);
        $this->getJson('/api/notes/tags')->assertExactJson(['data' => []]);
    }
}
