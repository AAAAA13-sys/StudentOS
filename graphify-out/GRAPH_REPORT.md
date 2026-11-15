# Graph Report - StudentOS  (2026-11-15)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 1333 nodes · 2007 edges · 96 communities (42 shown, 54 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `e6c1857a`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- environment
- Illuminate\Database\Schema\Blueprint
- app_colors.dart
- auth/composer.json
- calendar/composer.json
- notes/composer.json
- Illuminate\Support\Str
- Illuminate\Database\Eloquent\Builder
- app_spacing.dart
- auth/package.json
- gateway/bootstrap/app.php
- finance/composer.json
- gateway/composer.json
- Money
- dependencies
- auth_state.dart
- cache_store.dart
- auth_controller.dart
- NoteSearchTest
- api_exception.dart
- Illuminate\Http\JsonResponse
- Carbon\CarbonImmutable
- app_theme.dart
- TestCase
- finance/app/Http/Middleware/AuthenticateJwt.php
- Illuminate\Support\ServiceProvider
- app_database.dart
- Symfony\Component\HttpFoundation\Response
- Illuminate\Foundation\Testing\TestCase
- JsonError
- Illuminate\Http\Request
- TransactionController.php
- api_client.dart
- NoteCrudTest
- auth_repository.dart
- Illuminate\Support\Facades\Route
- TransactionCrudTest
- Category
- TargetResolver
- TenantIsolationTest
- package:flutter_riverpod/flutter_riverpod.dart
- x-service-env
- ProxyController.php
- SummaryTest
- TransactionListTest
- HealthAndAuthTest
- token_storage.dart
- depends_on
- SummaryController.php
- HttpConventionsTest
- TenantIsolationTest
- app_config.dart
- e2e.sh
- analysis_options.yaml
- CurrentUser
- .__invoke
- MainActivity.kt
- init-dbs.sh
- ModuleColors
- calendar/app/Http/Controllers/Controller.php
- notes/app/Http/Controllers/Controller.php

## God Nodes (most connected - your core abstractions)
1. `NoteSearchTest` - 26 edges
2. `TestCase` - 24 edges
3. `NoteCrudTest` - 17 edges
4. `TransactionCrudTest` - 16 edges
5. `environment` - 16 edges
6. `environment` - 16 edges
7. `environment` - 16 edges
8. `environment` - 16 edges
9. `SummaryTest` - 14 edges
10. `environment` - 14 edges

## Surprising Connections (you probably didn't know these)
- `NoteSearchTest` --inherits--> `TestCase`  [EXTRACTED]
  services/notes/tests/Feature/NoteSearchTest.php → services/auth/tests/TestCase.php
- `EventController` --inherits--> `Controller`  [EXTRACTED]
  services/calendar/app/Http/Controllers/EventController.php → services/auth/app/Http/Controllers/Controller.php
- `HealthController` --inherits--> `Controller`  [EXTRACTED]
  services/calendar/app/Http/Controllers/HealthController.php → services/auth/app/Http/Controllers/Controller.php
- `WidgetController` --inherits--> `Controller`  [EXTRACTED]
  services/calendar/app/Http/Controllers/WidgetController.php → services/auth/app/Http/Controllers/Controller.php
- `HttpConventionsTest` --inherits--> `TestCase`  [EXTRACTED]
  services/finance/tests/Feature/HttpConventionsTest.php → services/auth/tests/TestCase.php

## Import Cycles
- None detected.

## Communities (96 total, 54 thin omitted)

### Community 0 - "environment"
Cohesion: 0.06
Nodes (75): build, depends_on, environment, healthcheck, context, dockerfile, build, depends_on (+67 more)

### Community 1 - "Illuminate\Database\Schema\Blueprint"
Cohesion: 0.06
Nodes (27): {closure#1}(), {closure#2}(), {closure#3}(), {closure#1}(), {closure#2}(), {closure#1}(), {closure#2}(), {closure#3}() (+19 more)

### Community 2 - "app_colors.dart"
Cohesion: 0.04
Nodes (48): amber100, amber300, amber700, amber800, amber900, amber950, AppColors, calendar (+40 more)

### Community 3 - "auth/composer.json"
Cohesion: 0.04
Nodes (47): pestphp/pest-plugin, php-http/discovery, autoload, autoload-dev, psr-4, psr-4, config, allow-plugins (+39 more)

### Community 4 - "calendar/composer.json"
Cohesion: 0.04
Nodes (47): pestphp/pest-plugin, php-http/discovery, autoload, autoload-dev, psr-4, psr-4, config, allow-plugins (+39 more)

### Community 5 - "notes/composer.json"
Cohesion: 0.04
Nodes (47): pestphp/pest-plugin, php-http/discovery, autoload, autoload-dev, psr-4, psr-4, config, allow-plugins (+39 more)

### Community 6 - "Illuminate\Support\Str"
Cohesion: 0.07
Nodes (6): User, UserFactory, DatabaseSeeder, User, UserFactory, DatabaseSeeder

### Community 7 - "Illuminate\Database\Eloquent\Builder"
Cohesion: 0.08
Nodes (24): BelongsToUser, {closure#1}(), {closure#2}(), {closure#1}(), {closure#2}(), {closure#4}(), {closure#5}(), CurrentUser (+16 more)

### Community 8 - "app_spacing.dart"
Cohesion: 0.05
Nodes (33): AppDurations, AppRadius, AppSizes, AppSpacing, buttonHeight, card, extraLarge, fast (+25 more)

### Community 9 - "auth/package.json"
Cohesion: 0.08
Nodes (34): devDependencies, axios@^1.11.0, concurrently@^9.0.1, laravel-vite-plugin@^2.0.0, tailwindcss@^4.0.0, @tailwindcss/vite@^4.0.0, vite@^7.0.7, axios (+26 more)

### Community 10 - "gateway/bootstrap/app.php"
Cohesion: 0.10
Nodes (13): {closure#1}(), {closure#2}(), {closure#1}(), {closure#2}(), {closure#1}(), {closure#2}(), {closure#3}(), {closure#4}() (+5 more)

### Community 11 - "finance/composer.json"
Cohesion: 0.06
Nodes (31): autoload, autoload-dev, psr-4, psr-4, config, optimize-autoloader, preferred-install, sort-packages (+23 more)

### Community 12 - "gateway/composer.json"
Cohesion: 0.06
Nodes (31): autoload, autoload-dev, psr-4, psr-4, config, optimize-autoloader, preferred-install, sort-packages (+23 more)

### Community 13 - "Money"
Cohesion: 0.13
Nodes (4): ExampleTest, ExampleTest, Money, MoneyTest

### Community 14 - "dependencies"
Cohesion: 0.07
Nodes (26): dependencies, cupertino_icons, dio, drift, drift_flutter, flutter, flutter_riverpod, flutter_secure_storage (+18 more)

### Community 15 - "auth_state.dart"
Cohesion: 0.10
Nodes (17): Authenticated, AuthState, AuthUnknown, hashCode, isOffline, operator, Unauthenticated, user (+9 more)

### Community 16 - "cache_store.dart"
Cohesion: 0.08
Nodes (15): Cached, CacheHit, CacheStore, cacheStoreProvider, clearAll, data, _database, isOffline (+7 more)

### Community 17 - "auth_controller.dart"
Cohesion: 0.08
Nodes (14): authControllerProvider, build, _cachedUserKey, _endSession, login, logout, _readCachedUser, register (+6 more)

### Community 19 - "api_exception.dart"
Cohesion: 0.11
Nodes (18): allowsCacheFallback, ApiException, errorFor, fieldErrors, fromDio, fromResponse, message, NetworkException (+10 more)

### Community 20 - "Illuminate\Http\JsonResponse"
Cohesion: 0.14
Nodes (5): Controller, HealthController, HealthController, NoteController, TagNormalizer

### Community 21 - "Carbon\CarbonImmutable"
Cohesion: 0.19
Nodes (5): {closure#1}(), WidgetController, OccurrenceFinder, RecurrenceExpander, IsoDateTime

### Community 22 - "app_theme.dart"
Cohesion: 0.10
Nodes (11): AppTheme, AppThemeContext, _build, colors, dark, _darkScheme, light, _lightScheme (+3 more)

### Community 23 - "TestCase"
Cohesion: 0.17
Nodes (3): ExampleTest, TestCase, ExampleTest

### Community 24 - "finance/app/Http/Middleware/AuthenticateJwt.php"
Cohesion: 0.13
Nodes (4): AuthenticateJwt, AuthenticateJwt, AuthenticateJwt, CurrentUser

### Community 25 - "Illuminate\Support\ServiceProvider"
Cohesion: 0.13
Nodes (4): AppServiceProvider, AppServiceProvider, AppServiceProvider, AppServiceProvider

### Community 26 - "app_database.dart"
Cohesion: 0.11
Nodes (9): AppDatabase, appDatabaseProvider, CacheEntries, database, key, payload, primaryKey, savedAt (+1 more)

### Community 27 - "Symfony\Component\HttpFoundation\Response"
Cohesion: 0.21
Nodes (5): AuthenticateJwt, ForceJsonResponse, ForceJsonResponse, LimitBodySize, ForceJsonResponse

### Community 28 - "Illuminate\Foundation\Testing\TestCase"
Cohesion: 0.17
Nodes (4): TestCase, TestCase, TestCase, TestCase

### Community 29 - "JsonError"
Cohesion: 0.19
Nodes (4): JsonError, ThrottleAuthEntry, {closure#4}(), {closure#1}()

### Community 30 - "Illuminate\Http\Request"
Cohesion: 0.28
Nodes (4): EventController, EventResource, Event, IsoDateTimeRule

### Community 32 - "api_client.dart"
Cohesion: 0.13
Nodes (9): apiClientProvider, _authenticatedKey, delete, _dio, post, put, _send, _tokenSentKey (+1 more)

### Community 34 - "auth_repository.dart"
Cohesion: 0.14
Nodes (11): ApiClient, _api, AuthRepository, AuthSession, login, logout, me, _parseSession (+3 more)

### Community 37 - "Category"
Cohesion: 0.17
Nodes (9): Category, Allowance, Entertainment, Food, Other, PartTimeJob, School, Transport (+1 more)

### Community 38 - "TargetResolver"
Cohesion: 0.24
Nodes (3): Target, TargetResolver, ResolveTarget

### Community 40 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.17
Nodes (8): build, notify, UnauthorizedSignal, unauthorizedSignalProvider, sessionCacheStoreProvider, tokenStorageProvider, AuthController, authRepositoryProvider

### Community 41 - "x-service-env"
Cohesion: 0.17
Nodes (12): x-service-env, APP_DEBUG, APP_ENV, APP_KEY, CACHE_STORE, DB_CONNECTION, DB_HOST, DB_PORT (+4 more)

### Community 46 - "token_storage.dart"
Cohesion: 0.20
Nodes (6): clear, read, _storage, _tokenKey, TokenStorage, write

### Community 47 - "depends_on"
Cohesion: 0.22
Nodes (9): condition, condition, auth, calendar, finance, notes, condition, depends_on (+1 more)

### Community 49 - "SummaryController.php"
Cohesion: 0.22
Nodes (5): TransactionType, Expense, Income, SummaryController, Month

### Community 52 - "app_config.dart"
Cohesion: 0.29
Nodes (4): apiBaseUrl, AppConfig, connectTimeout, receiveTimeout

### Community 54 - "e2e.sh"
Cohesion: 0.62
Nodes (6): check(), expect_code(), expect_eq(), jget(), req(), e2e.sh script

### Community 55 - "analysis_options.yaml"
Cohesion: 0.33
Nodes (5): analyzer, exclude, include, linter, rules

## Knowledge Gaps
- **189 isolated node(s):** `hashCode`, `isOffline`, `operator`, `user`, `createdAt` (+184 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 667 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **54 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `TestCase` connect `TestCase` to `NoteCrudTest`, `TransactionCrudTest`, `TenantIsolationTest`, `SummaryTest`, `TransactionListTest`, `HealthAndAuthTest`, `HttpConventionsTest`, `TenantIsolationTest`, `NoteSearchTest`, `Illuminate\Foundation\Testing\TestCase`?**
  _High betweenness centrality (0.028) - this node is a cross-community bridge._
- **What connects `hashCode`, `isOffline`, `operator` to the rest of the system?**
  _189 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `environment` be split into smaller, more focused modules?**
  _Cohesion score 0.05754385964912281 - nodes in this community are weakly interconnected._
- **Why does `CurrentUser` connect `Illuminate\Database\Eloquent\Builder` to `finance/app/Http/Middleware/AuthenticateJwt.php`, `Illuminate\Support\ServiceProvider`, `TenantIsolationTest`, `TestCase`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Should `Illuminate\Database\Schema\Blueprint` be split into smaller, more focused modules?**
  _Cohesion score 0.055811571940604196 - nodes in this community are weakly interconnected._
- **Why does `ModuleColors` connect `ModuleColors` to `app_colors.dart`, `app_theme.dart`, `auth_state.dart`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Should `app_colors.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.038461538461538464 - nodes in this community are weakly interconnected._