import '../../../../core/error/result.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

/// USE CASE = satu aksi yang bisa dilakukan user / aplikasi.
/// "Ambil semua todo."
class GetTodos implements UseCase<List<Todo>, NoParams> {
  final TodoRepository repository;

  GetTodos(this.repository);

  @override
  Future<Result<List<Todo>>> call(NoParams params) {
    return repository.getTodos();
  }
}
