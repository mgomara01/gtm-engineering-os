import { test,expect } from '@playwright/test';
test('workspace overview renders',async({page})=>{await page.goto('/');await expect(page.getByText('Workspace Overview')).toBeVisible()});
test('implementation manager exposes twelve stages',async({page})=>{await page.goto('/implementation');await expect(page.getByRole('heading',{name:'Implementation Manager'})).toBeVisible();await expect(page.getByText('Scaling',{exact:true})).toBeVisible()});
