<?php

namespace Tests\Unit;

use App\Support\Money;
use PHPUnit\Framework\TestCase;

class MoneyTest extends TestCase
{
    public function test_normalise_handles_every_shape_a_database_driver_returns(): void
    {
        $this->assertSame('1320.50', Money::normalise('1320.50'));   // PostgreSQL numeric
        $this->assertSame('1320.50', Money::normalise('1320.5'));
        $this->assertSame('5000.00', Money::normalise(5000));        // SQLite integer
        $this->assertSame('0.30', Money::normalise(0.1 + 0.2));      // SQLite real
        $this->assertSame('99.99', Money::normalise(33.33 + 33.33 + 33.33));
        $this->assertSame('9999999999.99', Money::normalise(9999999999.99));
    }

    public function test_normalise_rejects_non_numbers(): void
    {
        $this->expectException(\InvalidArgumentException::class);

        Money::normalise('abc');
    }

    public function test_integer_cents_fallback_is_exact(): void
    {
        $this->assertSame('0.30', Money::addWithCents('0.10', '0.20'));
        $this->assertSame('3679.50', Money::subtractWithCents('5000.00', '1320.50'));
        $this->assertSame('-99.69', Money::subtractWithCents('0.30', '99.99'));
        $this->assertSame('-0.05', Money::subtractWithCents('0.00', '0.05'));
        $this->assertSame('0.00', Money::subtractWithCents('12.34', '12.34'));
    }

    public function test_public_arithmetic_agrees_with_the_fallback(): void
    {
        foreach ([['0.10', '0.20'], ['5000.00', '1320.50'], ['0.30', '99.99'], ['9999999999.99', '0.01']] as [$a, $b]) {
            $this->assertSame(Money::addWithCents($a, $b), Money::add($a, $b));
            $this->assertSame(Money::subtractWithCents($a, $b), Money::subtract($a, $b));
        }
    }
}
