<script setup lang="ts">
import * as types from '@/types'
import { computed, onMounted, ref, useTemplateRef } from 'vue'

const props = defineProps<{
	name: string
	item: types.FSItem
	index: number
	selected: boolean
}>()

const idex = ref(props.index)

const emits = defineEmits<{
	(e: 'click', self: types.FSButtonMethods, data: types.ButtonData): void
	(
		e: 'hover',
		self: types.FSButtonMethods,
		data: types.ButtonData,
		mousein: boolean
	): void
}>()

const active = ref(false)

const data = computed(() => {
	return {
		name: props.name,
		item: props.item,
		index: props.index,
	}
})

const isDir = computed(() => {
	return props.item.kind === 'dir'
})

onMounted(() => {
	if (props.selected) {
		emits('hover', {}, data.value, true)
	}
})

function handleMousemove() {
	if (!props.selected) emits('hover', {}, data.value, true)
}
</script>

<template>
	<div>
		<button
			@click="$emit('click', {}, data)"
			@mouseover="$emit('hover', {}, data, true)"
			@mousemove="handleMousemove()"
			@mouseleave="$emit('hover', {}, data, false)"
			class="default-font"
			v-bind:class="{ active: selected, 'is-dir': isDir, 'is-file': !isDir }"
		>
			{{ name }}{{ isDir ? '/' : '' }}
		</button>
		<br />
	</div>
</template>

<style scoped>
button {
	width: 100%;
	text-align: left;
	background: transparent;
	border: none;
}
.active {
	background: var(--selection-color);
}
.is-dir {
	color: var(--secondary-color);
}
.is-file {
	color: var(--foreground-color);
}
</style>
