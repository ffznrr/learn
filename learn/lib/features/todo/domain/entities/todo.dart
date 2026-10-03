/// ENTITY = objek bisnis paling murni.
///
/// - Tidak tahu soal JSON, database, API, ataupun Flutter.
/// - Cuma berisi data + aturan bisnis sederhana (kalau ada).
/// - Ini "jantung" aplikasi; layer lain bergantung ke sini, bukan sebaliknya.
class Todo {
  final String id;
  final String title;
  final bool isDone;

  const Todo({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  Todo copyWith({String? title, bool? isDone}) {
    return Todo(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }
}
