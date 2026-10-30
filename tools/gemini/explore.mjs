import { connect } from './lib.mjs';
const { b, page } = await connect();
await page.getByRole('button', { name: /Menü zum Hochladen|Datei|hinzufügen|Upload/i }).first().click({ timeout: 5000 }).catch(async e => { console.log('btn1 fail'); await page.locator('button:has(mat-icon[fonticon="add_2"]), button[aria-label*="hochladen" i]').first().click(); });
await page.waitForTimeout(1000);
await page.screenshot({ path: process.argv[2] });
console.log(await page.locator('[role=menuitem], [role=menu] button').allInnerTexts());
await b.close();
