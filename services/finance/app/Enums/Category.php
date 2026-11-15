<?php

namespace App\Enums;

/**
 * The single source of truth for transaction categories (CONTRACT section 8).
 */
enum Category: string
{
    case Food = 'Food';
    case Transport = 'Transport';
    case School = 'School';
    case Entertainment = 'Entertainment';
    case Allowance = 'Allowance';
    case PartTimeJob = 'Part-time Job';
    case Other = 'Other';

    /** @return list<string> */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
