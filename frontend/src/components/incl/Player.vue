<script setup lang="ts">
const props = defineProps<{
	src: string
}>()

import { computed } from '@vue/reactivity'
import { ref } from 'vue'
import { useAVWaveform } from 'vue-audio-visual'
import { useCssVar } from '@vueuse/core'

const primaryColor = useCssVar('--primary-color')
const primarySoftColor = useCssVar('--primary-soft-color')
const selectionColor = useCssVar('--selection-color')
const secondaryColor = useCssVar('--secondary-color')
const tertiaryColor = useCssVar('--tertiary-color')

const player = ref<HTMLAudioElement | undefined>(undefined)
const canvas = ref<HTMLCanvasElement | undefined>(undefined)

useAVWaveform(player, canvas, {
	src: props.src,
	noplayedLineColor: primaryColor,
	playedLineColor: selectionColor,
	playtimeFontColor: tertiaryColor,
	playtimeSliderColor: secondaryColor,
})

const isPause = ref<boolean>(player?.value?.paused || true)

function triggerPlayer() {
	const pl = player.value
	if (pl === undefined) {
		return
	}
	if (pl.paused) {
		pl.play()
	} else {
		pl.pause()
	}
}
</script>

<template>
	<audio ref="player" :src="props.src" controls hidden />
	<div class="play-container">
		<div class="inner">
			<button @click="triggerPlayer" :style="`height: ${canvas?.height}px;`">
				⏯
			</button>
		</div>
		<div class="inner">
			<canvas ref="canvas" />
		</div>
	</div>
</template>

<style scoped>
.play-container {
	max-width: 100%;
	overflow-x: hidden;
	display: flex;
	align-items: center;
}
.inner {
	float: left;
	margin-right: 0.3em;
}
</style>
