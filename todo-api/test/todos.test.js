import assert from 'node:assert/strict';
import { afterEach, beforeEach, describe, it } from 'node:test';

import { createApp } from '../src/app.js';
import { InMemoryTodoRepository } from '../src/modules/todo/todo.repository.js';

// Tiap test dapat server + repository baru (InMemory) di port acak,
// jadi test tidak saling mengganggu dan tidak menyentuh file data asli.
let server;
let baseUrl;

beforeEach(async () => {
  const app = createApp({
    todoRepository: new InMemoryTodoRepository(),
    logRequests: false,
  });
  server = await new Promise((resolve) => {
    const s = app.listen(0, () => resolve(s));
  });
  baseUrl = `http://127.0.0.1:${server.address().port}`;
});

afterEach(async () => {
  await new Promise((resolve) => server.close(resolve));
});

/** Helper kecil untuk kirim request & parse JSON response. */
async function api(method, path, body) {
  const response = await fetch(baseUrl + path, {
    method,
    headers: body === undefined ? {} : { 'content-type': 'application/json' },
    body: body === undefined ? undefined : typeof body === 'string' ? body : JSON.stringify(body),
  });
  const text = await response.text();
  return { status: response.status, body: text ? JSON.parse(text) : null };
}

describe('GET /health', () => {
  it('mengembalikan status ok', async () => {
    const res = await api('GET', '/health');
    assert.equal(res.status, 200);
    assert.deepEqual(res.body, { status: 'ok' });
  });
});

describe('POST /api/todos', () => {
  it('membuat todo baru (judul di-trim, is_done false)', async () => {
    const res = await api('POST', '/api/todos', { title: '  Belajar Express  ' });

    assert.equal(res.status, 201);
    assert.equal(res.body.title, 'Belajar Express');
    assert.equal(res.body.is_done, false);
    assert.equal(typeof res.body.id, 'string');
    assert.ok(res.body.created_at);

    const list = await api('GET', '/api/todos');
    assert.equal(list.body.length, 1);
  });

  it('menolak judul kosong', async () => {
    const res = await api('POST', '/api/todos', { title: '   ' });
    assert.equal(res.status, 400);
    assert.equal(res.body.message, 'Judul todo tidak boleh kosong');
  });

  it('menolak body tanpa title', async () => {
    const res = await api('POST', '/api/todos', {});
    assert.equal(res.status, 400);
  });

  it('menolak judul lebih dari 100 karakter', async () => {
    const res = await api('POST', '/api/todos', { title: 'a'.repeat(101) });
    assert.equal(res.status, 400);
  });

  it('menolak body yang bukan JSON valid', async () => {
    const res = await api('POST', '/api/todos', '{ ini bukan json');
    assert.equal(res.status, 400);
    assert.equal(res.body.message, 'Body request harus berupa JSON yang valid');
  });
});

describe('PATCH /api/todos/:id/toggle', () => {
  it('membalik status is_done', async () => {
    const { body: todo } = await api('POST', '/api/todos', { title: 'Toggle aku' });

    const first = await api('PATCH', `/api/todos/${todo.id}/toggle`);
    assert.equal(first.status, 200);
    assert.equal(first.body.is_done, true);

    const second = await api('PATCH', `/api/todos/${todo.id}/toggle`);
    assert.equal(second.body.is_done, false);
  });

  it('404 kalau id tidak ada', async () => {
    const res = await api('PATCH', '/api/todos/tidak-ada/toggle');
    assert.equal(res.status, 404);
  });
});

describe('PATCH /api/todos/:id', () => {
  it('mengubah title dan is_done', async () => {
    const { body: todo } = await api('POST', '/api/todos', { title: 'Lama' });

    const res = await api('PATCH', `/api/todos/${todo.id}`, { title: 'Baru', is_done: true });
    assert.equal(res.status, 200);
    assert.equal(res.body.title, 'Baru');
    assert.equal(res.body.is_done, true);
  });

  it('menolak is_done yang bukan boolean', async () => {
    const { body: todo } = await api('POST', '/api/todos', { title: 'Tes' });
    const res = await api('PATCH', `/api/todos/${todo.id}`, { is_done: 'ya' });
    assert.equal(res.status, 400);
  });

  it('menolak body tanpa field yang diubah', async () => {
    const { body: todo } = await api('POST', '/api/todos', { title: 'Tes' });
    const res = await api('PATCH', `/api/todos/${todo.id}`, {});
    assert.equal(res.status, 400);
  });
});

describe('DELETE /api/todos/:id', () => {
  it('menghapus todo', async () => {
    const { body: todo } = await api('POST', '/api/todos', { title: 'Hapus aku' });

    const res = await api('DELETE', `/api/todos/${todo.id}`);
    assert.equal(res.status, 204);

    const after = await api('GET', `/api/todos/${todo.id}`);
    assert.equal(after.status, 404);
  });

  it('404 kalau id tidak ada', async () => {
    const res = await api('DELETE', '/api/todos/tidak-ada');
    assert.equal(res.status, 404);
  });
});

describe('route lain', () => {
  it('404 untuk route yang tidak dikenal', async () => {
    const res = await api('GET', '/api/tidak-ada');
    assert.equal(res.status, 404);
  });
});
