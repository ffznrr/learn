# Clean Architecture — Contoh Todo App

Panduan singkat buat project ini. Baca sambil buka kodenya.

- **Frontend**: Flutter + Riverpod (folder ini)
- **Backend**: Express (`../todo-api`, lihat README di sana)

## 1. Idenya apa sih?

Clean Architecture = **memisahkan kode berdasarkan tanggung jawab**, jadi tiap bagian
bisa diganti / dites tanpa ngerusak bagian lain.

Aturan utamanya cuma satu, **Dependency Rule**:

> Kode di lapisan dalam **tidak boleh tahu** apa-apa tentang lapisan luar.

```
┌────────────────────────────────────────────┐
│  PRESENTATION  (Flutter UI, Riverpod)      │
│   ┌────────────────────────────────────┐   │
│   │  DATA  (HTTP, JSON, Model)         │   │
│   │   ┌────────────────────────────┐   │   │
│   │   │  DOMAIN                    │   │   │
│   │   │  Entity, UseCase,          │   │   │
│   │   │  Repository (kontrak)      │   │   │
│   │   └────────────────────────────┘   │   │
│   └────────────────────────────────────┘   │
└────────────────────────────────────────────┘
  Panah dependency selalu menuju ke DALAM (ke domain).
```

- **Domain** = inti bisnis. Dart murni: gak import Flutter, Riverpod, http, ataupun JSON.
- **Data** = cara ambil/simpan data (di sini: HTTP ke backend). Mengimplementasi kontrak domain.
- **Presentation** = tampilan + state (Riverpod). Memanggil use case.

> 💡 **Bukti nyata**: waktu app ini pindah dari data lokal ke backend Express, dan dari
> `ChangeNotifier` ke Riverpod, **folder `domain/` tidak berubah satu baris pun.**

## 2. Struktur folder

```
lib/
├── core/                              # dipakai bareng semua fitur
│   ├── config/api_config.dart         # alamat backend
│   ├── error/
│   │   ├── exceptions.dart            # error teknis (layer data)
│   │   ├── failure.dart               # error versi "bahasa domain"
│   │   └── result.dart                # Ok / Err
│   └── usecase/usecase.dart           # kontrak dasar use case
│
├── features/todo/
│   ├── domain/
│   │   ├── entities/todo.dart
│   │   ├── repositories/todo_repository.dart          # kontrak (abstract)
│   │   └── usecases/                                  # get/add/toggle/delete
│   ├── data/
│   │   ├── models/todo_model.dart                     # fromJson / toJson / toEntity
│   │   ├── datasources/
│   │   │   ├── todo_data_source.dart                  # kontrak data source
│   │   │   ├── todo_remote_data_source.dart           # ← HTTP ke backend (dipakai app)
│   │   │   └── todo_local_data_source.dart            # ← in-memory (dipakai test)
│   │   └── repositories/todo_repository_impl.dart     # Exception → Failure
│   └── presentation/
│       ├── providers/
│       │   ├── todo_providers.dart                    # dependency injection (Riverpod)
│       │   └── todo_list_notifier.dart                # state daftar todo
│       ├── pages/todo_page.dart
│       └── widgets/todo_tile.dart
│
└── main.dart                          # ProviderScope + MaterialApp
```

## 3. Penjelasan tiap bagian

### Domain (inti)

| File | Peran |
|---|---|
| `Todo` (entity) | Data bisnis murni. Gak ada `fromJson`, gak ada import Flutter. |
| `TodoRepository` (abstract) | "Janji" domain: *aku butuh bisa getTodos, addTodo, dst.* Gak peduli datanya dari mana. |
| `AddTodo`, `GetTodos`, ... (use case) | **Satu aksi = satu class.** Tempat aturan bisnis. Contoh: `AddTodo` nolak judul kosong *sebelum* request dikirim ke server. |

### Data

| File | Peran |
|---|---|
| `TodoModel` | Konversi JSON dari backend (`is_done` ↔ `isDone`). |
| `TodoDataSource` | Kontrak: method apa saja yang harus dimiliki sumber data. |
| `TodoRemoteDataSource` | Kirim request HTTP ke backend. Status 404 → `NotFoundException`, 4xx/5xx → `ServerException`, server mati/timeout → `NetworkException`. |
| `TodoLocalDataSource` | Versi in-memory, dipakai widget test supaya gak butuh backend. |
| `TodoRepositoryImpl` | Panggil data source → ubah Model jadi Entity → tangkap Exception jadi `Failure` dengan pesan yang ramah user. |

**Exception vs Failure**: Exception = error teknis (HTTP, socket, JSON), cuma hidup di layer data.
Failure = error yang sudah diterjemahkan untuk domain/UI. UI gak pernah lihat `SocketException`.

### Presentation (Riverpod)

| File | Peran |
|---|---|
| `todo_providers.dart` | **Dependency injection.** Tiap provider menyediakan satu objek: `http.Client → DataSource → Repository → UseCase`. |
| `TodoListNotifier` | State daftar todo (`AsyncValue<List<Todo>>`: loading / data / error). Cuma kenal use case. |
| `TodoPage` | `ref.watch(todoListProvider)` untuk tampilan, `ref.read(todoListProvider.notifier)` untuk aksi. |
| `TodoTile` | Widget kecil, cuma terima data + callback. |

Istilah Riverpod yang dipakai:

- **`ProviderScope`** (di `main.dart`) — wadah tempat semua provider hidup.
- **`Provider`** — menyediakan objek biasa (repository, use case, dll).
- **`AsyncNotifierProvider`** — state yang di-load secara async + punya method untuk mengubahnya.
- **`ref.watch`** — baca & *dengarkan* perubahan (dipakai di `build`).
- **`ref.read`** — baca sekali tanpa mendengarkan (dipakai di event handler / method).
- **`ref.invalidate`** — buang state lama & load ulang (tombol refresh / "Coba lagi").
- **`overrideWithValue`** — ganti isi provider, dipakai di test.

## 4. Alur data (contoh: user nambah todo)

```
[User tap "Tambah"]
      │
      ▼
TodoPage              → ref.read(todoListProvider.notifier).addTodo("  Belajar ")
      │
      ▼
TodoListNotifier      → ref.read(addTodoProvider)("  Belajar ")      (use case)
      │
      ▼
AddTodo               → trim → kosong? return Err(Failure)            ← aturan bisnis
                        → repository.addTodo("Belajar")
      │
      ▼
TodoRepositoryImpl    → try { dataSource.addTodo(...) }               ← Exception → Failure
      │
      ▼
TodoRemoteDataSource  → POST http://localhost:3000/api/todos  {"title":"Belajar"}
      │
      ▼
   [ todo-api ]       → routes → controller → service → repository → data/todos.json
```

Response-nya balik ke atas: JSON → `TodoModel` → `Todo` → `Ok(todo)` →
notifier set `state = AsyncData([...todos, todo])` → `ref.watch` di page → UI rebuild.
Kalau gagal → `Failure` → page tampilkan SnackBar.

## 5. Menjalankan

**1. Jalankan backend dulu** (terminal pertama):

```bash
cd ../todo-api
npm install   # sekali saja
npm run dev
```

**2. Jalankan Flutter** (terminal kedua):

```bash
flutter run
```

Alamat backend otomatis disesuaikan (lihat `lib/core/config/api_config.dart`):

| Jalan di | Alamat backend |
|---|---|
| iOS simulator, macOS, Chrome/web | `http://localhost:3000` |
| Android emulator | `http://10.0.2.2:3000` |
| HP fisik | `flutter run --dart-define=API_BASE_URL=http://<IP-laptop>:3000` |

Kalau backend belum jalan, app menampilkan *"Tidak bisa terhubung ke server"* + tombol **Coba lagi**.

**Test** (gak butuh backend):

```bash
flutter test
```

## 6. Kenapa repot-repot begini?

1. **Gampang ganti sumber data.** Sudah terbukti: data lokal → backend cukup bikin
   `TodoRemoteDataSource` + ubah 1 provider. Domain & UI tidak disentuh.
2. **Gampang ganti state management.** `ChangeNotifier` → Riverpod cuma mengubah presentation.
3. **Gampang dites.**
   - Use case dites pakai repository palsu (`test/.../add_todo_test.dart`)
   - Remote data source dites pakai `MockClient` tanpa server (`test/.../todo_remote_data_source_test.dart`)
   - UI dites dengan override provider ke data lokal (`test/widget_test.dart`)
4. **Rapi & konsisten.** Tiap orang tahu harus naruh kode di mana.

Kekurangannya: **file jadi banyak** (boilerplate). Untuk app super kecil kadang overkill.

## 7. Latihan buat kamu

1. **Edit judul todo.** Backend sudah siap (`PATCH /api/todos/:id` dengan `{"title": "..."}`).
   Kerjakan dari dalam ke luar: kontrak repository → use case `EditTodo` → data source →
   repository impl → provider → notifier → UI.
2. **Batas 100 karakter.** Backend sudah menolak judul > 100 karakter. Tambahkan aturan yang sama
   di use case `AddTodo` supaya user dapat pesan error tanpa harus kirim request.
3. **Offline cache.** Simpan hasil `getTodos` ke `shared_preferences`; kalau backend mati,
   tampilkan data terakhir. (Repository pakai 2 data source: remote + local.)
4. **Riverpod code generation.** Coba ubah provider ke versi `@riverpod`
   (package `riverpod_annotation` + `riverpod_generator` + `build_runner`).
5. **Database beneran di backend.** Ganti `JsonFileTodoRepository` dengan SQLite/PostgreSQL —
   lihat README di `todo-api`.

## 8. Package yang dipakai / umum dipakai

| Kebutuhan | Dipakai di sini | Alternatif |
|---|---|---|
| State management + DI | `flutter_riverpod` | `flutter_bloc` + `get_it` |
| HTTP | `http` | `dio` |
| Result / Either | bikin sendiri (`Result`) | `fpdart`, `dartz` |
| Equality entity | – | `equatable`, `freezed` |
| Mock untuk test | `MockClient` (bawaan `http`) | `mocktail` |
