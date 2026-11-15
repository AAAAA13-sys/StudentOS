<?php

namespace App\Models\Concerns;

use App\Support\CurrentUser;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

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
