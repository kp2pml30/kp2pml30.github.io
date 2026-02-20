<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'

const now = ref('')

const UTC_OFFSET_HOURS = 9

function setNow() {
	const n = new Date()
	const hours = (n.getUTCHours() + UTC_OFFSET_HOURS) % 24
	const minutes = n.getUTCMinutes()
	now.value = `${hours}`.padStart(2, '0') + ':' + `${minutes}`.padStart(2, '0')
}

let interval: number = 0

onMounted(() => {
	setNow()
	interval = setInterval(setNow, 5000)
})

onUnmounted(() => clearInterval(interval))
</script>

<template>
	<span>{{ now }}</span>
</template>
