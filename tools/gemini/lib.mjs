import { chromium } from 'playwright-core';
export async function connect() {
  const b = await chromium.connectOverCDP('http://localhost:9222');
  const ctx = b.contexts()[0];
  const page = ctx.pages().find(p => p.url().includes('gemini.google.com')) ?? ctx.pages()[0];
  return { b, ctx, page };
}
