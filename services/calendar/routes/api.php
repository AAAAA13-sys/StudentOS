<?php

use App\Http\Controllers\EventController;
use App\Http\Controllers\HealthController;
use App\Http\Controllers\WidgetController;
use Illuminate\Support\Facades\Route;

// Full public paths: the gateway forwards the request path unchanged.
Route::get('/api/calendar/health', HealthController::class);

Route::middleware('jwt')->prefix('/api/calendar')->group(function (): void {
    Route::get('/events', [EventController::class, 'index']);
    Route::post('/events', [EventController::class, 'store']);
    Route::get('/events/{id}', [EventController::class, 'show']);
    Route::put('/events/{id}', [EventController::class, 'update']);
    Route::delete('/events/{id}', [EventController::class, 'destroy']);

    Route::get('/widget', WidgetController::class);
});
