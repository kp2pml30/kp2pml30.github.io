import './assets/main.css'
import './assets/code.css'

import { createApp } from 'vue'
import FS from './components/main/FS.vue'
import App from './App.vue'
import { createRouter, createWebHistory } from 'vue-router'
import ABOUT from './components/main/ABOUT.vue'
import HOME from './components/main/HOME.vue'
import VIEW from './components/main/VIEW.vue'
import LICENSES from './components/main/LICENSES.vue'
import LNK from './components/main/lnk.vue'
import { AVPlugin } from 'vue-audio-visual'

const router = createRouter({
	history: createWebHistory(),
	routes: [
		{ path: '/LICENSES', component: LICENSES },
		{ path: '/ABOUT', component: ABOUT },
		{ path: '/VIEW', component: VIEW },
		{ path: '/FS', component: FS },
		{ path: '/lnk', component: LNK },
		{ path: '/', component: HOME },
	],
})

const app = createApp(App)

app.use(AVPlugin)
app.use(router)

app.mount('#app')
