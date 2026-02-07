<script setup lang="ts">
import Callout from '@/components/incl/Callout.vue'
import Message from '@/components/incl/Message.vue'
import { ref } from 'vue'
import { useToast } from 'vue-toastification'

interface Msg {
	name: string
	body: string
}

const toast = useToast()

const messages = ref([] as Msg[])

const BACKEND_ADDR = 'https://backend.kp2pml30.moe'
//const BACKEND_ADDR = 'http://localhost:8081'

function submitForm() {
	const formElement = document.getElementById('postComment') as HTMLFormElement
	const formData = new FormData(formElement)
	const urlEncodedData = new URLSearchParams()

	for (const [key, value] of formData.entries()) {
		urlEncodedData.append(key, value as any)
	}
	formElement.reset()

	fetch(`${BACKEND_ADDR}/blog/comment`, {
		method: 'POST',
		headers: {
			'Content-Type': 'application/x-www-form-urlencoded',
		},
		body: urlEncodedData.toString(),
	})
		.then((response) => response.json())
		.then((data) => {
			toast.success('Comment was succesfully submitted for moderation')
		})
		.catch((error) => {
			console.error('Error:', error)
			toast.error(`Error occured :( ${error}`)
		})
}

async function readMessages() {
	const resp = await fetch(`${BACKEND_ADDR}/blog/comment`)
	const body = await resp.text()
	let newMsg = [] as Msg[]
	for (const line of body.split('\n')) {
		if (line.length == 0 || line == '\n') {
			continue
		}
		const msg: Msg = JSON.parse(line)
		newMsg.push(msg)
	}
	messages.value = newMsg
}

readMessages()
</script>

<template>
	<div class="paragraph">I am Kira, visionary virtual machines architect</div>

	<iframe
		width="180"
		height="180"
		style="border: none; float: right"
		src="https://dimden.neocities.org/navlink/"
		name="neolink"
	></iframe>

	<div class="paragraph">
		I completed bachelor's degree at ITMO university, and my thesis was focused
		on language interoperability and optimization of its support in JIT, GC and
		runtime. I'm also interested in game development and visual art.
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

	<div class="paragraph">
		You can subscribe to RSS <a href="/a/generated/feed.xml"><img src="/a/rss.svg" style="height: 1em; vertical-align: middle"></a>
	</div>

	<Callout emoji="🏗️">
		Site is under construction. More content is coming soon
	</Callout>

	<div
		style="
			width: 80%;
			align-self: center;
			border: solid 1px;
			padding: 1em;
			margin: auto;
		"
	>
		<div style="display: block; max-height: 50vh; overflow-y: scroll">
			<Message v-for="item in messages" :name="item.name" :text="item.body" />
		</div>
		<br />
		<hr />
		<br />
		<form
			style="display: grid; width: 100%"
			method="post"
			@submit.prevent="submitForm"
			id="postComment"
		>
			<input
				type="text"
				placeholder="Name"
				name="name"
				style="margin-bottom: 0.2em"
				required
			/>
			<textarea
				placeholder="Text"
				name="body"
				style="resize: vertical; margin-bottom: 0.2em"
				required
			></textarea>
			<div style="display: flex; width: 100%">
				<altcha-widget
					:challengeurl="`${BACKEND_ADDR}/altcha-challenge`"
					debug
				></altcha-widget>
				<input type="submit" value="POST" style="width: 100%" />
			</div>
		</form>
	</div>
	<div style="display: flex; gap: 4px; flex-wrap: wrap; justify-content: center; margin-top: 1em">
		<a href="/a/generated/feed.xml"><img class="banner-img" src="/a/88x31/rss.gif"></a>
		<a href="https://www.goldfingerparty.com/bar/"><img class="banner-img" src="/a/88x31/goldfinger.gif"></a>
		<a href="https://lit.link/en/tokyotransmarch"><img class="banner-img" src="/a/88x31/tmarsh.gif"></a>
		<a href="https://etherscan.io/address/0x2D50eDE32E32481E06B261E5c9C2224B2A271add"><img class="banner-img" src="/a/88x31/donate.gif"></a>
		<a href="https://zh.wikipedia.org/"><img class="banner-img" src="/a/88x31/Zhwikipedialogo.gif"></a>
		<a href="https://github.com/kp2pml30"><img class="banner-img" src="/a/88x31/open_source.png"></a>
		<a href="https://discord.gg/TYjNRpFknx"><img class="banner-img" src="/a/88x31/discord.gif"></a>
	</div>
</template>

<style scoped>
.banner-img {
	height: 62px;
	image-rendering: pixelated;
}
</style>
