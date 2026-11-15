<?php

namespace App\Providers;

use App\Support\CurrentUser;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->scoped(CurrentUser::class);
    }
}
