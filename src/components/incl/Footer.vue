<script setup lang="ts">
defineProps<{}>()
</script>

<template>
	<div class="footer">
		<hr />
		Copyright (C) 2023-2025
		<span style="color: var(--quaternary-color)">kp2pml30</span>, see
		<router-link to="/LICENSES">LICENSE</router-link>
	</div>
</template>

<style scoped>
.footer {
	text-align: center;
	width: 100%;
	display: block;
	margin-top: 1em;
}
</style>
