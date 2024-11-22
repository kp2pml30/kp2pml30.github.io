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
import { AVPlugin } from 'vue-audio-visual'
import Prism from 'prismjs'

window.Prism = window.Prism || {}
window.Prism.manual = true

Prism.languages['kp2pml30-pseudo'] = {
	comment: {
		pattern: /#(\s|$)[^\n]*/,
		greedy: true,
	},
	keyword: {
		pattern:
			/\b(?:open|final|class|fn|let|var|if|else|while|loop|return|namespace|new)\b/,
		greedy: true,
	},
	'class-name': {
		pattern: /\b(?:[A-Z][a-zA-Z0-9\-_]*)\b/,
		greedy: true,
	},
	boolean: {
		pattern: /\b(?:null|undefined|true|false|this|self)\b/,
		greedy: true,
	},
	punctuation: {
		pattern: /[:,;()\[\]{}]/,
	},
	number: {
		pattern: /0|(0x[0-9a-fA-F]+)|([1-9][0-9]*(\.[0-9]+)?)/,
	},
	string: {
		pattern: /"(?:\\.|[^\\"])*"/,
	},
}

const router = createRouter({
	history: createWebHistory(),
	routes: [
		{ path: '/LICENSES', component: LICENSES },
		{ path: '/ABOUT', component: ABOUT },
		{ path: '/VIEW', component: VIEW },
		{ path: '/FS', component: FS },
		{ path: '/', component: HOME },
	],
})

const app = createApp(App)

app.use(AVPlugin)
app.use(router)

app.mount('#app')

Prism.highlightAll()
