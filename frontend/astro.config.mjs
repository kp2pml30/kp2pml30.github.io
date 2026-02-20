import { defineConfig } from 'astro/config'
import vue from '@astrojs/vue'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
	integrations: [
		vue({
			appEntrypoint: '/src/vue-app-entrypoint',
		}),
	],
	output: 'static',
	vite: {
		resolve: {
			alias: {
				'@': fileURLToPath(new URL('./src', import.meta.url)),
			},
		},
	},
})
