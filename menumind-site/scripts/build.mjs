/* ============================================================
   MenuMind landing — build step
   - copies src/ → dist/
   - generates a real QR code and injects it into index.html
   - self-hosts Plus Jakarta Sans (woff2)
   - optimizes images, generates favicons + OG card
   - drops a placeholder MenuMind.apk
   No runtime dependencies ship — this all happens at build time.
   ============================================================ */
import { promises as fs } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import QRCode from 'qrcode';
import sharp from 'sharp';
import pngToIco from 'png-to-ico';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '..');
const SRC = path.join(ROOT, 'src');
const DIST = path.join(ROOT, 'dist');
const HANDOFF = path.resolve(ROOT, '..', 'design_handoff_android', 'assets');
const FONT_SRC = path.join(ROOT, 'node_modules', '@fontsource', 'plus-jakarta-sans', 'files');

/* ─────────────────────────────────────────────────────────────
   ⚠️  TODO: point this at the REAL signed APK before launch.
   The QR encodes this exact (absolute) URL, and the download
   buttons in index.html link to /MenuMind.apk on the same host.
   ───────────────────────────────────────────────────────────── */
const DOWNLOAD_URL = 'https://menumind.app/MenuMind.apk';

const log = (...a) => console.log('  ', ...a);

async function clean() {
  await fs.rm(DIST, { recursive: true, force: true });
  await fs.mkdir(path.join(DIST, 'assets', 'fonts'), { recursive: true });
}

async function copyStatic() {
  await fs.copyFile(path.join(SRC, 'styles.css'), path.join(DIST, 'styles.css'));
  await fs.copyFile(path.join(SRC, 'main.js'), path.join(DIST, 'main.js'));
  log('copied styles.css, main.js');
}

async function copyFonts() {
  const weights = [400, 500, 600, 700, 800];
  for (const w of weights) {
    await fs.copyFile(
      path.join(FONT_SRC, `plus-jakarta-sans-latin-${w}-normal.woff2`),
      path.join(DIST, 'assets', 'fonts', `plus-jakarta-sans-${w}.woff2`)
    );
  }
  log(`self-hosted ${weights.length} font weights (woff2)`);
}

async function buildQrSvg() {
  // High error-correction so the centered logo/quiet zone is tolerated; crisp SVG.
  const svg = await QRCode.toString(DOWNLOAD_URL, {
    type: 'svg',
    errorCorrectionLevel: 'M',
    margin: 0,
    color: { dark: '#1A1008', light: '#00000000' },
  });
  // Strip the XML prolog and force it to scale to the styled box.
  return svg
    .replace(/<\?xml[^>]*\?>\s*/i, '')
    .replace('<svg ', '<svg role="img" aria-label="QR code to download MenuMind" ');
}

async function buildHtml(qrSvg) {
  let html = await fs.readFile(path.join(SRC, 'index.html'), 'utf8');
  html = html.replace('<!--QR_SVG-->', qrSvg);
  // light touch: drop HTML comments except conditional ones (keep file lean)
  await fs.writeFile(path.join(DIST, 'index.html'), html);
  log('injected QR → index.html');
}

async function images() {
  // Dish photo: 1024² original → 640² is plenty (displayed ~205px). mozjpeg.
  await sharp(path.join(HANDOFF, 'carbonara.jpg'))
    .resize(640, 640, { fit: 'cover' })
    .jpeg({ quality: 80, mozjpeg: true })
    .toFile(path.join(DIST, 'assets', 'carbonara.jpg'));

  // App icon for the nav (kept crisp at 2×: 68px).
  await sharp(path.join(HANDOFF, 'ic_launcher.png'))
    .resize(96, 96)
    .png({ compressionLevel: 9 })
    .toFile(path.join(DIST, 'assets', 'ic_launcher.png'));

  // Favicons from the brand icon.
  const fav32 = path.join(DIST, 'assets', 'favicon-32.png');
  await sharp(path.join(HANDOFF, 'ic_launcher.png')).resize(32, 32).png().toFile(fav32);
  await sharp(path.join(HANDOFF, 'ic_launcher.png')).resize(180, 180).png()
    .toFile(path.join(DIST, 'assets', 'favicon-180.png'));
  const fav48 = await sharp(path.join(HANDOFF, 'ic_launcher.png')).resize(48, 48).png().toBuffer();
  await fs.writeFile(path.join(DIST, 'favicon.ico'), await pngToIco([fav48]));

  log('optimized images + favicons');
}

async function ogImage() {
  // 1200×630 social card: brand gradient + icon + wordmark + tagline.
  const iconBuf = await sharp(path.join(HANDOFF, 'ic_launcher.png'))
    .resize(180, 180).png().toBuffer();
  const iconB64 = iconBuf.toString('base64');

  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
    <defs>
      <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stop-color="#FFD098"/>
        <stop offset="0.52" stop-color="#F05A28"/>
        <stop offset="1" stop-color="#C03010"/>
      </linearGradient>
      <radialGradient id="hl" cx="0.18" cy="0.12" r="0.7">
        <stop offset="0" stop-color="#ffffff" stop-opacity="0.35"/>
        <stop offset="1" stop-color="#ffffff" stop-opacity="0"/>
      </radialGradient>
    </defs>
    <rect width="1200" height="630" fill="url(#bg)"/>
    <rect width="1200" height="630" fill="url(#hl)"/>
    <image x="96" y="150" width="180" height="180" href="data:image/png;base64,${iconB64}"
           style="clip-path: inset(0 round 40px)"/>
    <text x="300" y="250" font-family="'Plus Jakarta Sans',Segoe UI,Arial,sans-serif"
          font-size="58" font-weight="800" letter-spacing="-2" fill="#ffffff">MenuMind</text>
    <text x="300" y="330" font-family="'Plus Jakarta Sans',Segoe UI,Arial,sans-serif"
          font-size="40" font-weight="700" fill="#ffffff" opacity="0.95">Translate any menu in seconds.</text>
    <text x="96" y="470" font-family="'Plus Jakarta Sans',Segoe UI,Arial,sans-serif"
          font-size="26" font-weight="600" fill="#ffffff" opacity="0.9">AI dish photos · diet filters · nutrition · 40+ languages · Free for Android</text>
  </svg>`;

  await sharp(Buffer.from(svg)).png().toFile(path.join(DIST, 'assets', 'og-image.png'));
  log('generated og-image.png (1200×630)');
}

async function apkPlaceholder() {
  // Placeholder so the download button resolves locally. Replace with the real APK.
  const note =
    'PLACEHOLDER — replace with the real signed MenuMind .apk before launch.\n' +
    'See DOWNLOAD_URL in scripts/build.mjs and the TODO comments in src/index.html.\n';
  await fs.writeFile(path.join(DIST, 'MenuMind.apk'), note);
  log('wrote placeholder MenuMind.apk  ⚠️  (TODO: real APK)');
}

async function vercelConfig() {
  // Copy hosting config into dist so a drag-drop deploy carries headers too.
  await fs.copyFile(path.join(ROOT, 'vercel.json'), path.join(DIST, 'vercel.json'))
    .catch(() => {});
  await fs.copyFile(path.join(ROOT, '_headers'), path.join(DIST, '_headers'))
    .catch(() => {});
}

async function main() {
  console.log('Building MenuMind landing → dist/');
  await clean();
  await copyStatic();
  await copyFonts();
  const qr = await buildQrSvg();
  await buildHtml(qr);
  await images();
  await ogImage();
  await apkPlaceholder();
  await vercelConfig();
  console.log(`Done. Download URL encoded in QR: ${DOWNLOAD_URL}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
