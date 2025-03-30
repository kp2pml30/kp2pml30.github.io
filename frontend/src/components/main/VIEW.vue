<script setup lang="ts">
import { ref } from 'vue'
import FSPreview from '../fs/FSPreview.vue'

const path = ref(
	new URL(window.location.href).pathname.replace(/^\/view\//, '')
)
console.log(path.value)
</script>

<template>
	<Suspense>
		<FSPreview :path="path" />
		<template #fallback> Loading... </template>
	</Suspense>
</template>

<style scoped></style>
