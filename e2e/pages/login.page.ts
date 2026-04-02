import type { Page } from '@playwright/test';
import { BasePage } from './base.page';

/**
 * Page object for the /login route.
 *
 * Used to perform dev-bypass authentication so that smoke tests can
 * access auth-protected routes without a real OIDC provider.
 */
export class LoginPage extends BasePage {
  constructor(page: Page) {
    super(page);
  }

  /** Navigate to the login page. */
  async navigate(): Promise<void> {
    await this.goto('/login');
  }

  /** Click the dev-login button (visible when DEV_AUTH_BYPASS=true). */
  async devLogin(): Promise<void> {
    const devLoginBtn = this.page.getByTestId('dev-login-btn');
    await devLoginBtn.waitFor({ state: 'visible', timeout: 15_000 });
    await devLoginBtn.click();
  }

  /** Whether the dev-login button is visible on the page. */
  async isDevLoginVisible(): Promise<boolean> {
    return this.page.getByTestId('dev-login-btn').isVisible();
  }
}
