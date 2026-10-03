import '../../../../core/error/exceptions.dart';
import '../models/todo_model.dart';
import 'todo_data_source.dart';

/// Data source in-memory (tanpa backend).
///
/// Dulu ini sumber data utama aplikasi. Sekarang app pakai
/// [TodoRemoteDataSource], dan class ini dipakai di widget test
/// supaya test tidak butuh server.
///
/// Dibuat "mirip API": async + kerja dengan Map JSON.
class TodoLocalDataSource implements TodoDataSource {
  /// Anggap ini "database" yang menyimpan JSON.
  final List<Map<String, dynamic>> _storage = [
    {'id': '1', 'title': 'Belajar Clean Architecture', 'is_done': false},
    {'id': '2', 'title': 'Install Flutter pakai fvm', 'is_done': true},
  ];

  int _nextId = 3;

  /// Simulasi latency seperti request ke server / database.
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 300));

  @override
  Future<List<TodoModel>> getTodos() async {
    await _delay();
    return _storage.map(TodoModel.fromJson).toList();
  }

  @override
  Future<TodoModel> addTodo(String title) async {
    await _delay();
    final model = TodoModel(id: '${_nextId++}', title: title, isDone: false);
    _storage.add(model.toJson());
    return model;
  }

  @override
  Future<TodoModel> toggleTodo(String id) async {
    await _delay();
    final index = _indexOf(id);
    final current = TodoModel.fromJson(_storage[index]);
    final updated = TodoModel(
      id: current.id,
      title: current.title,
      isDone: !current.isDone,
    );
    _storage[index] = updated.toJson();
    return updated;
  }

  @override
  Future<void> deleteTodo(String id) async {
    await _delay();
    _storage.removeAt(_indexOf(id));
  }

  int _indexOf(String id) {
    final index = _storage.indexWhere((json) => json['id'] == id);
    if (index == -1) {
      throw NotFoundException('Todo dengan id $id tidak ditemukan');
    }
    return index;
  }
}
