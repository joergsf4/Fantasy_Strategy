import { connect } from './lib.mjs';
const { b, page } = await connect();
await page.goto('https://gemini.google.com/app', { waitUntil: 'domcontentloaded' });
await page.waitForSelector('div[role=textbox], .ql-editor', { timeout: 30000 });
for (const t of [0, 1500, 4000]) {
  await page.waitForTimeout(t);
  console.log(t, await page.evaluate(() => [...document.querySelectorAll('button[aria-label]')].map(e => e.getAttribute('aria-label')).slice(0, 12)));
}
await b.close();
