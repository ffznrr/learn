import { AppError } from './errors.js';

/** Log setiap request: `GET /api/todos → 200 (1.2 ms)` */
export function requestLogger(req, res, next) {
  const start = performance.now();
  res.on('finish', () => {
    const ms = (performance.now() - start).toFixed(1);
    console.log(`${req.method} ${req.originalUrl} → ${res.statusCode} (${ms} ms)`);
  });
  next();
}

/** Dipanggil kalau tidak ada route yang cocok. */
export function notFoundHandler(req, res) {
  res
    .status(404)
    .json({ message: `Route ${req.method} ${req.originalUrl} tidak ditemukan` });
}

/**
 * Error handler terpusat (harus punya 4 parameter supaya dikenali Express).
 *
 * Di Express 5, error dari handler async otomatis diteruskan ke sini,
 * jadi controller tidak perlu try-catch.
 */
export function errorHandler(err, req, res, next) {
  if (res.headersSent) return next(err);

  // Error yang memang kita lempar sendiri (ValidationError, NotFoundError, ...)
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ message: err.message });
  }

  // Body request bukan JSON yang valid (dilempar oleh express.json())
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ message: 'Body request harus berupa JSON yang valid' });
  }

  // Error 4xx lain dari middleware bawaan (misal body terlalu besar)
  if (err.expose && err.status >= 400 && err.status < 500) {
    return res.status(err.status).json({ message: err.message });
  }

  // Selain itu: bug / error tak terduga. Log detailnya, tapi jangan bocorkan ke client.
  console.error(err);
  res.status(500).json({ message: 'Terjadi kesalahan di server' });
}
