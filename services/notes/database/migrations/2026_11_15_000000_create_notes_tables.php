<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notes', function (Blueprint $table): void {
            $table->id();
            // Owner id from the JWT `sub`; users live in the Auth Service, so no foreign key.
            $table->unsignedBigInteger('user_id');
            $table->string('title', 200);
            $table->text('body');
            $table->timestamps();

            $table->index(['user_id', 'updated_at']);
        });

        Schema::create('note_tags', function (Blueprint $table): void {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->foreignId('note_id')->constrained('notes')->cascadeOnDelete();
            $table->string('tag', 30);

            $table->unique(['note_id', 'tag']);
            $table->index(['user_id', 'tag']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('note_tags');
        Schema::dropIfExists('notes');
    }
};
