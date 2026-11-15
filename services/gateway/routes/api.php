<?php

use App\Gateway\JsonError;
use App\Http\Controllers\ProxyController;
use App\Http\Middleware\AuthenticateJwt;
use App\Http\Middleware\ResolveTarget;
use App\Http\Middleware\ThrottleAuthEntry;
use Illuminate\Support\Facades\Route;

Route::get('/api/health', fn () => response()->json(['status' => 'ok', 'service' => 'gateway']));

// Which service, whether a JWT is needed, and the upstream path are all
// decided by ResolveTarget from the request path, not from route parameters.
Route::any('/api/{service}/{path?}', ProxyController::class)
    ->where('path', '.*')
    ->middleware([ResolveTarget::class, ThrottleAuthEntry::class, AuthenticateJwt::class]);

Route::fallback(fn () => JsonError::notFound());
