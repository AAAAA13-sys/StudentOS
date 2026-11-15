<?php

return [
    'secret' => (string) env('JWT_SECRET', ''),
    'min_secret_length' => 32,
    'ttl_days' => 7,
];
