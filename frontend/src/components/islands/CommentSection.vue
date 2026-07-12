<script setup lang="ts">
import Message from '@/components/incl/Message.vue'
import { onMounted, ref } from 'vue'
import { useToast } from 'vue-toastification'
import 'altcha'

onMounted(() => {
	readMessages()
})

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
</script>

<template>
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
					auto="onsubmit"
					colorscheme="dark"
				></altcha-widget>
				<input type="submit" value="POST" style="width: 100%" />
			</div>
		</form>
	</div>
</template>

<style>
altcha-widget {
	color-scheme: dark;
	--altcha-color-base: var(--background-soft-color);
	--altcha-color-base-content: var(--foreground-color);
	--altcha-color-neutral: var(--muted-soft-color);
	--altcha-color-neutral-content: var(--foreground-color);
	--altcha-color-primary: var(--primary-color);
	--altcha-color-primary-content: var(--background-color);
	--altcha-color-success: var(--success-color);
	--altcha-color-success-content: var(--background-color);
	--altcha-border-color: var(--foreground-soft-color);
	--altcha-input-background-color: var(--background-darker-color);
	--altcha-input-color: var(--foreground-color);
	--altcha-checkbox-border-color: var(--foreground-soft-color);
	--altcha-spinner-color: var(--foreground-color);
}
</style>
