// Ende-zu-Ende-Test der Mitmach-Version des Text-Editors (GitHub Pages) und des Imports im lokalen Editor.
//   python3 tools/dialog_editor/build_pages.py out/pages && node tools/gemini/e2e_pages.mjs
// Prueft: Laden ohne Server, Bearbeiten, Zwischenspeichern im Browser, Aenderungspaket (Datei und Issue-Link), Neuladen, Import mit Konflikterkennung.
import { chromium } from 'playwright-core';
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const CHROME = process.env.CHROME || path.join(os.homedir(), 'Library/Caches/ms-playwright/chromium-1223/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing');
let fails = 0;
const check = (c, m) => { if (!c) { fails++; console.log('FAIL:', m); } else console.log('ok  :', m); };
const wait = ms => new Promise(r => setTimeout(r, ms));
const procs = [];
const serve = (cmd, args, opts) => { const p = spawn(cmd, args, { stdio: 'ignore', ...opts }); procs.push(p); return p; };

serve('python3', ['-m', 'http.server', '8799', '--bind', '127.0.0.1'], { cwd: path.join(ROOT, 'out/pages') });
serve('python3', [path.join(ROOT, 'tools/dialog_editor/server.py')], { cwd: ROOT, env: { ...process.env, PORT: '8766' } });
await wait(2000);

const browser = await chromium.launch({ executablePath: CHROME, headless: true });
try {
  // ---------------- Mitmach-Version
  const ctx = await browser.newContext({ acceptDownloads: true });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));
  await page.goto('http://127.0.0.1:8799/');
  await page.waitForSelector('#nav .ch');
  check(await page.locator('#mode').isVisible() && await page.locator('#submit').isVisible() && !(await page.locator('#imp').isVisible()) && !(await page.locator('#save').isVisible()), 'Mitmach-Modus: Einreichen sichtbar, Import und Speichern verborgen');
  check((await page.locator('#nav .ch').count()) >= 17, 'Kapitel aus der Momentaufnahme geladen');
  // Text bearbeiten (Kapitel 1, erste Zeile der Einleitung)
  const ta = page.locator('.card[data-c="intro"] .line textarea.txt').first();
  const old = await ta.inputValue();
  await ta.fill(old + ' (Testtext)');
  await wait(3500);
  check((await page.locator('#status').innerText()).includes('im Browser gesichert'), 'Automatisches Sichern meldet "im Browser gesichert"');
  // Einreichen
  await page.click('#submit');
  await page.waitForSelector('#modal');
  check((await page.locator('#modal .sum li').count()) === 1, 'Zusammenfassung zeigt genau 1 Aenderung');
  await page.fill('#subName', 'Anna Test');
  await page.fill('#subNote', 'Probelauf');
  const [dl] = await Promise.all([page.waitForEvent('download'), page.click('#subDl')]);
  const file = path.join(os.tmpdir(), dl.suggestedFilename());
  await dl.saveAs(file);
  check(/^fuzaketa-aenderungen-Anna-Test-\d{4}-\d{2}-\d{2}\.txt$/.test(dl.suggestedFilename()), 'Dateiname: ' + dl.suggestedFilename());
  const pkg = JSON.parse(fs.readFileSync(file, 'utf8'));
  check(pkg.format === 'fuzaketa-aenderungen' && pkg.version === 1 && pkg.author === 'Anna Test' && pkg.items.length === 1, 'Paket: Format, Autor, 1 Teil');
  check(pkg.items[0].kind === 'chapter' && pkg.items[0].part === 'intro' && pkg.items[0].after[0].text.endsWith('(Testtext)') && !pkg.items[0].before[0].text.endsWith('(Testtext)'), 'Paket: vorher und nachher');
  const [popup] = await Promise.all([ctx.waitForEvent('page'), page.click('#subIssue')]);
  const issueUrl = popup.url().startsWith('about:') ? await popup.evaluate(() => location.href).catch(() => '') : popup.url();
  await popup.close().catch(() => {});
  check(issueUrl.includes('github.com') || issueUrl.includes('/issues/new'), 'Issue-Link: ' + issueUrl.slice(0, 80));
  // Neuladen: Arbeitsstand bleibt
  await page.reload();
  await page.waitForSelector('#nav .ch');
  check((await page.locator('.card[data-c="intro"] .line textarea.txt').first().inputValue()).endsWith('(Testtext)'), 'Nach dem Neuladen ist der Text noch da (Browser-Speicher)');
  check(errors.length === 0, 'keine JavaScript-Fehler: ' + errors.join(' | '));

  // ---------------- Import im lokalen Editor
  const lp = await (await browser.newContext()).newPage();
  const lerr = [];
  lp.on('pageerror', e => lerr.push(String(e)));
  await lp.goto('http://127.0.0.1:8766/');
  await lp.waitForSelector('#nav .ch');
  check(await lp.locator('#imp').isVisible() && !(await lp.locator('#submit').isVisible()), 'Lokal: Import sichtbar, Einreichen verborgen');
  await lp.setInputFiles('#impfile', file);
  await lp.waitForSelector('#modal .imp-item');
  check((await lp.locator('#modal .imp-item .st.ok').count()) === 1, 'Import: Teil als "passt" erkannt');
  const addTxt = await lp.locator('#modal .dl .add').first().innerText().catch(() => '<keine>');
  check(addTxt.includes('(Testtext)'), 'Import: Diff zeigt den neuen Text: ' + addTxt.slice(0, 60));
  await lp.click('#impGo');
  await wait(300);
  check(await lp.evaluate(() => chapters[0].intro[0].text.endsWith('(Testtext)')), 'Import: Text im Editor uebernommen');
  check((await lp.locator('#status').innerText()).includes('Ungespeicherte'), 'Import: als ungespeichert markiert (Speichern prueft der Server)');
  // Konflikt: Paket mit anderem Ausgangstext
  const bad = JSON.parse(JSON.stringify(pkg));
  bad.items[0].before[0].text = 'ein ganz anderer Ausgangstext';
  const badFile = path.join(os.tmpdir(), 'fz-konflikt.txt');
  fs.writeFileSync(badFile, JSON.stringify(bad));
  await lp.evaluate(() => { chapters[0].intro[0].text = "lokal inzwischen geaendert"; });
  await lp.setInputFiles('#impfile', badFile);
  await lp.waitForSelector('#modal .imp-item');
  check((await lp.locator('#modal .imp-item .st.conflict').count()) === 1 && !(await lp.locator('#modal input[data-i]').first().isChecked()), 'Import: Konflikt erkannt und nicht vorangehakt');
  await lp.keyboard.press('Escape');
  // Unsinn
  fs.writeFileSync(badFile, '{"format":"x"}');
  await lp.setInputFiles('#impfile', badFile);
  await wait(300);
  check((await lp.locator('#toast .t.err').count()) >= 1, 'Import: falsche Datei wird abgelehnt');
  check(lerr.length === 0, 'lokal: keine JavaScript-Fehler: ' + lerr.join(' | '));
} finally {
  await browser.close();
  procs.forEach(p => p.kill());
}
console.log(fails ? `${fails} Fehler` : 'Alles ok');
process.exit(fails ? 1 : 0);
