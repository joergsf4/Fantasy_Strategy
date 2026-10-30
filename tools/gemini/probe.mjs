import { chromium } from 'playwright-core';
const b = await chromium.connectOverCDP('http://localhost:9222');
const ctx = b.contexts()[0];
const page = ctx.pages().find(p => p.url().includes('gemini')) ?? ctx.pages()[0];
console.log(page.url(), '|', await page.title());
await page.screenshot({ path: process.argv[2] ?? '/tmp/x.png' });
await b.close();
