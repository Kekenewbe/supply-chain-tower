import { test, expect } from '@playwright/test';

test.describe('Rules modal', () => {
  async function openRulesModal(page: import('@playwright/test').Page) {
    await page.goto('/');
    await page.locator('button[title="Afficher les règles du manager (délégation + autonomie)"]').click();
    await expect(page.locator('#rulesModal')).toHaveClass(/open/);
  }

  test('Opens modal on button click', async ({ page }) => {
    await page.goto('/');
    const rulesBtn = page.locator('button[title="Afficher les règles du manager (délégation + autonomie)"]');
    await rulesBtn.click();
    await expect(page.locator('#rulesModal')).toHaveClass(/open/);
  });

  test('Displays both sections with non-empty content', async ({ page }) => {
    await openRulesModal(page);
    await expect(page.getByText('Règles dures', { exact: true })).toBeVisible();
    await expect(page.getByText('Règles de délégation', { exact: true })).toBeVisible();
    const hardContent = page.locator('#rulesHardContent');
    await expect(hardContent).not.toBeEmpty();
    const delegationContent = page.locator('#rulesDelegationContent');
    await expect(delegationContent).not.toBeEmpty();
  });

  test('Closes modal on Escape key', async ({ page }) => {
    await openRulesModal(page);
    await page.keyboard.press('Escape');
    await expect(page.locator('#rulesModal')).not.toHaveClass(/open/);
  });

  test('Closes modal on Fermer button click', async ({ page }) => {
    await openRulesModal(page);
    await page.getByRole('button', { name: 'Fermer' }).click();
    await expect(page.locator('#rulesModal')).not.toHaveClass(/open/);
  });

  test('API /api/rules returns valid JSON', async ({ request }) => {
    const res = await request.get('/api/rules');
    expect(res.status()).toBe(200);
    const body = await res.json();
    expect(typeof body.regles_dures).toBe('string');
    expect(body.regles_dures.length).toBeGreaterThan(0);
    expect(typeof body.delegation).toBe('string');
    expect(body.delegation.length).toBeGreaterThan(0);
    expect(body).toHaveProperty('source');
    expect(body).toHaveProperty('generated_at');
  });
});
