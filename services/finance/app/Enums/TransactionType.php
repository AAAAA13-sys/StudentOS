<?php

namespace App\Enums;

enum TransactionType: string
{
    case Income = 'income';
    case Expense = 'expense';

    /** @return list<string> */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }
}
