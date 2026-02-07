<script setup lang="ts">
defineProps<{}>()
</script>

<template>
	<div class="footer">
		<hr />
		Copyright (C) 2023-2026
		<span style="color: var(--quaternary-color)">kp2pml30</span>, see
		<router-link to="/LICENSES">LICENSE</router-link>
		<br />
		<small
			>All opinions here are my own and do not reflect the views of my employers
			or university: future, past, and present.</small
		>
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
