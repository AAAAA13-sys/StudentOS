<?php

return [

    'connect_timeout' => 3,
    'timeout' => 10,

    // Largest request body accepted, in bytes.
    'max_body_bytes' => 1024 * 1024,

    // POST /api/auth/login and /api/auth/register, per client IP and path.
    'auth_throttle' => [
        'max_attempts' => 10,
        'decay_seconds' => 60,
    ],

];
