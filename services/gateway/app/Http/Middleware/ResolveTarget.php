<?php

namespace App\Http\Middleware;

use App\Gateway\JsonError;
use App\Gateway\Target;
use App\Gateway\TargetResolver;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/** Decides which service a request is for; anything unroutable ends here as 404. */
class ResolveTarget
{
    public const TARGET = 'gateway.target';

    public function __construct(private readonly TargetResolver $resolver) {}

    public function handle(Request $request, Closure $next): Response
    {
        $target = $this->resolver->resolve($request);

        if (! $target instanceof Target) {
            return JsonError::notFound();
        }

        $request->attributes->set(self::TARGET, $target);

        return $next($request);
    }
}
