<?php

namespace App\Http\Controllers;

use App\Enums\Category;
use App\Enums\TransactionType;
use App\Http\Resources\TransactionResource;
use App\Models\Transaction;
use App\Support\Money;
use App\Support\Month;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Response;
use Illuminate\Validation\Rule;

class TransactionController
{
    private const MAX_AMOUNT = '9999999999.99';

    public function index(Request $request): AnonymousResourceCollection
    {
        $filters = $request->validate([
            'month' => ['sometimes', 'string', 'regex:'.Month::PATTERN],
            'category' => ['sometimes', 'string', Rule::in(Category::values())],
            'type' => ['sometimes', 'string', Rule::in(TransactionType::values())],
        ]);

        $query = Transaction::query();

        if (isset($filters['month'])) {
            $month = Month::fromLabel($filters['month']);
            $query->where('occurred_on', '>=', $month->start)->where('occurred_on', '<', $month->end);
        }
        if (isset($filters['category'])) {
            $query->where('category', $filters['category']);
        }
        if (isset($filters['type'])) {
            $query->where('type', $filters['type']);
        }

        return TransactionResource::collection(
            $query->orderByDesc('occurred_on')->orderByDesc('id')->get()
        );
    }

    public function store(Request $request): JsonResponse
    {
        $transaction = Transaction::create($this->validated($request, partial: false));

        return (new TransactionResource($transaction))->response()->setStatusCode(201);
    }

    public function show(string $id): TransactionResource
    {
        return new TransactionResource(Transaction::findOrFail((int) $id));
    }

    public function update(Request $request, string $id): TransactionResource
    {
        $transaction = Transaction::findOrFail((int) $id);
        $transaction->update($this->validated($request, partial: true));

        return new TransactionResource($transaction);
    }

    public function destroy(string $id): Response
    {
        Transaction::findOrFail((int) $id)->delete();

        return response()->noContent();
    }

    /** @return array<string, mixed> */
    private function validated(Request $request, bool $partial): array
    {
        $presence = $partial ? 'sometimes' : 'required';

        $data = $request->validate([
            'type' => [$presence, 'required', 'string', Rule::in(TransactionType::values())],
            'amount' => [$presence, 'required', 'numeric', 'decimal:0,2', 'gt:0', 'max:'.self::MAX_AMOUNT],
            'category' => [$presence, 'required', 'string', Rule::in(Category::values())],
            'occurred_on' => [
                $presence, 'required', 'string', 'date_format:Y-m-d',
                'after_or_equal:1900-01-01', 'before_or_equal:2999-12-31',
            ],
            'note' => ['sometimes', 'nullable', 'string', 'max:255'],
        ]);

        if (array_key_exists('amount', $data)) {
            $data['amount'] = Money::normalise($data['amount']);
        }

        return $data;
    }
}
