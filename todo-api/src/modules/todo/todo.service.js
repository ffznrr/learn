import { randomUUID } from 'node:crypto';

import { NotFoundError, ValidationError } from '../../core/errors.js';

const TITLE_MAX_LENGTH = 100;

/**
 * SERVICE = tempat aturan bisnis (validasi, logika toggle, dll).
 *
 * - Tidak tahu soal Express (req/res) → gampang dites & dipakai ulang.
 * - Tidak tahu data disimpan di mana → cukup panggil repository.
 */
export class TodoService {
  constructor(todoRepository) {
    this.todoRepository = todoRepository;
  }

  list() {
    return this.todoRepository.findAll();
  }

  async get(id) {
    const todo = await this.todoRepository.findById(id);
    if (!todo) throw new NotFoundError(`Todo dengan id ${id} tidak ditemukan`);
    return todo;
  }

  create(input) {
    const title = validateTitle(input?.title);
    const now = new Date().toISOString();

    return this.todoRepository.create({
      id: randomUUID(),
      title,
      is_done: false,
      created_at: now,
      updated_at: now,
    });
  }

  /** Update sebagian field (title dan/atau is_done). */
  async update(id, input) {
    await this.get(id); // lempar 404 kalau tidak ada

    const changes = {};
    if (input?.title !== undefined) {
      changes.title = validateTitle(input.title);
    }
    if (input?.is_done !== undefined) {
      if (typeof input.is_done !== 'boolean') {
        throw new ValidationError('Field "is_done" harus berupa boolean');
      }
      changes.is_done = input.is_done;
    }
    if (Object.keys(changes).length === 0) {
      throw new ValidationError('Tidak ada field yang diubah (title / is_done)');
    }

    return this.todoRepository.update(id, {
      ...changes,
      updated_at: new Date().toISOString(),
    });
  }

  async toggle(id) {
    const todo = await this.get(id);
    return this.todoRepository.update(id, {
      is_done: !todo.is_done,
      updated_at: new Date().toISOString(),
    });
  }

  async remove(id) {
    const deleted = await this.todoRepository.delete(id);
    if (!deleted) throw new NotFoundError(`Todo dengan id ${id} tidak ditemukan`);
  }
}

function validateTitle(title) {
  if (typeof title !== 'string') {
    throw new ValidationError('Field "title" wajib diisi dan harus berupa teks');
  }

  const trimmed = title.trim();
  if (trimmed.length === 0) {
    throw new ValidationError('Judul todo tidak boleh kosong');
  }
  if (trimmed.length > TITLE_MAX_LENGTH) {
    throw new ValidationError(`Judul todo maksimal ${TITLE_MAX_LENGTH} karakter`);
  }
  return trimmed;
}
