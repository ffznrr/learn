import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:learn/core/error/exceptions.dart';
import 'package:learn/features/todo/data/datasources/todo_data_source.dart';
import 'package:learn/features/todo/data/datasources/todo_local_data_source.dart';
import 'package:learn/features/todo/data/models/todo_model.dart';
import 'package:learn/features/todo/presentation/providers/todo_providers.dart';
import 'package:learn/main.dart';

/// Bungkus app dengan ProviderScope yang data source-nya di-override.
/// Seluruh app tetap sama, cuma sumber datanya yang ditukar → tidak butuh backend.
Widget createTestApp(TodoDataSource dataSource) {
  return ProviderScope(
    overrides: [todoDataSourceProvider.overrideWithValue(dataSource)],
    child: const MyApp(),
  );
}

/// Data source yang selalu gagal, seolah-olah backend mati.
class OfflineDataSource implements TodoDataSource {
  @override
  Future<List<TodoModel>> getTodos() async => throw const NetworkException();
  @override
  Future<TodoModel> addTodo(String title) async =>
      throw const NetworkException();
  @override
  Future<TodoModel> toggleTodo(String id) async =>
      throw const NetworkException();
  @override
  Future<void> deleteTodo(String id) async => throw const NetworkException();
}

/// TodoLocalDataSource punya delay 300 ms. Majukan waktu dulu supaya
/// request-nya selesai, baru tunggu semua animasi beres.
Future<void> waitForDataSource(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Menampilkan todo awal lalu bisa menambah todo baru',
      (tester) async {
    await tester.pumpWidget(createTestApp(TodoLocalDataSource()));

    // Awalnya loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Tunggu simulasi delay data source selesai
    await tester.pumpAndSettle();
    expect(find.text('Belajar Clean Architecture'), findsOneWidget);

    // Tambah todo
    await tester.enterText(find.byType(TextField), 'Todo dari test');
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Todo dari test'), findsOneWidget);
  });

  testWidgets('Bisa toggle dan hapus todo', (tester) async {
    await tester.pumpWidget(createTestApp(TodoLocalDataSource()));
    await tester.pumpAndSettle();

    // Todo pertama awalnya belum selesai
    final firstCheckbox = find.byType(Checkbox).first;
    expect(tester.widget<Checkbox>(firstCheckbox).value, isFalse);

    await tester.tap(firstCheckbox);
    await waitForDataSource(tester);
    expect(tester.widget<Checkbox>(firstCheckbox).value, isTrue);

    await tester.tap(find.byTooltip('Hapus').first);
    await waitForDataSource(tester);
    expect(find.text('Belajar Clean Architecture'), findsNothing);
  });

  testWidgets('Judul kosong menampilkan pesan error', (tester) async {
    await tester.pumpWidget(createTestApp(TodoLocalDataSource()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Judul todo tidak boleh kosong'), findsOneWidget);
  });

  testWidgets('Backend mati → tampil pesan error dan tombol coba lagi',
      (tester) async {
    await tester.pumpWidget(createTestApp(OfflineDataSource()));
    await tester.pumpAndSettle();

    expect(
      find.text('Tidak bisa terhubung ke server. Pastikan backend sudah jalan.'),
      findsOneWidget,
    );
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
