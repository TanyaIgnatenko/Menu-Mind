/* Tiny zero-dependency static server for local preview of dist/.
   Serves the correct MIME types — including the Android .apk type. */
import { createServer } from 'node:http';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DIST = path.resolve(__dirname, '..', 'dist');
const PORT = process.env.PORT || 4321;

const TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff2': 'font/woff2',
  '.apk': 'application/vnd.android.package-archive',
};

const server = createServer(async (req, res) => {
  try {
    let urlPath = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    if (urlPath === '/') urlPath = '/index.html';
    let filePath = path.join(DIST, urlPath);
    if (!filePath.startsWith(DIST)) { res.writeHead(403).end(); return; }

    let data;
    try {
      data = await fs.readFile(filePath);
    } catch {
      filePath = path.join(DIST, 'index.html'); // SPA-ish fallback
      data = await fs.readFile(filePath);
    }

    const ext = path.extname(filePath).toLowerCase();
    const headers = { 'Content-Type': TYPES[ext] || 'application/octet-stream' };
    if (ext === '.apk') {
      headers['Content-Disposition'] = 'attachment; filename="MenuMind.apk"';
    }
    res.writeHead(200, headers).end(data);
  } catch (err) {
    res.writeHead(500).end(String(err));
  }
});

server.listen(PORT, () => {
  console.log(`MenuMind landing → http://localhost:${PORT}`);
});
