import '../error/result.dart';

/// Kontrak dasar untuk semua use case.
///
/// [T]      = tipe data yang dikembalikan kalau sukses.
/// [Params] = parameter yang dibutuhkan use case.
///
/// Setiap use case cuma punya SATU tugas, dipanggil lewat `call()`
/// sehingga bisa dipakai seperti fungsi: `await getTodos(NoParams())`.
abstract interface class UseCase<T, Params> {
  Future<Result<T>> call(Params params);
}

/// Dipakai untuk use case yang tidak butuh parameter.
class NoParams {
  const NoParams();
}
