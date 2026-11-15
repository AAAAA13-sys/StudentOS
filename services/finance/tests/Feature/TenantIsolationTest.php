<?php

namespace Tests\Feature;

use App\Models\Transaction;
use App\Support\CurrentUser;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class TenantIsolationTest extends TestCase
{
    use RefreshDatabase;

    private int $idOfA;

    protected function setUp(): void
    {
        parent::setUp();

        $this->idOfA = $this->createTransaction(self::USER_A, [
            'type' => 'expense', 'amount' => '777.77', 'category' => 'Food', 'occurred_on' => '2026-11-15', 'note' => 'private to A',
        ])->assertCreated()->json('data.id');
    }

    public function test_user_b_cannot_show_user_a_transaction(): void
    {
        $this->as(self::USER_B)->getJson("/api/finance/transactions/{$this->idOfA}")
            ->assertNotFound()
            ->assertExactJson(['message' => 'Not found.']);
    }

    public function test_user_b_cannot_update_user_a_transaction(): void
    {
        $this->as(self::USER_B)->putJson("/api/finance/transactions/{$this->idOfA}", ['amount' => 1, 'note' => 'hijacked'])
            ->assertNotFound()
            ->assertExactJson(['message' => 'Not found.']);

        $row = DB::table('transactions')->where('id', $this->idOfA)->first();
        $this->assertSame('private to A', $row->note);
        $this->assertSame(777.77, round((float) $row->amount, 2));
        $this->assertSame(self::USER_A, (int) $row->user_id);
    }

    public function test_user_b_cannot_delete_user_a_transaction(): void
    {
        $this->as(self::USER_B)->deleteJson("/api/finance/transactions/{$this->idOfA}")
            ->assertNotFound()
            ->assertExactJson(['message' => 'Not found.']);

        $this->assertSame(1, DB::table('transactions')->where('id', $this->idOfA)->count());
        $this->as(self::USER_A)->getJson("/api/finance/transactions/{$this->idOfA}")->assertOk();
    }

    public function test_user_b_does_not_see_user_a_transactions_in_lists(): void
    {
        $idOfB = $this->createTransaction(self::USER_B, ['note' => 'belongs to B'])->json('data.id');

        foreach (['', '?month=2026-11', '?category=Food', '?type=expense'] as $query) {
            $this->assertSame(
                [$idOfB],
                $this->as(self::USER_B)->getJson('/api/finance/transactions'.$query)->assertOk()->json('data.*.id'),
                "Leak with query [{$query}]"
            );
        }

        $this->assertSame(
            [$this->idOfA],
            $this->as(self::USER_A)->getJson('/api/finance/transactions')->json('data.*.id')
        );
    }

    public function test_user_a_amounts_never_appear_in_user_b_summary(): void
    {
        $this->as(self::USER_B)->getJson('/api/finance/summary?month=2026-11')
            ->assertOk()
            ->assertExactJson([
                'month' => '2026-11', 'total_income' => 0.0, 'total_expenses' => 0.0, 'balance' => 0.0, 'by_category' => [],
            ]);

        $this->createTransaction(self::USER_B, ['amount' => '10.00', 'category' => 'Food'])->assertCreated();

        $summary = $this->as(self::USER_B)->getJson('/api/finance/summary?month=2026-11')->json();
        $this->assertSame(10.0, $summary['total_expenses']);
        $this->assertSame(-10.0, $summary['balance']);
        $this->assertSame([['category' => 'Food', 'type' => 'expense', 'total' => 10.0]], $summary['by_category']);

        $this->assertSame(
            777.77,
            $this->as(self::USER_A)->getJson('/api/finance/summary?month=2026-11')->json('total_expenses')
        );
    }

    public function test_queries_fail_closed_when_no_user_is_set(): void
    {
        $this->app->forgetScopedInstances();

        $this->expectException(\LogicException::class);

        Transaction::query()->count();
    }

    public function test_user_id_is_not_mass_assignable(): void
    {
        app(CurrentUser::class)->set(self::USER_B);

        $transaction = Transaction::create([
            'user_id' => self::USER_A,
            'type' => 'expense', 'amount' => '1.00', 'category' => 'Other', 'occurred_on' => '2026-11-15',
        ]);

        $this->assertSame(self::USER_B, (int) $transaction->user_id);
    }
}
