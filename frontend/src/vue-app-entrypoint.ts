import type { App } from 'vue'
import { AVPlugin } from 'vue-audio-visual'
import Toast from 'vue-toastification'
import 'vue-toastification/dist/index.css'

export default (app: App) => {
	app.use(AVPlugin)
	app.use(Toast)
}
