import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:learn/core/error/exceptions.dart';
import 'package:learn/features/todo/data/datasources/todo_remote_data_source.dart';

/// MockClient (bawaan package http) = server palsu.
/// Kita bisa cek request yang dikirim & atur response-nya,
/// tanpa perlu menjalankan backend beneran.
http.Response jsonResponse(Object? body, int statusCode) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

TodoRemoteDataSource createDataSource(MockClientHandler handler) {
  return TodoRemoteDataSource(
    client: MockClient(handler),
    baseUrl: 'http://api.test',
  );
}

void main() {
  group('getTodos', () {
    test('GET /api/todos lalu parse JSON jadi TodoModel', () async {
      final dataSource = createDataSource((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'http://api.test/api/todos');
        return jsonResponse([
          {'id': 'a', 'title': 'Halo 👋', 'is_done': true, 'created_at': 'x'},
        ], 200);
      });

      final todos = await dataSource.getTodos();

      expect(todos, hasLength(1));
      expect(todos.first.id, 'a');
      expect(todos.first.title, 'Halo 👋');
      expect(todos.first.isDone, isTrue);
    });

    test('server tidak bisa dihubungi → NetworkException', () async {
      final dataSource = createDataSource((request) async {
        throw http.ClientException('Connection refused', request.url);
      });

      expect(dataSource.getTodos(), throwsA(isA<NetworkException>()));
    });

    test('500 → ServerException dengan pesan dari server', () async {
      final dataSource = createDataSource(
        (_) async => jsonResponse({'message': 'Server lagi error'}, 500),
      );

      expect(
        dataSource.getTodos(),
        throwsA(
          isA<ServerException>()
              .having((e) => e.message, 'message', 'Server lagi error')
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });

  test('addTodo kirim POST dengan body JSON', () async {
    final dataSource = createDataSource((request) async {
      expect(request.method, 'POST');
      expect(request.headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(request.body), {'title': 'Belajar'});
      return jsonResponse(
        {'id': 'b', 'title': 'Belajar', 'is_done': false},
        201,
      );
    });

    final todo = await dataSource.addTodo('Belajar');
    expect(todo.id, 'b');
  });

  test('toggleTodo kirim PATCH /api/todos/:id/toggle', () async {
    final dataSource = createDataSource((request) async {
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/todos/b/toggle');
      return jsonResponse({'id': 'b', 'title': 'X', 'is_done': true}, 200);
    });

    final todo = await dataSource.toggleTodo('b');
    expect(todo.isDone, isTrue);
  });

  test('deleteTodo 404 → NotFoundException dengan pesan dari server', () async {
    final dataSource = createDataSource((request) async {
      expect(request.method, 'DELETE');
      return jsonResponse({'message': 'Todo tidak ditemukan'}, 404);
    });

    expect(
      dataSource.deleteTodo('zzz'),
      throwsA(
        isA<NotFoundException>()
            .having((e) => e.message, 'message', 'Todo tidak ditemukan'),
      ),
    );
  });
}
