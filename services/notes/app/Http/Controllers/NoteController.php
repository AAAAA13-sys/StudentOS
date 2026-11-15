<?php

namespace App\Http\Controllers;

use App\Models\Note;
use App\Models\NoteTag;
use App\Support\TagNormalizer;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class NoteController extends Controller
{
    /** Explicit escape character: SQLite has none by default, PostgreSQL defaults to backslash. Use ! to avoid PDO escaping issues. */
    private const LIKE = "LIKE ? ESCAPE '!'";

    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'q' => ['sometimes', 'string', 'max:200'],
            'tag' => ['sometimes', 'string', 'max:200'],
        ]);

        $q = trim($filters['q'] ?? '');
        $tag = TagNormalizer::normalizeOne($filters['tag'] ?? '');

        $query = Note::query()->with('tagRows');

        if ($q !== '') {
            // LOWER() only folds ASCII on some databases, so the verbatim pattern is tried as well.
            $raw = '%'.$this->escapeLike($q).'%';
            $lower = '%'.$this->escapeLike(mb_strtolower($q)).'%';

            $query->where(function (Builder $match) use ($raw, $lower): void {
                $match->whereRaw('LOWER(notes.title) '.self::LIKE, [$lower])
                    ->orWhereRaw('notes.title '.self::LIKE, [$raw])
                    ->orWhereRaw('LOWER(notes.body) '.self::LIKE, [$lower])
                    ->orWhereRaw('notes.body '.self::LIKE, [$raw])
                    ->orWhereHas('tagRows', function (Builder $tags) use ($lower): void {
                        $tags->whereRaw('note_tags.tag '.self::LIKE, [$lower]);
                    });
            });
        }

        if ($tag !== '') {
            $query->whereHas('tagRows', function (Builder $tags) use ($tag): void {
                $tags->where('note_tags.tag', $tag);
            });
        }

        $notes = $query->orderByDesc('notes.updated_at')->orderByDesc('notes.id')->get();

        return response()->json(['data' => $notes->map(fn (Note $note) => $note->toApi())->all()]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'title' => ['required', 'string', 'max:200'],
            'body' => ['sometimes', 'string', 'max:100000'],
            'tags' => ['sometimes', 'list'],
            'tags.*' => ['string'],
        ]);
        $tags = TagNormalizer::normalize($data['tags'] ?? []);

        $note = DB::transaction(function () use ($data, $tags): Note {
            $note = Note::create([
                'title' => trim($data['title']),
                'body' => $data['body'] ?? '',
            ]);
            $this->syncTags($note, $tags);

            return $note;
        });

        return response()->json(['data' => $note->load('tagRows')->toApi()], 201);
    }

    public function show(string $id): JsonResponse
    {
        return response()->json(['data' => $this->findNote($id)->toApi()]);
    }

    public function update(Request $request, string $id): JsonResponse
    {
        $note = $this->findNote($id);

        $data = $request->validate([
            'title' => ['sometimes', 'required', 'string', 'max:200'],
            'body' => ['sometimes', 'string', 'max:100000'],
            'tags' => ['sometimes', 'list'],
            'tags.*' => ['string'],
        ]);
        $tags = array_key_exists('tags', $data) ? TagNormalizer::normalize($data['tags']) : null;

        DB::transaction(function () use ($note, $data, $tags): void {
            if (array_key_exists('title', $data)) {
                $note->title = trim($data['title']);
            }
            if (array_key_exists('body', $data)) {
                $note->body = $data['body'];
            }
            // Every accepted update counts as a modification, including tag-only changes.
            $note->updated_at = $note->freshTimestamp();
            $note->save();

            if ($tags !== null) {
                $this->syncTags($note, $tags);
            }
        });

        return response()->json(['data' => $note->load('tagRows')->toApi()]);
    }

    public function destroy(string $id): Response
    {
        $note = $this->findNote($id);

        DB::transaction(function () use ($note): void {
            $note->tagRows()->delete();
            $note->delete();
        });

        return response()->noContent();
    }

    public function tags(): JsonResponse
    {
        $tags = NoteTag::query()->distinct()->pluck('tag')->all();
        sort($tags, SORT_STRING);

        return response()->json(['data' => $tags]);
    }

    /** Scoped to the current user by BelongsToUser, so another user's id is a 404. */
    private function findNote(string $id): Note
    {
        return Note::query()->with('tagRows')->findOrFail((int) $id);
    }

    /** @param  array<int, string>  $tags */
    private function syncTags(Note $note, array $tags): void
    {
        $existing = $note->tagRows()->pluck('tag')->all();

        $removed = array_values(array_diff($existing, $tags));
        if ($removed !== []) {
            $note->tagRows()->whereIn('tag', $removed)->delete();
        }

        foreach (array_diff($tags, $existing) as $tag) {
            $note->tagRows()->create(['tag' => $tag]);
        }
    }

    private function escapeLike(string $value): string
    {
        return str_replace(['!', '%', '_'], ['!!', '!%', '!_'], $value);
    }
}
