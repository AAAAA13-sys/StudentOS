<?php

namespace App\Models;

use App\Models\Concerns\BelongsToUser;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use BelongsToUser;

    // user_id is deliberately absent: it is set only by BelongsToUser.
    protected $fillable = ['type', 'amount', 'category', 'occurred_on', 'note'];
}
