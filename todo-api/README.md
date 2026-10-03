# todo-api

Backend REST API untuk Todo app Flutter (`../learn`), pakai **Express 5**.
Data disimpan di file JSON (`data/todos.json`), jadi tetap ada walaupun server di-restart.

## Menjalankan

```bash
npm install     # sekali saja
npm run dev     # jalan di http://localhost:3000, auto-restart kalau kode berubah
npm start       # jalan tanpa auto-restart
npm test        # jalankan test
```

Ganti port / lokasi data lewat environment variable:

```bash
PORT=4000 DATA_FILE=/tmp/todos.json npm start
```

Data contoh dibuat otomatis saat pertama kali jalan. Mau reset? Hapus folder `data/`.

## Endpoint

| Method | Path | Body | Response |
|---|---|---|---|
| `GET` | `/health` | – | `200 {"status":"ok"}` |
| `GET` | `/api/todos` | – | `200 [todo, ...]` |
| `GET` | `/api/todos/:id` | – | `200 todo` / `404` |
| `POST` | `/api/todos` | `{"title": "..."}` | `201 todo` / `400` |
| `PATCH` | `/api/todos/:id` | `{"title"?: "...", "is_done"?: true}` | `200 todo` / `400` / `404` |
| `PATCH` | `/api/todos/:id/toggle` | – | `200 todo` / `404` |
| `DELETE` | `/api/todos/:id` | – | `204` / `404` |

Bentuk `todo`:

```json
{
  "id": "6be3eda1-1e6d-4a45-bf57-b035301378f7",
  "title": "Belajar Clean Architecture",
  "is_done": false,
  "created_at": "2026-10-03T11:07:36.735Z",
  "updated_at": "2026-10-03T11:07:36.735Z"
}
```

Semua error berbentuk `{"message": "..."}`, contoh: `400 {"message": "Judul todo tidak boleh kosong"}`.
Aplikasi Flutter menampilkan `message` ini langsung ke user.

Coba pakai curl:

```bash
curl localhost:3000/api/todos
curl -X POST localhost:3000/api/todos -H 'content-type: application/json' -d '{"title":"Belajar Express"}'
curl -X PATCH localhost:3000/api/todos/<id>/toggle
curl -X DELETE localhost:3000/api/todos/<id>
```

## Struktur

```
src/
├── server.js                  # titik masuk: bikin repository → app → listen
├── app.js                     # bikin app Express + sambungkan semua layer
├── config.js                  # PORT, DATA_FILE
├── core/
│   ├── errors.js              # AppError, ValidationError (400), NotFoundError (404)
│   └── middlewares.js         # request logger, 404 handler, error handler
└── modules/todo/              # 1 fitur = 1 folder (mirip features/ di Flutter)
    ├── todo.routes.js         # URL → controller
    ├── todo.controller.js     # HTTP (req/res) ↔ service
    ├── todo.service.js        # aturan bisnis & validasi
    └── todo.repository.js     # penyimpanan data (InMemory / JsonFile)
test/
├── todos.test.js              # test semua endpoint (pakai InMemory repository)
└── todo.repository.test.js    # test penyimpanan ke file JSON
```

Alur satu request, contoh `POST /api/todos`:

```
Request → express.json() → todo.routes → TodoController.create
        → TodoService.create (validasi judul) → Repository.create (simpan)
        ← 201 + todo
Error di mana pun → errorHandler → {"message": "..."} + status code yang sesuai
```

Konsepnya sama dengan clean architecture di Flutter:

| Backend (Express) | Flutter | Tugas |
|---|---|---|
| `todo.routes.js` + `todo.controller.js` | `presentation/` | Pintu masuk (HTTP / UI) |
| `todo.service.js` | `domain/usecases/` | Aturan bisnis |
| `todo.repository.js` | `data/` | Ambil & simpan data |
| `createApp({ todoRepository })` | Riverpod provider | Dependency injection |

Mau ganti ke database beneran (PostgreSQL, MongoDB, SQLite)? Bikin class repository baru
dengan method yang sama (`findAll`, `findById`, `create`, `update`, `delete`), lalu
pakai di `server.js`. Service, controller, dan routes tidak perlu diubah.
