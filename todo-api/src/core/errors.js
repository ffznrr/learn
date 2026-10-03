/**
 * Error yang "dikenal" aplikasi. Service melempar error ini,
 * lalu error-handler mengubahnya jadi response HTTP yang rapi.
 */
export class AppError extends Error {
  constructor(message, statusCode = 500) {
    super(message);
    this.name = this.constructor.name;
    this.statusCode = statusCode;
  }
}

/** 400 — input dari client tidak valid. */
export class ValidationError extends AppError {
  constructor(message) {
    super(message, 400);
  }
}

/** 404 — data yang dicari tidak ada. */
export class NotFoundError extends AppError {
  constructor(message = 'Data tidak ditemukan') {
    super(message, 404);
  }
}
