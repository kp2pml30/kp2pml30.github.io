<script setup lang="ts">
import Callout from '@/components/incl/Callout.vue'
</script>

<template>
	<div class="paragraph">I am Kira, visionary virtual machines architect!</div>

	<div class="paragraph">
		And this is my personal website. It consists of two main parts:
		<ol>
			<li>
				<router-link to="/fs/kp2pml30">kp2pml30</router-link> — blog about
				programming
			</li>
			<li>
				<router-link to="/fs/r3vdy-2-b10vv">r3vdy-2-b10vv</router-link> — blog
				about other, more personal stuff
			</li>
		</ol>
		Both of them are available on the
		<router-link to="/fs">filesystem</router-link>
	</div>

	<Callout emoji="🏗️">
		Site is under construction. Tag clouds, dates and more content are coming
		soon.
	</Callout>
</template>

<style scoped></style>
