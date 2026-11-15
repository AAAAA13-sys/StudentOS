<?php

namespace App\Models;

use App\Models\Concerns\BelongsToUser;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Note extends Model
{
    use BelongsToUser;

    protected $fillable = ['title', 'body'];

    public function tagRows(): HasMany
    {
        return $this->hasMany(NoteTag::class);
    }

    /** @return array<string, mixed> */
    public function toApi(): array
    {
        $tags = $this->tagRows->pluck('tag')->all();
        sort($tags, SORT_STRING);

        return [
            'id' => $this->id,
            'title' => $this->title,
            'body' => $this->body,
            'tags' => $tags,
            'created_at' => $this->created_at->utc()->format('Y-m-d\TH:i:s\Z'),
            'updated_at' => $this->updated_at->utc()->format('Y-m-d\TH:i:s\Z'),
        ];
    }
}
