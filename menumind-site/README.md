# MenuMind — Android install / landing page

A fast, static, single-page marketing site whose only job is one conversion:
**download the MenuMind Android app.** Built from the spec in
[`../design_handoff_android/README.md`](../design_handoff_android/README.md).

## Stack

Plain **HTML + CSS + a few lines of vanilla JS** — no runtime framework. A small
**build step** (Node, dev-dependencies only) generates the QR code, self-hosts the
fonts, optimizes images, and creates the favicons + OG card. **Production ships zero
JavaScript dependencies.**

Why: it's a single static page with no routing/state/data — a framework would add a
toolchain and JS payload for nothing. This is the most Lighthouse-friendly, cheapest-
to-host option.

## Develop

```bash
npm install      # dev-deps only (qrcode, sharp, @fontsource/..., png-to-ico)
npm run build    # src/ + assets → dist/
npm run serve    # static server with correct .apk MIME → http://localhost:4321
# or:
npm run dev      # build + serve
```

Edit source in [`src/`](src/); run `npm run build` to regenerate `dist/`.
`dist/` is the deployable folder (git-ignored — it's a build artifact).

## Structure

```
src/
  index.html      semantic page (nav · hero · features · footer)
  styles.css      design tokens as CSS vars + all layout (breakpoint 860px)
  main.js         tiny: Android-detect hint, smooth-scroll, focus mgmt
  (assets live in ../design_handoff_android/assets and are pulled in at build)
scripts/
  build.mjs       QR injection · font copy · image opt · favicon/OG · APK placeholder
  serve.mjs       zero-dep static server (correct MIME incl. .apk)
vercel.json       Vercel build + APK MIME header + cache headers
_headers          portable header file (Netlify / Cloudflare Pages)
dist/             build output (deploy this)
```

## Design-token mapping

Every color/radius/shadow token from the handoff README is a CSS custom property in
`:root` (`styles.css`) — no raw hex in markup. Type scale (hero H1 52/800/-0.04em,
etc.) and the 860px breakpoint follow the spec's "Responsive behavior" section:
desktop split hero + QR; mobile single column, full-width button, **QR hidden**,
features stacked, phone shrunk to a peek.

## Stubbed — replace before launch

| Item | Where | Action |
|---|---|---|
| **APK file** | `dist/MenuMind.apk` is a text placeholder | Drop in the real signed APK (or point the host header / button at object storage) |
| **Download URL** (QR + buttons) | `DOWNLOAD_URL` in `scripts/build.mjs`; `href="/MenuMind.apk"` in `src/index.html` | Set your real absolute URL, rebuild (QR re-encodes) |
| **Marketing stats** | 4.8★ / 12k / 500k+ / 40+ in `src/index.html` | Replace with real numbers |
| **Nav links** | "How it works" → `#features`; "Support" → `mailto:` | Point at real destinations |
| **Analytics** | TODO in `src/main.js` (`.js-download` handler) | Wire your analytics event |
| **Email capture** | not built (optional in spec) | Add if you want launch-notify |

## Hosting (recommendation: **Vercel**, since this is already a git repo)

Connect the repo in the Vercel dashboard once — every push auto-deploys.
`vercel.json` is pre-configured: build command `npm run build`, output `dist`, and the
critical APK header `Content-Type: application/vnd.android.package-archive`.

- **Custom domain:** add it in the project's *Domains* tab, then add the DNS record
  Vercel shows (a CNAME to `cname.vercel-dns.com`, or A record for an apex domain).
- **HTTPS:** automatic (managed certs).
- **Cost:** free Hobby tier is plenty for a landing page.

Alternatives are equivalent for a static site:
- **Netlify** — fastest with *zero* git/CLI: build locally, drag `dist/` onto
  `app.netlify.com/drop`. APK MIME via the included `_headers`.
- **Cloudflare Pages** — best long-term (unlimited bandwidth); `_headers` works here too.
- **GitHub Pages** — works, but weakest for APKs (MIME control + 100 MB file cap).

**APK gotcha (every host):** the file must be served as
`application/vnd.android.package-archive`, or browsers may try to render it. The
included `vercel.json` / `_headers` set this. For a large or versioned APK, host the
site here but put the binary on **GitHub Releases** or object storage (R2/S3) and
point the button + `DOWNLOAD_URL` there.
