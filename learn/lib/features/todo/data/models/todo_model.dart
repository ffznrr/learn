import '../../domain/entities/todo.dart';

/// MODEL = versi "teknis" dari entity.
///
/// Tugasnya: konversi dari/ke format penyimpanan (JSON, Map database, dll).
/// Entity tetap bersih; urusan serialisasi cukup di sini.
class TodoModel {
  final String id;
  final String title;
  final bool isDone;

  const TodoModel({
    required this.id,
    required this.title,
    required this.isDone,
  });

  /// Dari JSON (misal response API) -> Model
  factory TodoModel.fromJson(Map<String, dynamic> json) {
    return TodoModel(
      id: json['id'] as String,
      title: json['title'] as String,
      // Contoh: format API beda dengan entity (snake_case),
      // perbedaan ini cukup diurus di model.
      isDone: json['is_done'] as bool,
    );
  }

  /// Model -> JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'is_done': isDone,
      };

  /// Model -> Entity (data keluar ke domain)
  Todo toEntity() => Todo(id: id, title: title, isDone: isDone);

  /// Entity -> Model (data masuk dari domain)
  factory TodoModel.fromEntity(Todo todo) {
    return TodoModel(id: todo.id, title: todo.title, isDone: todo.isDone);
  }
}
