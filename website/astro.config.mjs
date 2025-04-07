// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

// https://astro.build/config
export default defineConfig({
	site: 'https://alamshafil.github.io',
	base: 'Pictella',
	integrations: [
		starlight({
			title: 'Pictella AI',
			social: {
				github: 'https://github.com/alamshafil/pictella',
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
