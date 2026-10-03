import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

/// "Tambah todo baru."
///
/// Contoh aturan bisnis yang tempatnya di use case: judul tidak boleh kosong.
/// Aturan ini berlaku di mana pun use case dipanggil (UI mana pun, test, dll).
class AddTodo implements UseCase<Todo, String> {
  final TodoRepository repository;

  AddTodo(this.repository);

  @override
  Future<Result<Todo>> call(String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return const Err(Failure('Judul todo tidak boleh kosong'));
    }
    return repository.addTodo(trimmed);
  }
}
