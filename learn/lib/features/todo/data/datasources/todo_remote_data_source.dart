import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../models/todo_model.dart';
import 'todo_data_source.dart';

/// Data source yang ambil data dari backend (todo-api / Express).
///
/// Endpoint yang dipakai:
///   GET    /api/todos              → daftar todo
///   POST   /api/todos              → tambah todo   (body: {"title": "..."})
///   PATCH  /api/todos/:id/toggle   → toggle is_done
///   DELETE /api/todos/:id          → hapus todo
///
/// Tugasnya cuma urusan HTTP & JSON. Error HTTP / jaringan diubah jadi
/// exception dari `core/error/exceptions.dart`; repository yang akan
/// menerjemahkannya jadi Failure.
class TodoRemoteDataSource implements TodoDataSource {
  final http.Client client;
  final String baseUrl;

  static const _timeout = Duration(seconds: 10);
  static const _jsonHeaders = {'Content-Type': 'application/json'};

  TodoRemoteDataSource({required this.client, required this.baseUrl});

  Uri _uri([String path = '']) => Uri.parse('$baseUrl/api/todos$path');

  @override
  Future<List<TodoModel>> getTodos() async {
    final response = await _send(() => client.get(_uri()));
    final list = _decode(response) as List<dynamic>;
    return list
        .map((json) => TodoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TodoModel> addTodo(String title) async {
    final response = await _send(
      () => client.post(
        _uri(),
        headers: _jsonHeaders,
        body: jsonEncode({'title': title}),
      ),
    );
    return TodoModel.fromJson(_decode(response) as Map<String, dynamic>);
  }

  @override
  Future<TodoModel> toggleTodo(String id) async {
    final response = await _send(() => client.patch(_uri('/$id/toggle')));
    return TodoModel.fromJson(_decode(response) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTodo(String id) async {
    await _send(() => client.delete(_uri('/$id')));
  }

  /// Jalankan request, lalu ubah kegagalan jadi exception yang "dikenal".
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw const NetworkException();
    } on http.ClientException {
      // Server mati / connection refused / tidak ada internet.
      throw const NetworkException();
    }

    if (response.statusCode == 404) {
      throw NotFoundException(
        _errorMessage(response) ?? 'Data tidak ditemukan',
      );
    }
    if (response.statusCode >= 400) {
      throw ServerException(
        _errorMessage(response) ?? 'Server error (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  /// Decode body sebagai UTF-8 (supaya emoji / huruf non-latin aman).
  Object? _decode(http.Response response) =>
      jsonDecode(utf8.decode(response.bodyBytes));

  /// Backend mengirim error dalam bentuk {"message": "..."}.
  String? _errorMessage(http.Response response) {
    try {
      final body = _decode(response);
      if (body is Map<String, dynamic> && body['message'] is String) {
        return body['message'] as String;
      }
    } on FormatException {
      // Body bukan JSON (misal halaman HTML dari proxy) → pakai pesan default.
    }
    return null;
  }
}
