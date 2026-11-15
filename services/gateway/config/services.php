<?php

return [

    /*
    | The only routable upstreams. The key is the {service} path segment of
    | /api/{service}/...; the base URL comes from the environment and never
    | from request input.
    */
    'upstreams' => [
        'auth' => env('AUTH_SERVICE_URL'),
        'calendar' => env('CALENDAR_SERVICE_URL'),
        'finance' => env('FINANCE_SERVICE_URL'),
        'notes' => env('NOTES_SERVICE_URL'),
    ],

];
