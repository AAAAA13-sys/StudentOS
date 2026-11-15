<?php

namespace App\Http\Controllers;

use App\Gateway\JsonError;
use App\Gateway\Target;
use App\Http\Middleware\AccessLog;
use App\Http\Middleware\ResolveTarget;
use GuzzleHttp\Exception\TransferException;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class ProxyController
{
    public function __invoke(Request $request): Response
    {
        /** @var Target $target */
        $target = $request->attributes->get(ResolveTarget::TARGET);

        $baseUrl = config("services.upstreams.{$target->service}");

        if (! is_string($baseUrl) || $baseUrl === '') {
            Log::error("No upstream URL is configured for service [{$target->service}].");

            return JsonError::unavailable();
        }

        $pending = Http::withHeaders($this->upstreamHeaders($request))
            ->connectTimeout((int) config('gateway.connect_timeout'))
            ->timeout((int) config('gateway.timeout'))
            ->withoutRedirecting();

        $body = $request->getContent();

        if ($body !== '') {
            $pending->withBody($body, $request->headers->get('Content-Type', 'application/json'));
        }

        try {
            $upstream = $pending->send($request->method(), $this->upstreamUrl($baseUrl, $target, $request));
        } catch (ConnectionException|TransferException $e) {
            // The exception message can contain the full URL, so only its type is logged.
            Log::warning(sprintf('Upstream [%s] unreachable: %s', $target->service, $e::class));

            return JsonError::unavailable();
        }

        $response = response($upstream->body(), $upstream->status());

        if ($upstream->hasHeader('Content-Type')) {
            $response->header('Content-Type', $upstream->header('Content-Type'));
        }

        return $response;
    }

    /**
     * Only these headers go upstream. Host, Cookie, hop-by-hop headers and
     * anything else the client sent are dropped.
     *
     * @return array<string, string>
     */
    private function upstreamHeaders(Request $request): array
    {
        $headers = [
            'Accept' => 'application/json',
            'X-Request-Id' => $request->attributes->get(AccessLog::REQUEST_ID),
        ];

        $authorization = $request->headers->get('Authorization');

        if (is_string($authorization) && $authorization !== '') {
            $headers['Authorization'] = $authorization;
        }

        return $headers;
    }

    private function upstreamUrl(string $baseUrl, Target $target, Request $request): string
    {
        $url = rtrim($baseUrl, '/').$target->path;

        $query = (string) $request->server->get('QUERY_STRING', '');

        return $query === '' ? $url : $url.'?'.$query;
    }
}
