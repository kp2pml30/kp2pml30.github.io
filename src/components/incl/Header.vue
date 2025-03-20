<script setup lang="ts">
defineProps<{}>()
</script>

<template>
	<div class="header-all">
		<div class="header">
			<span class="id"
				><router-link to="/"
					><span style="color: var(--quaternary-color); padding: 0px"
						>kp2pml30</span
					></router-link
				>'s personal blog</span
			>
			<span class="item"
				><router-link to="/">HOME</router-link>
				<router-link to="/fs">ROFS</router-link>
				<router-link to="/about">ABOUT</router-link>
				<router-link to="/lnk">LNK</router-link></span
			>
		</div>
		<hr />
	</div>
</template>

<style scoped>
.header {
	text-align: center;
	width: 100%;
	display: block;
	font-size: large;
}
.header-all {
	width: 100%;
	display: grid;
	margin-bottom: 1em;
}
.id {
	float: left;
}
.item {
	float: right;
}
</style>
