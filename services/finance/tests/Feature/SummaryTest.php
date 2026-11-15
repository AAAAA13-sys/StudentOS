<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class SummaryTest extends TestCase
{
    use RefreshDatabase;

    private function add(string $type, string|int|float $amount, string $category, string $date, int $user = self::USER_A): void
    {
        $this->createTransaction($user, [
            'type' => $type, 'amount' => $amount, 'category' => $category, 'occurred_on' => $date,
        ])->assertCreated();
    }

    private function summary(string $query = '', int $user = self::USER_A): array
    {
        return $this->as($user)->getJson('/api/finance/summary'.$query)->assertOk()->json();
    }

    public function test_summary_matches_the_contract_example(): void
    {
        $this->add('income', '5000.00', 'Allowance', '2026-11-01');
        $this->add('expense', '500.00', 'Food', '2026-11-03');
        $this->add('expense', '320.50', 'Food', '2026-11-10');
        $this->add('expense', '300.00', 'Transport', '2026-11-12');
        $this->add('expense', '200.00', 'School', '2026-11-20');

        $response = $this->as(self::USER_A)->getJson('/api/finance/summary?month=2026-11')->assertOk();

        $this->assertSame([
            'month' => '2026-11',
            'total_income' => 5000.0,
            'total_expenses' => 1320.5,
            'balance' => 3679.5,
            'by_category' => [
                ['category' => 'Allowance', 'type' => 'income', 'total' => 5000.0],
                ['category' => 'Food', 'type' => 'expense', 'total' => 820.5],
                ['category' => 'Transport', 'type' => 'expense', 'total' => 300.0],
                ['category' => 'School', 'type' => 'expense', 'total' => 200.0],
            ],
        ], $response->json());

        // Totals are JSON numbers, not strings.
        $this->assertStringContainsString('"total_expenses":1320.5', $response->getContent());
        $this->assertStringContainsString('"balance":3679.5', $response->getContent());
    }

    public function test_decimal_precision_is_exact(): void
    {
        $this->add('income', '0.10', 'Other', '2026-11-05');
        $this->add('income', '0.20', 'Other', '2026-11-06');
        $this->add('expense', '33.33', 'Food', '2026-11-07');
        $this->add('expense', '33.33', 'Food', '2026-11-08');
        $this->add('expense', '33.33', 'Food', '2026-11-09');

        $response = $this->as(self::USER_A)->getJson('/api/finance/summary?month=2026-11')->assertOk();

        $this->assertSame(0.3, $response->json('total_income'));
        $this->assertSame(99.99, $response->json('total_expenses'));
        $this->assertSame(-99.69, $response->json('balance'));
        $this->assertSame(
            [
                ['category' => 'Food', 'type' => 'expense', 'total' => 99.99],
                ['category' => 'Other', 'type' => 'income', 'total' => 0.3],
            ],
            $response->json('by_category')
        );

        $body = $response->getContent();
        $this->assertStringContainsString('"total_income":0.3,', $body);
        $this->assertStringContainsString('"total_expenses":99.99,', $body);
        $this->assertStringContainsString('"balance":-99.69,', $body);
    }

    public function test_many_small_amounts_do_not_drift(): void
    {
        for ($i = 0; $i < 30; $i++) {
            $this->add('expense', '0.10', 'Transport', '2026-11-10');
        }
        $this->add('income', '3.00', 'Allowance', '2026-11-10');

        $summary = $this->summary('?month=2026-11');

        $this->assertSame(3.0, $summary['total_expenses']);
        $this->assertSame(0.0, $summary['balance']);
    }

    public function test_same_category_is_reported_separately_per_type(): void
    {
        $this->add('income', '50.00', 'Other', '2026-11-02');
        $this->add('expense', '20.00', 'Other', '2026-11-02');

        $this->assertSame(
            [
                ['category' => 'Other', 'type' => 'income', 'total' => 50.0],
                ['category' => 'Other', 'type' => 'expense', 'total' => 20.0],
            ],
            $this->summary('?month=2026-11')['by_category']
        );
    }

    public function test_month_boundaries(): void
    {
        $this->add('expense', '1.00', 'Food', '2026-10-31');   // previous month
        $this->add('expense', '2.00', 'Food', '2026-11-01');   // first day: included
        $this->add('expense', '4.00', 'Food', '2026-11-30');   // last day: included
        $this->add('expense', '8.00', 'Food', '2026-12-01');   // next month: excluded
        $this->add('expense', '16.00', 'Food', '2026-12-31');  // December's last day
        $this->add('expense', '32.00', 'Food', '2027-01-01');  // next year

        $this->assertSame(6.0, $this->summary('?month=2026-11')['total_expenses']);
        $this->assertSame(24.0, $this->summary('?month=2026-12')['total_expenses']);
        $this->assertSame(1.0, $this->summary('?month=2026-10')['total_expenses']);
        $this->assertSame(32.0, $this->summary('?month=2027-01')['total_expenses']);
    }

    public function test_leap_february_includes_the_29th(): void
    {
        $this->add('expense', '5.00', 'Food', '2028-02-29');
        $this->add('expense', '7.00', 'Food', '2028-03-01');

        $this->assertSame(5.0, $this->summary('?month=2028-02')['total_expenses']);
    }

    public function test_empty_month_returns_zeros_and_an_empty_list(): void
    {
        $this->add('expense', '10.00', 'Food', '2026-11-15');

        $response = $this->as(self::USER_A)->getJson('/api/finance/summary?month=2026-09')->assertOk();

        $this->assertSame([
            'month' => '2026-09',
            'total_income' => 0.0,
            'total_expenses' => 0.0,
            'balance' => 0.0,
            'by_category' => [],
        ], $response->json());
        $this->assertStringContainsString('"by_category":[]', $response->getContent());
    }

    public function test_month_defaults_to_the_current_utc_month(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-11-30 23:59:59', 'UTC'));

        $this->add('expense', '10.00', 'Food', '2026-11-30');
        $this->add('expense', '99.00', 'Food', '2026-12-01');

        $summary = $this->summary();

        $this->assertSame('2026-11', $summary['month']);
        $this->assertSame(10.0, $summary['total_expenses']);
    }

    public function test_invalid_month_returns_422(): void
    {
        foreach (['2026-13', '2026-1', 'abc', '2026-11-01'] as $month) {
            $this->as(self::USER_A)->getJson('/api/finance/summary?month='.$month)
                ->assertUnprocessable()
                ->assertJsonValidationErrors(['month']);
        }
    }
}
