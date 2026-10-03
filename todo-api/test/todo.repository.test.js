import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { afterEach, beforeEach, describe, it } from 'node:test';

import { JsonFileTodoRepository } from '../src/modules/todo/todo.repository.js';

describe('JsonFileTodoRepository', () => {
  let dir;
  let filePath;

  beforeEach(async () => {
    dir = await mkdtemp(path.join(tmpdir(), 'todo-api-test-'));
    filePath = path.join(dir, 'nested', 'todos.json');
  });

  afterEach(async () => {
    await rm(dir, { recursive: true, force: true });
  });

  const todo = (id, title) => ({
    id,
    title,
    is_done: false,
    created_at: 'x',
    updated_at: 'x',
  });

  it('membuat file berisi data seed kalau file belum ada', async () => {
    const repo = new JsonFileTodoRepository(filePath);
    await repo.init([todo('1', 'Seed')]);

    const saved = JSON.parse(await readFile(filePath, 'utf8'));
    assert.deepEqual(saved.map((t) => t.title), ['Seed']);
  });

  it('data tetap ada setelah "restart" (instance baru membaca file yang sama)', async () => {
    const first = new JsonFileTodoRepository(filePath);
    await first.init();
    await first.create(todo('a', 'Satu'));
    await first.create(todo('b', 'Dua'));
    await first.update('a', { is_done: true });
    await first.delete('b');

    const second = new JsonFileTodoRepository(filePath);
    await second.init([todo('seed', 'Tidak boleh dipakai')]);

    const todos = await second.findAll();
    assert.equal(todos.length, 1);
    assert.equal(todos[0].title, 'Satu');
    assert.equal(todos[0].is_done, true);
  });

  it('banyak perubahan bersamaan tetap tersimpan semua', async () => {
    const repo = new JsonFileTodoRepository(filePath);
    await repo.init();

    await Promise.all(
      Array.from({ length: 20 }, (_, i) => repo.create(todo(`${i}`, `Todo ${i}`))),
    );

    const saved = JSON.parse(await readFile(filePath, 'utf8'));
    assert.equal(saved.length, 20);
  });
});
