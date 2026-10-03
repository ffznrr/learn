/**
 * CONTROLLER = penerjemah antara HTTP dan service.
 *
 * Tugasnya cuma: ambil data dari request (params/body) → panggil service
 * → kirim response dengan status code yang tepat. Tidak ada logika bisnis.
 *
 * Method ditulis sebagai arrow function supaya `this` tetap benar
 * waktu dipasang langsung di router (router.get('/', controller.list)).
 */
export class TodoController {
  constructor(todoService) {
    this.todoService = todoService;
  }

  list = async (req, res) => {
    res.json(await this.todoService.list());
  };

  get = async (req, res) => {
    res.json(await this.todoService.get(req.params.id));
  };

  create = async (req, res) => {
    const todo = await this.todoService.create(req.body);
    res.status(201).json(todo);
  };

  update = async (req, res) => {
    res.json(await this.todoService.update(req.params.id, req.body));
  };

  toggle = async (req, res) => {
    res.json(await this.todoService.toggle(req.params.id));
  };

  remove = async (req, res) => {
    await this.todoService.remove(req.params.id);
    res.status(204).end();
  };
}
