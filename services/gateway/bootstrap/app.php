<?php

use App\Gateway\JsonError;
use App\Http\Middleware\AccessLog;
use App\Http\Middleware\LimitBodySize;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Support\Facades\Route;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        using: fn () => Route::group([], base_path('routes/api.php')),
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // The gateway is stateless: no sessions, cookies, CORS or proxy trust.
        // Client IPs come from the socket, so X-Forwarded-For cannot dodge the throttle.
        $middleware->use([
            AccessLog::class,
            LimitBodySize::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(function (Throwable $e) {
            if ($e instanceof NotFoundHttpException) {
                return JsonError::notFound();
            }

            if ($e instanceof HttpExceptionInterface) {
                $status = $e->getStatusCode();

                return JsonError::make($status, (Response::$statusTexts[$status] ?? 'Error').'.', $e->getHeaders());
            }

            return JsonError::serverError();
        });
    })->create();
