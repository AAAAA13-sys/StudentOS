<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            // Tenant key. No foreign key: users live in the Auth Service's database.
            $table->unsignedBigInteger('user_id');
            $table->string('type', 10);
            $table->decimal('amount', 12, 2);
            $table->string('category', 30);
            $table->date('occurred_on');
            $table->string('note', 255)->nullable();
            $table->timestamps();

            // Serves both "all rows of a user" and the month range filter.
            $table->index(['user_id', 'occurred_on']);
        });

        // SQLite cannot add a CHECK with ALTER TABLE; request validation enforces it there.
        if (DB::connection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE transactions ADD CONSTRAINT transactions_amount_positive CHECK (amount > 0)');
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
