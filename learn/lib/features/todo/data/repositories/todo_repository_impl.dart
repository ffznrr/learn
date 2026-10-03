import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/todo_data_source.dart';

/// REPOSITORY IMPLEMENTATION = penghubung domain <-> data source.
///
/// Tugasnya:
/// 1. Memanggil data source (bisa lebih dari satu, misal remote + cache).
/// 2. Mengubah Model -> Entity.
/// 3. Menangkap Exception dan mengubahnya jadi Failure (lewat [Result]).
///
/// Perhatikan: class ini cuma kenal kontrak [TodoDataSource].
/// Mau datanya dari backend atau dari memori, kode di sini sama persis.
class TodoRepositoryImpl implements TodoRepository {
  final TodoDataSource dataSource;

  TodoRepositoryImpl(this.dataSource);

  @override
  Future<Result<List<Todo>>> getTodos() {
    return _guard(() async {
      final models = await dataSource.getTodos();
      return models.map((m) => m.toEntity()).toList();
    });
  }

  @override
  Future<Result<Todo>> addTodo(String title) {
    return _guard(() async {
      final model = await dataSource.addTodo(title);
      return model.toEntity();
    });
  }

  @override
  Future<Result<Todo>> toggleTodo(String id) {
    return _guard(() async {
      final model = await dataSource.toggleTodo(id);
      return model.toEntity();
    });
  }

  @override
  Future<Result<void>> deleteTodo(String id) {
    return _guard(() => dataSource.deleteTodo(id));
  }

  /// Helper: jalankan [action], ubah Exception jadi [Err] berisi Failure.
  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on NetworkException {
      return const Err(
        Failure('Tidak bisa terhubung ke server. Pastikan backend sudah jalan.'),
      );
    } on NotFoundException catch (e) {
      return Err(Failure(e.message));
    } on ServerException catch (e) {
      return Err(Failure(e.message));
    } catch (_) {
      return const Err(Failure('Terjadi kesalahan, coba lagi'));
    }
  }
}
