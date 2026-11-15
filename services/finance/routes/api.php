<?php

use App\Http\Controllers\CategoryController;
use App\Http\Controllers\HealthController;
use App\Http\Controllers\SummaryController;
use App\Http\Controllers\TransactionController;
use Illuminate\Support\Facades\Route;

// Full public paths: the gateway forwards the path unchanged.
Route::get('/api/finance/health', HealthController::class);

Route::middleware('jwt')->group(function (): void {
    Route::get('/api/finance/categories', CategoryController::class);
    Route::get('/api/finance/summary', SummaryController::class);

    Route::get('/api/finance/transactions', [TransactionController::class, 'index']);
    Route::post('/api/finance/transactions', [TransactionController::class, 'store']);

    // Digits only, short enough to always fit a bigint.
    Route::where(['id' => '[0-9]{1,18}'])->group(function (): void {
        Route::get('/api/finance/transactions/{id}', [TransactionController::class, 'show']);
        Route::put('/api/finance/transactions/{id}', [TransactionController::class, 'update']);
        Route::delete('/api/finance/transactions/{id}', [TransactionController::class, 'destroy']);
    });
});
