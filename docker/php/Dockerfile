# Shared recipe for every StudentOS Laravel service.
# Build context is the service directory (see docker-compose.yml).
FROM php:8.3-cli-alpine

RUN apk add --no-cache libpq unzip \
    && apk add --no-cache --virtual .build-deps libpq-dev \
    && docker-php-ext-install pdo_pgsql \
    && apk del .build-deps

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --no-interaction --prefer-dist

COPY . .
RUN composer dump-autoload --optimize --no-dev \
    && mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && php artisan package:discover --ansi

ENV PHP_CLI_SERVER_WORKERS=4
EXPOSE 8000

CMD ["sh", "-c", "php artisan migrate --force && php artisan serve --host=0.0.0.0 --port=8000"]
