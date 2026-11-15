<?php

use App\Http\Controllers\HealthController;
use App\Http\Controllers\NoteController;
use Illuminate\Support\Facades\Route;

// The gateway forwards paths unchanged, so this service serves /api/notes/* itself.
Route::get('notes/health', HealthController::class);

Route::middleware('jwt')->group(function (): void {
    Route::get('notes/tags', [NoteController::class, 'tags']);

    Route::get('notes', [NoteController::class, 'index']);
    Route::post('notes', [NoteController::class, 'store']);

    // Digits only (and short enough to fit a bigint), so "health" and "tags" never match.
    Route::get('notes/{id}', [NoteController::class, 'show'])->where('id', '[0-9]{1,18}');
    Route::put('notes/{id}', [NoteController::class, 'update'])->where('id', '[0-9]{1,18}');
    Route::delete('notes/{id}', [NoteController::class, 'destroy'])->where('id', '[0-9]{1,18}');
});
