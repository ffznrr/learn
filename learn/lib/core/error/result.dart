import 'failure.dart';

/// `Result<T>` = hasil sebuah operasi: kalau tidak [Ok], ya [Err].
///
/// Daripada pakai try-catch di mana-mana, repository mengembalikan Result.
/// Pemanggil "dipaksa" menangani dua kemungkinan lewat `switch`.
/// (Mirip `Either` di package dartz/fpdart, tapi versi sederhana tanpa package.)
sealed class Result<T> {
  const Result();
}

/// Operasi berhasil, membawa [data].
final class Ok<T> extends Result<T> {
  final T data;
  const Ok(this.data);
}

/// Operasi gagal, membawa [failure].
final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
