<?php

use App\Http\Middleware\AuthenticateJwt;
use App\Http\Middleware\ForceJsonResponse;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        api: __DIR__.'/../routes/api.php',
        apiPrefix: '',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->prepend(ForceJsonResponse::class);
        $middleware->alias(['jwt' => AuthenticateJwt::class]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(fn (Request $request, Throwable $e): bool => true);

        // Covers unknown routes and missing/other-tenant models (ModelNotFoundException
        // is converted to NotFoundHttpException before rendering).
        $exceptions->render(fn (NotFoundHttpException $e) => response()->json(['message' => 'Not found.'], 404));
    })->create();
