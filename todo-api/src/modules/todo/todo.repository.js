import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import path from 'node:path';

/**
 * REPOSITORY = satu-satunya bagian yang tahu CARA menyimpan data.
 *
 * Service cuma memanggil method-method ini (findAll, create, ...),
 * tanpa peduli datanya di memori, file JSON, atau database beneran.
 *
 * Bentuk objek todo:
 *   { id, title, is_done, created_at, updated_at }
 */

/** Simpan data di memori. Hilang saat server restart — cocok untuk test. */
export class InMemoryTodoRepository {
  constructor(initialTodos = []) {
    /** @type {Map<string, object>} */
    this.todos = new Map(initialTodos.map((todo) => [todo.id, { ...todo }]));
  }

  // Selalu kembalikan salinan ({ ...todo }) supaya data di dalam
  // repository tidak bisa diubah diam-diam dari luar.

  async findAll() {
    return [...this.todos.values()].map((todo) => ({ ...todo }));
  }

  async findById(id) {
    const todo = this.todos.get(id);
    return todo ? { ...todo } : null;
  }

  async create(todo) {
    this.todos.set(todo.id, { ...todo });
    return { ...todo };
  }

  /** Return todo yang sudah di-update, atau null kalau id tidak ada. */
  async update(id, changes) {
    const current = this.todos.get(id);
    if (!current) return null;

    const updated = { ...current, ...changes };
    this.todos.set(id, updated);
    return { ...updated };
  }

  /** Return true kalau berhasil dihapus, false kalau id tidak ada. */
  async delete(id) {
    return this.todos.delete(id);
  }
}

/**
 * Sama seperti InMemory, tapi setiap perubahan juga disimpan ke file JSON,
 * jadi data tetap ada walaupun server di-restart.
 *
 * Mau ganti ke database (PostgreSQL, MongoDB, SQLite)? Bikin class baru
 * dengan method yang sama, lalu pakai di server.js. Service tidak perlu diubah.
 */
export class JsonFileTodoRepository extends InMemoryTodoRepository {
  #filePath;
  #writeQueue = Promise.resolve();

  constructor(filePath) {
    super();
    this.#filePath = filePath;
  }

  /** Baca data dari file. Kalau file belum ada, isi dengan [seedTodos]. */
  async init(seedTodos = []) {
    try {
      const todos = JSON.parse(await readFile(this.#filePath, 'utf8'));
      for (const todo of todos) this.todos.set(todo.id, todo);
    } catch (error) {
      if (error.code !== 'ENOENT') throw error;

      for (const todo of seedTodos) this.todos.set(todo.id, { ...todo });
      await this.#save();
    }
  }

  async create(todo) {
    const created = await super.create(todo);
    await this.#save();
    return created;
  }

  async update(id, changes) {
    const updated = await super.update(id, changes);
    if (updated) await this.#save();
    return updated;
  }

  async delete(id) {
    const deleted = await super.delete(id);
    if (deleted) await this.#save();
    return deleted;
  }

  /**
   * Tulis ke file .tmp dulu lalu rename, supaya file tidak rusak kalau
   * proses mati di tengah jalan. Penulisan diantrekan supaya dua request
   * yang datang bersamaan tidak menulis file di waktu yang sama.
   */
  #save() {
    const json = JSON.stringify([...this.todos.values()], null, 2);
    const tmpPath = `${this.#filePath}.tmp`;

    this.#writeQueue = this.#writeQueue
      .catch(() => {}) // kegagalan tulis sebelumnya jangan menghentikan antrean
      .then(async () => {
        await mkdir(path.dirname(this.#filePath), { recursive: true });
        await writeFile(tmpPath, json);
        await rename(tmpPath, this.#filePath);
      });

    return this.#writeQueue;
  }
}
