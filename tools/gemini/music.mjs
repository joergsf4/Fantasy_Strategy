// Musik ueber Gemini erzeugen (Werkzeug "Musik erstellen"):  node music.mjs "<Beschreibung>" <ausgabe.mp3>
// Voraussetzung wie bei run.mjs: Chrome mit Remote-Debugging auf Port 9222, bei Gemini angemeldet. Ergebnis: MP3 (ca. 1 Minute).
import { chromium } from 'playwright-core';
const [prompt, out] = process.argv.slice(2);
if (!prompt || !out) { console.error('Benutzung: node music.mjs "<Beschreibung>" <ausgabe.mp3>'); process.exit(1); }
const b = await chromium.connectOverCDP('http://localhost:9222');
const page = b.contexts()[0].pages().find(p => p.url().includes('gemini.google.com')) ?? b.contexts()[0].pages()[0];
await page.goto('https://gemini.google.com/app', { waitUntil: 'domcontentloaded' });
await page.waitForSelector('div[role=textbox], .ql-editor', { timeout: 30000 });
await page.waitForTimeout(2500);
await page.getByRole('button', { name: 'Uploads & Tools' }).first().click();
await page.getByText('Weitere Tools', { exact: true }).click();
await page.waitForTimeout(500);
await page.getByText('Musik erstellen', { exact: true }).click();
await page.waitForTimeout(800);
await page.locator('div[role=textbox], .ql-editor').first().click();
await page.keyboard.insertText(prompt);
await page.keyboard.press('Enter');
const dl = page.getByRole('button', { name: 'Titel herunterladen' }).last();
await dl.waitFor({ timeout: 300000 });
await page.waitForTimeout(1500);
await dl.scrollIntoViewIfNeeded();
await dl.click();
const [d] = await Promise.all([page.waitForEvent('download', { timeout: 60000 }), page.getByRole('menuitem').filter({ hasText: 'Nur Audio' }).click()]);
await d.saveAs(out);
console.log('gespeichert:', out);
await b.close();
