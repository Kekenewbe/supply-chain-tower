import { test, expect } from '@playwright/test';

test.describe('Espace_Opti dashboard', () => {
  test('seed', async ({ page }) => {
    await page.goto('/');
  });
});
