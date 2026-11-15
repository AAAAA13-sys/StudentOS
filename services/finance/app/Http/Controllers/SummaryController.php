<?php

namespace App\Http\Controllers;

use App\Enums\TransactionType;
use App\Models\Transaction;
use App\Support\Money;
use App\Support\Month;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SummaryController
{
    public function __invoke(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'month' => ['sometimes', 'string', 'regex:'.Month::PATTERN],
        ]);

        $month = isset($filters['month']) ? Month::fromLabel($filters['month']) : Month::current();

        // The tenant scope from BelongsToUser applies to this aggregate as well.
        $rows = Transaction::query()
            ->selectRaw('type, category, SUM(amount) AS total')
            ->where('occurred_on', '>=', $month->start)
            ->where('occurred_on', '<', $month->end)
            ->groupBy('type', 'category')
            ->orderByDesc('total')
            ->orderBy('category')
            ->orderBy('type')
            ->toBase()
            ->get();

        $income = '0.00';
        $expenses = '0.00';
        $byCategory = [];

        foreach ($rows as $row) {
            $total = Money::normalise($row->total);

            if ($row->type === TransactionType::Income->value) {
                $income = Money::add($income, $total);
            } else {
                $expenses = Money::add($expenses, $total);
            }

            $byCategory[] = [
                'category' => $row->category,
                'type' => $row->type,
                'total' => Money::toNumber($total),
            ];
        }

        return response()->json([
            'month' => $month->label,
            'total_income' => Money::toNumber($income),
            'total_expenses' => Money::toNumber($expenses),
            'balance' => Money::toNumber(Money::subtract($income, $expenses)),
            'by_category' => $byCategory,
        ]);
    }
}
