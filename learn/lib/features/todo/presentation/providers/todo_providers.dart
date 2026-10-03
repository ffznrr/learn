import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../data/datasources/todo_data_source.dart';
import '../../data/datasources/todo_remote_data_source.dart';
import '../../data/repositories/todo_repository_impl.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../domain/usecases/add_todo.dart';
import '../../domain/usecases/delete_todo.dart';
import '../../domain/usecases/get_todos.dart';
import '../../domain/usecases/toggle_todo.dart';

/// DEPENDENCY INJECTION pakai Riverpod (pengganti `injection.dart`).
///
/// Setiap provider "menyediakan" satu objek, dan bisa meminta objek lain
/// lewat `ref.watch`. Rantainya:
///
///   http.Client → DataSource → Repository → UseCase → TodoListNotifier
///
/// Keuntungannya: provider mana pun bisa di-override. Contoh di test:
///   ProviderScope(
///     overrides: [todoDataSourceProvider.overrideWithValue(TodoLocalDataSource())],
///     child: MyApp(),
///   )
/// → seluruh app pakai data lokal, tanpa backend, tanpa ubah kode lain.
///
/// Catatan: domain & data TIDAK import Riverpod sama sekali.
/// Riverpod cuma dipakai di sini (presentation) untuk menyambungkan semuanya.

// ---------------- Data layer ----------------

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final todoDataSourceProvider = Provider<TodoDataSource>((ref) {
  return TodoRemoteDataSource(
    client: ref.watch(httpClientProvider),
    baseUrl: ApiConfig.baseUrl,
  );
});

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  return TodoRepositoryImpl(ref.watch(todoDataSourceProvider));
});

// ---------------- Domain layer (use cases) ----------------

final getTodosProvider = Provider<GetTodos>((ref) {
  return GetTodos(ref.watch(todoRepositoryProvider));
});

final addTodoProvider = Provider<AddTodo>((ref) {
  return AddTodo(ref.watch(todoRepositoryProvider));
});

final toggleTodoProvider = Provider<ToggleTodo>((ref) {
  return ToggleTodo(ref.watch(todoRepositoryProvider));
});

final deleteTodoProvider = Provider<DeleteTodo>((ref) {
  return DeleteTodo(ref.watch(todoRepositoryProvider));
});
