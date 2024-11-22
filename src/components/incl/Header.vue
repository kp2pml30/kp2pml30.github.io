<script setup lang="ts">
defineProps<{}>()
</script>

<template>
	<div class="header">
		<span class="id"
			><span style="color: var(--quaternary-color)">kp2pml30</span>'s personal
			blog</span
		>
		<span class="item"
			><router-link to="/">HOME</router-link>
			<router-link to="/FS">ROFS</router-link>
			<router-link to="/ABOUT">ABOUT</router-link></span
		>
		<br />
		<hr />
	</div>
</template>

<style scoped>
.header {
	text-align: center;
	width: 100%;
	display: block;
	font-size: large;
	margin-bottom: 1em;
}
.id {
	float: left;
}
.item {
	float: right;
}
</style>
