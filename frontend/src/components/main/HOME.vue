<script setup lang="ts">
import Callout from '@/components/incl/Callout.vue'
import Message from '@/components/incl/Message.vue'

interface Msg {
	name: string
	body: string
}

const messages: Msg[] = [
	{
		name: 'foo',
		body: 'bar'.repeat(100),
	},
	{
		name: 'foo',
		body: 'bar'.repeat(1000),
	},
	{
		name: 'short',
		body: 'bar '.repeat(3),
	},
]
</script>

<template>
	<div class="paragraph">
		I am Kira<sub><small>she</small></sub
		>, visionary virtual machines architect
	</div>

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
		Site is under construction. More contents is coming soon
	</Callout>

	<div style="width: 80%; align-self: center; border: solid 1px; padding: 1em; margin: auto;">
		<div style="display: block; max-height: 50vh; overflow-y: scroll;">
			<Message v-for="item in messages" :name="item.name" :text="item.body" />
		</div>
		<br/>
		<hr/>
		<br/>
		<form style="display: grid; width: 100%;" method="post" action="http://172.29.196.58:8081/blog/comment">
		<input type="text" placeholder="Name" name="name" style="margin-bottom: 0.2em;"/>
		<textarea placeholder="Text" name="body" style="resize: vertical; margin-bottom: 0.2em;"></textarea>
		<div style="display: flex; width: 100%;">
			<altcha-widget challengeurl="http://172.29.196.58:8081/altcha-challenge" debug test></altcha-widget>
			<input type="submit" value="POST" style="width: 100%;"/>
		</div>
		</form>
	</div>
</template>

<style scoped></style>
