<?php

return [

    // HS256 secret shared with the Auth Service. Must be at least 32 characters;
    // AuthenticateJwt refuses to validate tokens with anything shorter.
    'secret' => env('JWT_SECRET'),

    'issuer' => 'studentos-auth',

    'min_secret_length' => 32,

];
