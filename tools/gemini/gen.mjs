// node gen.mjs <ausgabe.png> <prompt> <referenzbild> [weitere Referenzen...]
import { connect } from './lib.mjs';
import fs from 'node:fs';
import path from 'node:path';

export async function generate(page, out, prompt, refs, { debug = null } = {}) {
  await page.goto('https://gemini.google.com/app', { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('div[role=textbox], .ql-editor', { timeout: 30000 });
  await page.waitForTimeout(2500);
  const plus = () => page.getByRole('button', { name: 'Uploads & Tools' }).first();
  // Referenzbilder hochladen (versteckte Datei-Eingabe fuer Bilder)
  await page.locator('input[type=file][accept="image/*,video/*"]').first().setInputFiles(refs);
  await page.waitForTimeout(3000);
  // Bildmodus
  await plus().click().catch(() => {});
  await page.getByText('Bild erstellen', { exact: true }).click().catch(() => {});
  await page.waitForTimeout(500);
  const box = page.locator('div[role=textbox], .ql-editor').first();
  await box.click();
  await page.keyboard.insertText(prompt);
  if (debug) await page.screenshot({ path: debug + '-pre.png' });
  await page.keyboard.press('Enter');
  // auf fertiges Bild warten
  const img = page.locator('model-response img, .response-container img, generated-image img').first();
  await img.waitFor({ timeout: 180000 });
  await page.waitForTimeout(6000);
  if (debug) await page.screenshot({ path: debug + '-post.png' });
  return page;
}

if (process.argv[1].endsWith('gen.mjs')) {
  const [out, prompt, ...refs] = process.argv.slice(2);
  const { b, page } = await connect();
  await generate(page, out, prompt, refs, { debug: out.replace(/\.png$/, '') });
  await b.close();
}
