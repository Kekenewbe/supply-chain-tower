import { test, expect } from '@playwright/test';

test.describe('Dashboard smoke', () => {
  test('loads and exposes MCP status endpoint', async ({ page, request }) => {
    await page.goto('/');
    await expect(page).toHaveURL(/localhost:3131\/?$/);

    const res = await request.get('/api/mcp/status');
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('obsidian');
    expect(body).toHaveProperty('pinecone');
  });
});
