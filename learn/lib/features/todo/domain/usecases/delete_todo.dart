import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/todo_repository.dart';

/// "Hapus todo."
class DeleteTodo implements UseCase<void, String> {
  final TodoRepository repository;

  DeleteTodo(this.repository);

  @override
  Future<Result<void>> call(String id) {
    return repository.deleteTodo(id);
  }
}
