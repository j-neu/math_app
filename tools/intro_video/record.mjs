// Renders scene.html frame by frame (deterministic window.renderAt(t)).
import { chromium } from 'playwright';
import { existsSync, mkdirSync, readFileSync, rmSync } from 'node:fs';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));
const durs = JSON.parse(readFileSync(path.join(here, 'work/timeline.json'), 'utf8').replace(/^\uFEFF/, ''));
const total = durs.reduce((a, d) => a + d + 0.6, 0) + 1;
const fps = 30;
const frames = path.join(here, 'work/frames');
rmSync(frames, { recursive: true, force: true });
mkdirSync(frames, { recursive: true });

// Use an installed Chromium when the pinned build's browser isn't downloaded.
const fallback = path.join(process.env.LOCALAPPDATA ?? '', 'ms-playwright/chromium-1140/chrome-win/chrome.exe');
const browser = await chromium.launch(existsSync(fallback) ? { executablePath: fallback } : {});
const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
page.on('pageerror', (e) => { console.error('page error:', e.message); process.exit(1); });
await page.goto(pathToFileURL(path.join(here, 'scene.html')).href);
await page.waitForFunction(() => window.ready === true);
const n = Math.ceil(total * fps);
for (let f = 0; f < n; f++) {
  await page.evaluate((t) => window.renderAt(t), f / fps);
  await page.screenshot({ path: path.join(frames, `f${String(f).padStart(5, '0')}.png`) });
  if (f % 300 === 0) console.log(`frame ${f}/${n}`);
}
await browser.close();
console.log('frames done', total.toFixed(1), 's');
