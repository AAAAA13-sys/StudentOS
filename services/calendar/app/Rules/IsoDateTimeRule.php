<?php

namespace App\Rules;

use App\Support\IsoDateTime;
use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

class IsoDateTimeRule implements ValidationRule
{
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (IsoDateTime::parse($value) === null) {
            $fail('The :attribute field must be an ISO-8601 datetime, e.g. 2026-11-20T01:30:00Z.');
        }
    }
}
