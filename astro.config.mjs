import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import icon from 'astro-icon';

export default defineConfig({
  site: 'https://landing-finance.kedein.com',
  output: 'static',
  integrations: [
    sitemap({
      filter: (page) => !page.includes('/terms') && !page.includes('/privacy'),
    }),
    icon(),
  ],
});
