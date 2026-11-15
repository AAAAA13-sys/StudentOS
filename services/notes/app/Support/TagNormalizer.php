<?php

namespace App\Support;

use Illuminate\Validation\ValidationException;

class TagNormalizer
{
    public const MAX_TAGS = 20;

    public const MAX_TAG_LENGTH = 30;

    public static function normalizeOne(string $tag): string
    {
        return mb_strtolower(trim($tag));
    }

    /**
     * Trim, lower-case, drop empties, de-duplicate; reject over-long tags or too many.
     *
     * @param  array<int, string>  $tags
     * @return array<int, string>
     *
     * @throws ValidationException
     */
    public static function normalize(array $tags): array
    {
        $normalized = [];
        foreach ($tags as $tag) {
            $tag = self::normalizeOne($tag);
            if ($tag === '') {
                continue;
            }
            if (mb_strlen($tag) > self::MAX_TAG_LENGTH) {
                throw ValidationException::withMessages([
                    'tags' => ['Each tag must not be greater than '.self::MAX_TAG_LENGTH.' characters.'],
                ]);
            }
            $normalized[$tag] = true;
        }

        if (count($normalized) > self::MAX_TAGS) {
            throw ValidationException::withMessages([
                'tags' => ['A note must not have more than '.self::MAX_TAGS.' tags.'],
            ]);
        }

        // Numeric-looking tags become int array keys; hand back strings.
        return array_map('strval', array_keys($normalized));
    }
}
