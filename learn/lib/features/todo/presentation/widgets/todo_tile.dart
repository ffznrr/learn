import 'package:flutter/material.dart';

import '../../domain/entities/todo.dart';

/// Widget kecil yang cuma menampilkan satu Todo.
/// Tidak tahu soal controller — aksi dikirim lewat callback.
class TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TodoTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: todo.isDone,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.isDone ? TextDecoration.lineThrough : null,
          color: todo.isDone ? Theme.of(context).disabledColor : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Hapus',
        onPressed: onDelete,
      ),
      onTap: onToggle,
    );
  }
}
