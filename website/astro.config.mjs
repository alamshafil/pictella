// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: 'https://alamshafil.github.io',
	base: 'photomagic-ai',
	integrations: [
		starlight({
			title: 'PhotoMagic AI',
			social: {
				github: 'https://github.com/alamshafil/photomagic-ai',
			},
			sidebar: [
				{
					label: 'Information',
					autogenerate: { directory: 'info' },
				},
			],
			customCss: ['./src/assets/landing.css'],
		}),
	],
});
