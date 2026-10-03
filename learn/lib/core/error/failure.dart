/// Failure = error yang sudah "diterjemahkan" jadi bahasa domain.
///
/// Layer data boleh melempar Exception (misal error network, error parsing),
/// tapi sebelum sampai ke domain/presentation, Exception itu diubah jadi
/// Failure supaya UI tidak perlu tahu detail teknis dari mana error berasal.
///
/// Implements [Exception] supaya bisa dibawa lewat `AsyncValue.error`
/// di Riverpod (lihat `TodoListNotifier.build`).
class Failure implements Exception {
  final String message;

  const Failure(this.message);

  @override
  String toString() => 'Failure($message)';
}
