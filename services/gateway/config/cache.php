<?php

return [

    // Only used by the login/register rate limiter. No database store exists.
    'default' => env('CACHE_STORE', 'file'),

    'stores' => [

        'array' => [
            'driver' => 'array',
            'serialize' => false,
        ],

        'file' => [
            'driver' => 'file',
            'path' => storage_path('framework/cache/data'),
            'lock_path' => storage_path('framework/cache/data'),
        ],

    ],

    'prefix' => env('CACHE_PREFIX', 'studentos-gateway-cache-'),

];
