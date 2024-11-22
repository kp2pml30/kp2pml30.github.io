<script setup lang="ts">
import { computed, onMounted, ref, watch, type Ref } from 'vue'
import { AVWaveform } from 'vue-audio-visual'
import Player from '@/components/incl/Player.vue'
import Prism from 'prismjs'

const props = defineProps<{
	path: string
}>()

type Data =
	| { kind: 'unknown' }
	| { kind: 'html'; contents: string }
	| { kind: 'music'; path: string }

const data: Ref<Data> = ref({ kind: 'html', contents: '' })

async function upd() {
	if (props.path.endsWith('.png') || props.path.endsWith('.jpg')) {
		data.value = {
			kind: 'html',
			contents: `<img style="max-width: 100%; max-height: 100% object-fit: contain; display: block; margin-left: auto; margin-right: auto;" src="/fs-tree/${props.path}" />`,
		}
	} else if (props.path.endsWith('.html')) {
		const contents = await (await fetch('/fs-tree/' + props.path)).text()
		const doc = new DOMParser().parseFromString(contents, 'text/html')
		Prism.highlightAllUnder(doc)
		const div = document.createElement('div')
		for (const el of doc.childNodes) {
			div.appendChild(el)
		}
		data.value = {
			kind: 'html',
			contents: div.innerHTML,
		}
	} else if (props.path.endsWith('.mp3') || props.path.endsWith('.wav')) {
		data.value = {
			kind: 'music',
			path: '/fs-tree/' + props.path,
		}
	} else {
		data.value = { kind: 'unknown' }
	}
}

watch(props, async () => {
	upd()
})

onMounted(async () => {
	upd()
})
</script>

<template>
	<div class="preview">
		<div id="preview-has-code" v-if="data.kind == 'html'">
			<span v-html="data.contents"></span>
		</div>
		<div v-else-if="data.kind == 'music'" class="music">
			<Player :src="data.path" />
		</div>
		<div v-else>
			Unknown file format<br /><a :href="'/fs-tree/' + props.path"
				>Raw contents link</a
			>
		</div>
	</div>
</template>

<style scoped>
.music {
	display: block;
	margin-left: auto;
	margin-right: auto;
}
</style>
