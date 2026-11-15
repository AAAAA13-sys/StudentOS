<?php

namespace App\Http\Controllers;

use App\Enums\Category;
use Illuminate\Http\JsonResponse;

class CategoryController
{
    public function __invoke(): JsonResponse
    {
        return response()->json(['data' => Category::values()]);
    }
}
