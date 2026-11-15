<?php

return [

    // Shared HS256 secret (same value as the Auth Service). Must be >= 32 chars.
    'secret' => (string) env('JWT_SECRET', ''),

    'issuer' => 'studentos-auth',

    'min_secret_length' => 32,

];
