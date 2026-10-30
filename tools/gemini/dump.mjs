import { connect } from './lib.mjs';
const { b, page } = await connect();
await page.goto('https://gemini.google.com/app', { waitUntil: 'domcontentloaded' });
await page.waitForTimeout(2500);
const r = await page.evaluate(() => [...document.querySelectorAll('input-area-v2 button, .input-area button, rich-textarea, div[role=textbox]')].map(e => e.tagName + ' | ' + (e.getAttribute('aria-label')||'') + ' | ' + (e.className||'').toString().slice(0,60) + ' | ' + (e.getAttribute('data-test-id')||'')));
console.log(r.join('\n'));
await b.close();
