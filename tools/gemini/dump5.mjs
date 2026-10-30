import { connect } from './lib.mjs';
const { b, page } = await connect();
await page.waitForTimeout(3000);
console.log(await page.evaluate(() => [...document.querySelectorAll('img')].filter(i => i.naturalWidth > 200).map(i => i.naturalWidth + 'x' + i.naturalHeight + ' ' + i.src.slice(0, 90) + ' | parent:' + i.closest('[class]')?.className?.toString().slice(0, 40))));
await page.locator('generated-image, single-image').first().hover().catch(() => {});
console.log(await page.evaluate(() => [...document.querySelectorAll('button[aria-label]')].map(e => e.getAttribute('aria-label')).filter(l => /herunter|download|teilen|kopieren/i.test(l))));
await page.screenshot({ path: process.argv[2] });
await b.close();
