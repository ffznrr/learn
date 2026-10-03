import 'package:flutter_test/flutter_test.dart';

import 'package:learn/core/error/failure.dart';
import 'package:learn/core/error/result.dart';
import 'package:learn/features/todo/domain/entities/todo.dart';
import 'package:learn/features/todo/domain/repositories/todo_repository.dart';
import 'package:learn/features/todo/domain/usecases/add_todo.dart';

/// Repository palsu. Karena use case cuma bergantung ke KONTRAK
/// (TodoRepository), kita bisa mengetes aturan bisnis tanpa
/// database / API / Flutter UI sama sekali.
class FakeTodoRepository implements TodoRepository {
  final List<String> addedTitles = [];

  @override
  Future<Result<Todo>> addTodo(String title) async {
    addedTitles.add(title);
    return Ok(Todo(id: 'x', title: title));
  }

  @override
  Future<Result<List<Todo>>> getTodos() async => const Ok([]);

  @override
  Future<Result<Todo>> toggleTodo(String id) async =>
      const Err(Failure('not used'));

  @override
  Future<Result<void>> deleteTodo(String id) async => const Ok(null);
}

void main() {
  late FakeTodoRepository repository;
  late AddTodo addTodo;

  setUp(() {
    repository = FakeTodoRepository();
    addTodo = AddTodo(repository);
  });

  test('judul di-trim lalu diteruskan ke repository', () async {
    final result = await addTodo('  Belajar  ');

    expect(result, isA<Ok<Todo>>());
    expect((result as Ok<Todo>).data.title, 'Belajar');
    expect(repository.addedTitles, ['Belajar']);
  });

  test('judul kosong menghasilkan Err dan TIDAK memanggil repository',
      () async {
    final result = await addTodo('   ');

    expect(result, isA<Err<Todo>>());
    expect(repository.addedTitles, isEmpty);
  });
}
