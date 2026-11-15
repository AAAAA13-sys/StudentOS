<?php

namespace App\Models\Concerns;

use App\Support\CurrentUser;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

/**
 * Tenant isolation: every query is scoped to the authenticated user and
 * user_id is stamped on create from the token, never from input.
 */
trait BelongsToUser
{
    public static function bootBelongsToUser(): void
    {
        static::addGlobalScope('user', function (Builder $builder): void {
            $builder->where(
                $builder->getModel()->qualifyColumn('user_id'),
                app(CurrentUser::class)->idOrFail()
            );
        });

        static::creating(function (Model $model): void {
            $model->setAttribute('user_id', app(CurrentUser::class)->idOrFail());
        });
    }
}
