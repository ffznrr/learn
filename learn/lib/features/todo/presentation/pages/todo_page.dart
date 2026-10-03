import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/todo.dart';
import '../providers/todo_list_notifier.dart';
import '../widgets/todo_tile.dart';

/// PAGE = tampilan. Tugasnya hanya:
/// 1. Menampilkan state dari provider (`ref.watch`).
/// 2. Meneruskan aksi user ke notifier (`ref.read(...notifier)`).
/// Tidak ada logika bisnis / akses data di sini.
///
/// Pakai ConsumerStatefulWidget karena butuh TextEditingController
/// (kalau tidak butuh state lokal, cukup ConsumerWidget).
class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {
  final _textController = TextEditingController();
  bool _isSubmitting = false;

  TodoListNotifier get _notifier => ref.read(todoListProvider.notifier);

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final failure = await _notifier.addTodo(_textController.text);
    if (!mounted) return;

    setState(() => _isSubmitting = false);
    if (failure == null) {
      _textController.clear();
    } else {
      _showError(failure);
    }
  }

  /// Jalankan aksi (toggle/delete); kalau gagal tampilkan SnackBar.
  Future<void> _run(Future<Failure?> action) async {
    final failure = await action;
    if (failure != null && mounted) _showError(failure);
  }

  void _showError(Failure failure) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.message)));
  }

  void _reload() => ref.invalidate(todoListProvider);

  @override
  Widget build(BuildContext context) {
    // ref.watch = rebuild otomatis setiap state todoListProvider berubah.
    final todosAsync = ref.watch(todoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo — Clean Architecture'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInput(),
          Expanded(
            child: todosAsync.when(
              // false → spinner juga muncul waktu "Muat ulang" / "Coba lagi"
              skipLoadingOnRefresh: false,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildError(error),
              data: _buildList,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Mau ngapain hari ini?',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    final message =
        error is Failure ? error.message : 'Terjadi kesalahan, coba lagi';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: _reload,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Todo> todos) {
    if (todos.isEmpty) {
      return const Center(child: Text('Belum ada todo 🎉'));
    }
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return TodoTile(
          key: ValueKey(todo.id),
          todo: todo,
          onToggle: () => _run(_notifier.toggleTodo(todo.id)),
          onDelete: () => _run(_notifier.deleteTodo(todo.id)),
        );
      },
    );
  }
}
