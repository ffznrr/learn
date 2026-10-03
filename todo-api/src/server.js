import { randomUUID } from 'node:crypto';

import { createApp } from './app.js';
import { config } from './config.js';
import { JsonFileTodoRepository } from './modules/todo/todo.repository.js';

/** Data contoh, hanya dipakai saat file data belum ada (pertama kali jalan). */
function createSeedTodos() {
  const now = new Date().toISOString();
  return [
    { title: 'Belajar Clean Architecture', is_done: false },
    { title: 'Bikin backend pakai Express', is_done: true },
  ].map((todo) => ({ id: randomUUID(), ...todo, created_at: now, updated_at: now }));
}

const todoRepository = new JsonFileTodoRepository(config.dataFile);
await todoRepository.init(createSeedTodos());

const app = createApp({ todoRepository });

app.listen(config.port, (error) => {
  if (error) {
    console.error(`Gagal menjalankan server di port ${config.port}:`, error.message);
    process.exit(1);
  }
  console.log(`🚀 Todo API jalan di http://localhost:${config.port}`);
  console.log(`📁 Data disimpan di ${config.dataFile}`);
});
