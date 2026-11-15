<?php

namespace App\Http\Middleware;

use App\Gateway\JsonError;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class LimitBodySize
{
    public function handle(Request $request, Closure $next): Response
    {
        $max = (int) config('gateway.max_body_bytes');

        $declared = (int) $request->headers->get('Content-Length', '0');

        if ($declared > $max || strlen($request->getContent()) > $max) {
            return JsonError::make(413, 'Payload too large.');
        }

        return $next($request);
    }
}
