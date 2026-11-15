<?php

namespace App\Models;

use App\Models\Concerns\BelongsToUser;
use Illuminate\Database\Eloquent\Model;

class NoteTag extends Model
{
    use BelongsToUser;

    public $timestamps = false;

    protected $fillable = ['tag'];
}
