import cors from 'cors';
import express from 'express';

import { errorHandler, notFoundHandler, requestLogger } from './core/middlewares.js';
import { TodoController } from './modules/todo/todo.controller.js';
import { createTodoRouter } from './modules/todo/todo.routes.js';
import { TodoService } from './modules/todo/todo.service.js';

/**
 * Bikin aplikasi Express, TANPA langsung listen ke port.
 *
 * Repository dikirim dari luar (dependency injection), jadi:
 * - server.js pakai JsonFileTodoRepository (data disimpan ke file)
 * - test pakai InMemoryTodoRepository (cepat & bersih tiap test)
 */
export function createApp({ todoRepository, logRequests = true }) {
  // Sambungkan "kabel"-nya: Repository → Service → Controller → Router
  const todoService = new TodoService(todoRepository);
  const todoController = new TodoController(todoService);

  const app = express();

  app.use(cors()); // izinkan request dari origin lain (dibutuhkan Flutter Web)
  app.use(express.json()); // parse body JSON → req.body
  if (logRequests) app.use(requestLogger);

  app.get('/health', (req, res) => res.json({ status: 'ok' }));
  app.use('/api/todos', createTodoRouter(todoController));

  // Harus paling akhir: route tidak ketemu → 404, error apa pun → errorHandler
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
