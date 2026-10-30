import { connect } from './lib.mjs';
const { b, page } = await connect();
const btn = page.getByRole('button', { name: 'Bild in Originalgröße herunterladen' }).last();
await page.locator('generated-image, single-image, .image.loaded').last().hover().catch(() => {});
const [d] = await Promise.all([page.waitForEvent('download', { timeout: 60000 }), btn.click({ force: true })]);
console.log(d.suggestedFilename());
await d.saveAs(process.argv[2]);
await b.close();
