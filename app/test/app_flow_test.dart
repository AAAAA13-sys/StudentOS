import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentos/core/db/app_database.dart';
import 'package:studentos/core/storage/token_storage.dart';
import 'package:studentos/main.dart';

class InMemoryTokenStorage extends TokenStorage {
  InMemoryTokenStorage([this._token]) : super(const FlutterSecureStorage());
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async {
    _token = token;
  }

  @override
  Future<void> clear() async {
    _token = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late InMemoryTokenStorage tokenStorage;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    tokenStorage = InMemoryTokenStorage();
  });

  tearDown(() async {
    await database.close();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        tokenStorageProvider.overrideWithValue(tokenStorage),
      ],
      child: const StudentOSApp(),
    );
  }

  testWidgets('App launches and renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    // Allow session restoration microtasks to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.text('StudentOS'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('Login shows validation error when submitted empty', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    final Finder signInButton = find.widgetWithText(FilledButton, 'Sign In');
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email'), findsOneWidget);
  });

  testWidgets('Can navigate to register screen and back', (WidgetTester tester) async {
    await tester.pumpWidget(createTestWidget());

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    final Finder createAccountButton = find.text('Create Account');
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();

    expect(find.text('Join StudentOS today'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3)); // Name, Email, Password

    final Finder backButton = find.byIcon(Icons.arrow_back_rounded);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.text('Your all-in-one productivity suite'), findsOneWidget);
  });
}
