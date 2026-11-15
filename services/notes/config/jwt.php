<?php

return [
    // Shared HS256 secret; tokens are issued only by the Auth Service.
    'secret' => (string) env('JWT_SECRET', ''),
];
