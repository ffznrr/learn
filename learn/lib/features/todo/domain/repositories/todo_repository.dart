import '../../../../core/error/result.dart';
import '../entities/todo.dart';

/// REPOSITORY (kontrak / abstract) = "janji" domain tentang data apa saja
/// yang dibutuhkan, TANPA peduli datanya dari mana.
///
/// Implementasinya ada di layer data (`TodoRepositoryImpl`).
/// Inilah Dependency Inversion: domain yang menentukan aturan,
/// layer data yang menyesuaikan.
abstract interface class TodoRepository {
  Future<Result<List<Todo>>> getTodos();
  Future<Result<Todo>> addTodo(String title);
  Future<Result<Todo>> toggleTodo(String id);
  Future<Result<void>> deleteTodo(String id);
}
