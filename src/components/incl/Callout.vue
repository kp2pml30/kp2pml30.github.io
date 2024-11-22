<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
	emoji: string | undefined
}>()

const emoji = computed(() => props.emoji || 'ℹ️')
</script>

<template>
	<div class="callout">
		<div>{{ emoji }}</div>
		<slot />
	</div>
</template>

<style scoped>
.callout {
	border: solid 1px;
	border-radius: 5px;
	margin: 1em;
	padding: 1em;
	display: grid;
	grid-template-columns: 5% 95%;
	background-color: var(--selection-soft-color);
	border-color: var(--primary-color);
}
</style>
