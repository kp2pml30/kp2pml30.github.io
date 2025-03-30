<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
	name: string
	text: string
}>()
</script>

<template>
	<div class="message">
		<p>
			<small
				><span class="name">{{ name }}</span
				>:</small
			>
		</p>
		{{ text }}
	</div>
	<br />
</template>

<style scoped>
.name {
	color: var(--senary-color);
}
.message {
	border: solid 1px;
	border-radius: 5px;
	margin: 1em;
	padding: 0.5em;
	display: inline-block;
	max-width: 70%;
	border-color: var(--primary-color);
	word-wrap: normal;
	overflow-wrap: break-word;
	align-items: start;
}
</style>
