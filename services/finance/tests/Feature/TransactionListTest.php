<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class TransactionListTest extends TestCase
{
    use RefreshDatabase;

    /** @return array<string, int> note => id */
    private function seedTransactions(): array
    {
        $rows = [
            ['note' => 'oct-last', 'occurred_on' => '2026-10-31', 'type' => 'expense', 'category' => 'Food', 'amount' => 10],
            ['note' => 'nov-first', 'occurred_on' => '2026-11-01', 'type' => 'income', 'category' => 'Allowance', 'amount' => 5000],
            ['note' => 'nov-mid-a', 'occurred_on' => '2026-11-15', 'type' => 'expense', 'category' => 'Food', 'amount' => 120.50],
            ['note' => 'nov-mid-b', 'occurred_on' => '2026-11-15', 'type' => 'expense', 'category' => 'Transport', 'amount' => 30],
            ['note' => 'nov-last', 'occurred_on' => '2026-11-30', 'type' => 'expense', 'category' => 'Food', 'amount' => 45],
            ['note' => 'dec-first', 'occurred_on' => '2026-12-01', 'type' => 'income', 'category' => 'Part-time Job', 'amount' => 800],
        ];

        $ids = [];
        foreach ($rows as $row) {
            $ids[$row['note']] = $this->createTransaction(self::USER_A, $row)->assertCreated()->json('data.id');
        }

        return $ids;
    }

    private function notes(string $query = ''): array
    {
        return $this->as(self::USER_A)->getJson('/api/finance/transactions'.$query)
            ->assertOk()
            ->assertJsonStructure(['data'])
            ->json('data.*.note');
    }

    public function test_empty_list_is_an_empty_data_array(): void
    {
        $this->as(self::USER_A)->getJson('/api/finance/transactions')
            ->assertOk()
            ->assertExactJson(['data' => []]);
    }

    public function test_list_is_ordered_by_date_desc_then_id_desc(): void
    {
        $this->seedTransactions();

        $this->assertSame(
            ['dec-first', 'nov-last', 'nov-mid-b', 'nov-mid-a', 'nov-first', 'oct-last'],
            $this->notes()
        );
    }

    public function test_month_filter_includes_first_and_last_day_and_excludes_neighbours(): void
    {
        $this->seedTransactions();

        $this->assertSame(['nov-last', 'nov-mid-b', 'nov-mid-a', 'nov-first'], $this->notes('?month=2026-11'));
        $this->assertSame(['dec-first'], $this->notes('?month=2026-12'));
        $this->assertSame(['oct-last'], $this->notes('?month=2026-10'));
        $this->assertSame([], $this->notes('?month=2026-09'));
    }

    public function test_category_filter(): void
    {
        $this->seedTransactions();

        $this->assertSame(['nov-last', 'nov-mid-a', 'oct-last'], $this->notes('?category=Food'));
        $this->assertSame(['dec-first'], $this->notes('?category='.rawurlencode('Part-time Job')));
    }

    public function test_type_filter(): void
    {
        $this->seedTransactions();

        $this->assertSame(['dec-first', 'nov-first'], $this->notes('?type=income'));
        $this->assertSame(['nov-last', 'nov-mid-b', 'nov-mid-a', 'oct-last'], $this->notes('?type=expense'));
    }

    public function test_filters_combine(): void
    {
        $this->seedTransactions();

        $this->assertSame(['nov-last', 'nov-mid-a'], $this->notes('?month=2026-11&category=Food&type=expense'));
        $this->assertSame([], $this->notes('?month=2026-11&category=Food&type=income'));
    }

    public static function invalidFilters(): array
    {
        return [
            'month without zero padding' => ['?month=2026-1', 'month'],
            'month 13' => ['?month=2026-13', 'month'],
            'month 00' => ['?month=2026-00', 'month'],
            'month with day' => ['?month=2026-11-01', 'month'],
            'month as words' => ['?month=november', 'month'],
            'month as array' => ['?month[]=2026-11', 'month'],
            'unknown category' => ['?category=Rent', 'category'],
            'unknown type' => ['?type=transfer', 'type'],
        ];
    }

    #[DataProvider('invalidFilters')]
    public function test_invalid_filters_return_422(string $query, string $field): void
    {
        $this->as(self::USER_A)->getJson('/api/finance/transactions'.$query)
            ->assertUnprocessable()
            ->assertJsonValidationErrors([$field]);
    }
}
