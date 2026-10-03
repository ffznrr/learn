import '../models/todo_model.dart';

/// KONTRAK DATA SOURCE = method apa saja yang harus dimiliki sumber data todo.
///
/// Ada dua implementasi:
/// - [TodoRemoteDataSource] → ambil dari backend (todo-api) lewat HTTP
/// - [TodoLocalDataSource]  → simpan di memori (dipakai untuk test / offline)
///
/// Repository cuma kenal kontrak ini, jadi sumber data bisa ditukar
/// tanpa mengubah repository, use case, ataupun UI.
///
/// Implementasi boleh melempar exception dari `core/error/exceptions.dart`.
abstract interface class TodoDataSource {
  Future<List<TodoModel>> getTodos();
  Future<TodoModel> addTodo(String title);
  Future<TodoModel> toggleTodo(String id);
  Future<void> deleteTodo(String id);
}
