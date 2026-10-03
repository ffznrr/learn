import path from 'node:path';

/**
 * Konfigurasi aplikasi. Bisa di-override lewat environment variable:
 *   PORT=4000 npm start
 *   DATA_FILE=/tmp/todos.json npm start
 */
export const config = {
  port: Number(process.env.PORT) || 3000,
  // Default: <root project>/data/todos.json (tidak tergantung dari folder mana server dijalankan)
  dataFile:
    process.env.DATA_FILE ??
    path.join(import.meta.dirname, '..', 'data', 'todos.json'),
};
