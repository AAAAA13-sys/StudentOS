<?php

return [
    // Shared HS256 secret; tokens are issued only by the Auth Service.
    'secret' => (string) env('JWT_SECRET', ''),

    // Anything shorter is treated as a misconfiguration, never as a usable key.
    'min_secret_length' => 32,
];
