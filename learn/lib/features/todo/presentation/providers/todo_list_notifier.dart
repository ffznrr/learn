import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/todo.dart';
import 'todo_providers.dart';

/// State daftar todo yang ditampilkan UI.
///
/// `AsyncValue<List<Todo>>` otomatis punya 3 kemungkinan:
///   loading → lagi ambil data dari backend
///   data    → daftar todo
///   error   → gagal (isinya [Failure])
final todoListProvider = AsyncNotifierProvider<TodoListNotifier, List<Todo>>(
  TodoListNotifier.new,
  // Riverpod 3 otomatis retry provider yang gagal. Di sini dimatikan supaya
  // user yang menentukan kapan coba lagi (tombol "Coba lagi").
  retry: (retryCount, error) => null,
);

/// NOTIFIER = pengganti `TodoController` (ChangeNotifier) sebelumnya.
///
/// - `build()` dipanggil otomatis saat UI pertama kali butuh data.
/// - Method lain (add/toggle/delete) dipanggil UI lewat
///   `ref.read(todoListProvider.notifier)`.
/// - Seperti sebelumnya, notifier HANYA kenal use case.
class TodoListNotifier extends AsyncNotifier<List<Todo>> {
  @override
  Future<List<Todo>> build() async {
    final getTodos = ref.watch(getTodosProvider);
    final result = await getTodos(const NoParams());

    return switch (result) {
      Ok(:final data) => data,
      // Dilempar → Riverpod mengubahnya jadi AsyncError → UI tampilkan error.
      Err(:final failure) => throw failure,
    };
  }

  // Method di bawah return `null` kalau sukses, atau [Failure] kalau gagal.
  // Error-nya tidak disimpan di state supaya daftar todo tetap tampil;
  // UI cukup menampilkan SnackBar.

  Future<Failure?> addTodo(String title) {
    return _mutate(
      () => ref.read(addTodoProvider)(title),
      (todos, newTodo) => [...todos, newTodo],
    );
  }

  Future<Failure?> toggleTodo(String id) {
    return _mutate(
      () => ref.read(toggleTodoProvider)(id),
      (todos, updated) => [
        for (final todo in todos) todo.id == id ? updated : todo,
      ],
    );
  }

  Future<Failure?> deleteTodo(String id) {
    return _mutate(
      () => ref.read(deleteTodoProvider)(id),
      (todos, _) => todos.where((todo) => todo.id != id).toList(),
    );
  }

  /// Helper: jalankan use case, lalu kalau sukses update daftar todo
  /// pakai fungsi [update] (tanpa perlu fetch ulang semua data).
  Future<Failure?> _mutate<T>(
    Future<Result<T>> Function() action,
    List<Todo> Function(List<Todo> todos, T data) update,
  ) async {
    final result = await action();

    switch (result) {
      case Ok(:final data):
        // Setelah `await`, provider bisa saja sudah di-dispose / di-refresh.
        if (!ref.mounted) return null;

        final current = state.value;
        if (current == null) {
          // Belum ada data (misal sebelumnya error) → ambil ulang dari server.
          ref.invalidateSelf();
        } else {
          state = AsyncData(update(current, data));
        }
        return null;
      case Err(:final failure):
        return failure;
    }
  }
}
