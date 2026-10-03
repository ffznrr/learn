import 'package:flutter/foundation.dart';

/// Alamat backend (todo-api).
///
/// Default:
/// - Android emulator → http://10.0.2.2:3000 (alamat "localhost"-nya laptop
///   dilihat dari dalam emulator)
/// - iOS simulator, macOS, web, desktop → http://localhost:3000
///
/// HP fisik? Pakai IP laptop di jaringan yang sama, contoh:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
class ApiConfig {
  const ApiConfig._();

  static const _fromEnvironment = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_fromEnvironment.isNotEmpty) return _fromEnvironment;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
}
