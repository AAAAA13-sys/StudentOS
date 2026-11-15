<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class TransactionCrudTest extends TestCase
{
    use RefreshDatabase;

    private const TIMESTAMP = '/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/';

    public function test_create_returns_201_with_the_contract_shape(): void
    {
        $response = $this->createTransaction(self::USER_A);

        $response->assertCreated()->assertJsonStructure(['data' => [
            'id', 'type', 'amount', 'category', 'occurred_on', 'note', 'created_at', 'updated_at',
        ]]);

        $data = $response->json('data');
        $this->assertCount(8, $data);
        $this->assertIsInt($data['id']);
        $this->assertSame('expense', $data['type']);
        $this->assertSame(120.5, $data['amount']);
        $this->assertSame('Food', $data['category']);
        $this->assertSame('2026-11-15', $data['occurred_on']);
        $this->assertSame('Lunch', $data['note']);
        $this->assertMatchesRegularExpression(self::TIMESTAMP, $data['created_at']);
        $this->assertMatchesRegularExpression(self::TIMESTAMP, $data['updated_at']);

        // amount must be a JSON number, not a string.
        $this->assertStringContainsString('"amount":120.5', $response->getContent());
    }

    public function test_user_id_comes_from_the_token_never_from_the_body(): void
    {
        $id = $this->createTransaction(self::USER_A, ['user_id' => self::USER_B])->json('data.id');

        $this->assertSame(self::USER_A, (int) DB::table('transactions')->where('id', $id)->value('user_id'));
    }

    public function test_note_is_optional_and_amount_accepts_a_numeric_string(): void
    {
        $response = $this->as(self::USER_A)->postJson('/api/finance/transactions', [
            'type' => 'income',
            'amount' => '5000.00',
            'category' => 'Allowance',
            'occurred_on' => '2026-11-01',
        ]);

        $response->assertCreated();
        $this->assertNull($response->json('data.note'));
        $this->assertSame(5000, (int) $response->json('data.amount'));
        $this->assertStringContainsString('"amount":5000', $response->getContent());
        $this->assertStringNotContainsString('"amount":"', $response->getContent());
    }

    public function test_largest_allowed_amount_round_trips(): void
    {
        $id = $this->createTransaction(self::USER_A, ['amount' => '9999999999.99'])->assertCreated()->json('data.id');

        $this->assertSame(
            9999999999.99,
            $this->as(self::USER_A)->getJson("/api/finance/transactions/{$id}")->json('data.amount')
        );
    }

    public function test_show_returns_the_transaction(): void
    {
        $id = $this->createTransaction(self::USER_A)->json('data.id');

        $this->as(self::USER_A)->getJson("/api/finance/transactions/{$id}")
            ->assertOk()
            ->assertJsonPath('data.id', $id)
            ->assertJsonPath('data.category', 'Food');
    }

    public function test_show_of_a_missing_transaction_is_404(): void
    {
        $this->as(self::USER_A)->getJson('/api/finance/transactions/999')
            ->assertNotFound()
            ->assertExactJson(['message' => 'Not found.']);
    }

    public function test_put_allows_a_partial_update(): void
    {
        $id = $this->createTransaction(self::USER_A)->json('data.id');

        $this->as(self::USER_A)->putJson("/api/finance/transactions/{$id}", ['amount' => 99.99])
            ->assertOk()
            ->assertJsonPath('data.amount', 99.99)
            ->assertJsonPath('data.type', 'expense')
            ->assertJsonPath('data.category', 'Food')
            ->assertJsonPath('data.occurred_on', '2026-11-15')
            ->assertJsonPath('data.note', 'Lunch');
    }

    public function test_put_can_change_every_field_and_clear_the_note(): void
    {
        $id = $this->createTransaction(self::USER_A)->json('data.id');

        $this->as(self::USER_A)->putJson("/api/finance/transactions/{$id}", [
            'type' => 'income',
            'amount' => 800,
            'category' => 'Part-time Job',
            'occurred_on' => '2026-10-31',
            'note' => null,
        ])
            ->assertOk()
            ->assertJsonPath('data.type', 'income')
            ->assertJsonPath('data.category', 'Part-time Job')
            ->assertJsonPath('data.occurred_on', '2026-10-31')
            ->assertJsonPath('data.note', null);

        $this->assertSame(800, (int) $this->as(self::USER_A)->getJson("/api/finance/transactions/{$id}")->json('data.amount'));
    }

    public function test_put_rejects_invalid_values_and_leaves_the_record_unchanged(): void
    {
        $id = $this->createTransaction(self::USER_A)->json('data.id');

        $this->as(self::USER_A)->putJson("/api/finance/transactions/{$id}", ['amount' => -1, 'category' => 'Rent'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['amount', 'category']);

        $this->as(self::USER_A)->putJson("/api/finance/transactions/{$id}", ['type' => null])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['type']);

        $this->as(self::USER_A)->getJson("/api/finance/transactions/{$id}")
            ->assertJsonPath('data.amount', 120.5)
            ->assertJsonPath('data.category', 'Food');
    }

    public function test_delete_returns_204_and_removes_the_transaction(): void
    {
        $id = $this->createTransaction(self::USER_A)->json('data.id');

        $response = $this->as(self::USER_A)->deleteJson("/api/finance/transactions/{$id}");
        $response->assertNoContent();
        $this->assertSame('', $response->getContent());

        $this->as(self::USER_A)->getJson("/api/finance/transactions/{$id}")->assertNotFound();
        $this->as(self::USER_A)->deleteJson("/api/finance/transactions/{$id}")->assertNotFound();
    }

    public static function invalidPayloads(): array
    {
        return [
            'missing type' => [['type' => null], 'type'],
            'unknown type' => [['type' => 'transfer'], 'type'],
            'missing amount' => [['amount' => null], 'amount'],
            'negative amount' => [['amount' => -5], 'amount'],
            'zero amount' => [['amount' => 0], 'amount'],
            'three decimals' => [['amount' => 10.123], 'amount'],
            'three decimals as string' => [['amount' => '10.123'], 'amount'],
            'non-numeric amount' => [['amount' => 'abc'], 'amount'],
            'exponent notation' => [['amount' => '1e3'], 'amount'],
            'amount too large' => [['amount' => '10000000000.00'], 'amount'],
            'missing category' => [['category' => null], 'category'],
            'unknown category' => [['category' => 'Rent'], 'category'],
            'category wrong case' => [['category' => 'food'], 'category'],
            'missing date' => [['occurred_on' => null], 'occurred_on'],
            'bad date format' => [['occurred_on' => '15/11/2026'], 'occurred_on'],
            'impossible date' => [['occurred_on' => '2026-02-30'], 'occurred_on'],
            'datetime instead of date' => [['occurred_on' => '2026-11-15T10:00:00Z'], 'occurred_on'],
            'note too long' => [['note' => 'x'.str_repeat('y', 255)], 'note'],
        ];
    }

    #[DataProvider('invalidPayloads')]
    public function test_create_rejects_invalid_input(array $overrides, string $field): void
    {
        $this->createTransaction(self::USER_A, $overrides)
            ->assertUnprocessable()
            ->assertJsonStructure(['message', 'errors' => [$field]]);

        $this->assertSame(0, DB::table('transactions')->count());
    }

    public function test_note_of_exactly_255_characters_is_accepted(): void
    {
        $this->createTransaction(self::USER_A, ['note' => str_repeat('n', 255)])->assertCreated();
    }
}
