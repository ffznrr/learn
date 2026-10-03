import { Router } from 'express';

/**
 * ROUTES = daftar endpoint → controller mana yang menangani.
 * Router ini dipasang di /api/todos (lihat app.js).
 */
export function createTodoRouter(todoController) {
  const router = Router();

  router.get('/', todoController.list);
  router.post('/', todoController.create);
  router.get('/:id', todoController.get);
  router.patch('/:id', todoController.update);
  router.patch('/:id/toggle', todoController.toggle);
  router.delete('/:id', todoController.remove);

  return router;
}
