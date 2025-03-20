<script setup lang="ts">
import Callout from '@/components/incl/Callout.vue'
</script>

<template>
	<div class="paragraph">I am Kira<sub><small>she</small></sub>, visionary virtual machines architect</div>

	<iframe
		width="180"
		height="180"
		style="border: none; float: right"
		src="https://dimden.neocities.org/navlink/"
		name="neolink"
	></iframe>

	<div class="paragraph">
		I completed bachelor's degree at ITMO university, and my thesis was focused
		on language interoperability and it's optimization of its support in JIT, GC
		and runtime. I'm also interested in game development and visual art.
	</div>

	<div class="paragraph">
		This blog is an outlet for me to talk about my research, technological
		interests, hobbies and ideas. It consists of two main parts:
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
