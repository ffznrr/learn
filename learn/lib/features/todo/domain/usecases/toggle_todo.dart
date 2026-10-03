import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

/// "Tandai todo selesai / belum selesai."
class ToggleTodo implements UseCase<Todo, String> {
  final TodoRepository repository;

  ToggleTodo(this.repository);

  @override
  Future<Result<Todo>> call(String id) {
    return repository.toggleTodo(id);
  }
}
