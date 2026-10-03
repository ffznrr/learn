/// EXCEPTION = error teknis dari layer data.
///
/// Dilempar oleh data source, lalu ditangkap repository dan diubah jadi
/// [Failure]. Jadi layer domain & presentation tidak pernah melihat ini.
library;

/// Server membalas dengan status error (4xx / 5xx).
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, {this.statusCode});
}

/// Data yang diminta tidak ada (404).
class NotFoundException implements Exception {
  final String message;

  const NotFoundException(this.message);
}

/// Tidak bisa terhubung ke server (server mati, timeout, tidak ada internet).
class NetworkException implements Exception {
  const NetworkException();
}
