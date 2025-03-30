<script setup lang="ts">
import { onMounted, onUnmounted, ref } from 'vue'

let now = ref('')

const UTC_OFFSET_HOURS = 4

function setNow() {
	const n = new Date()
	const hours = (n.getUTCHours() + UTC_OFFSET_HOURS) % 24
	const minutes = n.getUTCMinutes()
	now.value = `${hours}`.padStart(2, '0') + ':' + `${minutes}`.padStart(2, '0')
}

function useIntervalFn(ms: number, cb: () => void) {
	let int: number = 0
	onMounted(() => (int = setInterval(cb, ms)))
	onUnmounted(() => clearInterval(int))
}

useIntervalFn(5000, setNow)

setNow()
</script>

<template>
	I am Kira ><> Prokopenko, visionary virtual machines architect

	<hr class="hr-space" />

	<h2>Pronouns</h2>
	<ul>
		<li>she</li>
		<li>they</li>
	</ul>

	<h2>Contacts</h2>

	<ul>
		<li><a href="mailto:kp2pml30@gmail.com">kp2pml30@gmail.com</a></li>
		<li><a href="https://t.me/kp2pml30">@kp2pml30</a> (telegram)</li>
		<li>Timezone: UTC+4 ({{ now }})</li>
	</ul>

	<h2>Other socials</h2>

	<ul>
		<li><a href="https://discord.gg/TYjNRpFknx">discord server</a></li>
		<li><a href="https://www.twitch.tv/r3vdy2b10vv">twitch</a></li>
		<li>
			<a href="https://stackoverflow.com/users/17500068/kp2pml30"
				>stack overflow</a
			>
		</li>
	</ul>

	<hr class="hr-space" />
	<h2>Donate</h2>
	<ul>
		<li><a href="https://ko-fi.com/r3vdy2b10vv">ko-fi</a></li>
		<li>eth 0x2D50eDE32E32481E06B261E5c9C2224B2A271add</li>
	</ul>

	<hr class="hr-space" />
	<h2>Identities</h2>
	<ul>
		<li>pgp keys: TBA</li>
		<li>
			ssh keys (current): see on
			<a href="https://github.com/kp2pml30.keys">github</a>
		</li>
		<li>eth 0x2D50eDE32E32481E06B261E5c9C2224B2A271add</li>
	</ul>

	<h2>Git profiles</h2>
	<ul>
		<li>
			<a href="https://github.com/kp2pml30">github</a> (Yeager AI and open
			source contributions)
		</li>
		<li>
			<a href="https://gitee.com/kprokopenko">gitee</a> (Huawei (Open Harmony)
			contributions)
		</li>
		<li>
			<a href="https://git.kp2pml30.moe">personal git</a>
		</li>
	</ul>

	<h2>Work</h2>
	<ul>
		<li><a href="https://linkedin.com/in/kp2pml30">linkedin</a></li>
		<li>
			<a
				href="https://github.com/kp2pml30/cv/blob/artifacts/cv.pdf"
				target="_blank"
				>cv</a
			>
			(note: if I am not looking for a job it may be outdated)
		</li>
	</ul>
</template>
