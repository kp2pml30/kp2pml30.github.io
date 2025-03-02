<script setup lang="ts">
import { computed, onMounted, ref, watch, type Ref } from 'vue'

import tree_json_imp from '@/tree.json'
import * as types from '@/types'
import FSButton from '../fs/FSButton.vue'
import FSPreview from '../fs/FSPreview.vue'
import FSMeta from '../fs/FSMeta.vue'

const tree_json = tree_json_imp as types.FSItemDir

type ChainItem = {
	name: string
	selected: number
	dir: types.FSItemDir
	prev: ChainItem | undefined
}

const cur_index = ref(0)

const cur_chain: Ref<ChainItem> = ref(
	(() => {
		let init_chain: ChainItem = {
			name: '',
			selected: 0,
			dir: tree_json,
			prev: undefined,
		}
		const url = new URL(window.location.href)
		let savedPath = url.pathname
		if (savedPath.startsWith('/fs/')) {
			savedPath = savedPath.substring(4)
		}
		for (const part of savedPath.split('/')) {
			const idx = init_chain.dir.sub.findIndex((v) => v.name == part)
			if (idx < 0) {
				break
			}
			init_chain.selected = idx
			const next = init_chain.dir.sub[idx]
			if (next.kind === 'file') {
				break
			}
			init_chain = {
				name: part,
				selected: 0,
				dir: next,
				prev: init_chain,
			}
		}
		if (url.hash != '') {
			const hash = url.hash.replace(/^#/, '')
			init_chain.selected = Math.max(
				0,
				init_chain.dir.sub.findIndex((v) => v.name == hash)
			)
		}
		cur_index.value = init_chain.selected
		return init_chain
	})()
)

const cur_path = computed(() => {
	let cur: ChainItem | undefined = cur_chain.value
	let ans: string[] = []
	while (cur !== undefined) {
		ans.push(cur.name)
		cur = cur.prev
	}
	if (ans[ans.length - 1] === '') {
		ans.pop()
	}
	return ans.reverse().join('/')
})

function pressedPrev(self: types.FSButtonMethods, data: types.ButtonData) {
	if (cur_chain.value.prev === undefined) {
		return
	}
	cur_chain.value = cur_chain.value.prev
	cur_index.value = cur_chain.value.selected
}

function pressedNext(self: types.FSButtonMethods, data: types.ButtonData) {
	if (data.item.kind !== 'dir') {
		return
	}
	const idx = cur_index.value
	cur_chain.value.selected = idx
	cur_index.value = 0
	const old_val = cur_chain.value
	cur_chain.value = {
		name: data.name,
		selected: 0,
		dir: data.item,
		prev: old_val,
	}
}

function hoveredNext(
	self: types.FSButtonMethods,
	data: types.ButtonData,
	mouseIn: boolean
) {
	if (!mouseIn) {
		return
	}
	cur_index.value = data.index
}

const is_dir = computed(() => {
	const idx = cur_index.value
	if (idx >= cur_chain.value.dir.sub.length) {
		return false
	}
	return cur_chain.value.dir.sub[cur_index.value].kind === 'dir'
})

watch([cur_path, cur_chain, cur_index], ([cp, cc, ci]) => {
	let res = '/fs/'
	if (cp != '') {
		res += cp
		if (cur_chain.value.dir.sub[cur_index.value].kind == 'dir') {
			res += '#'
		} else {
			res += '/'
		}
	}

	history.pushState({}, '', res + cc.dir.sub[ci].name)
})
</script>

<template>
	<span style="color: var(--quaternary-color)">guest</span
	><span style="color: var(--tertiary-color)">@kp2pml30-blog</span>&nbsp;
	<span style="color: var(--secondary-color)">/{{ cur_path }}</span>

	<div class="fs-columns">
		<div class="prev-col col col-bord">
			<div class="content">
				<div v-if="cur_chain.prev == undefined"></div>
				<div v-else>
					<FSButton
						v-for="(item, index) in cur_chain.prev.dir.sub"
						:name="item.name"
						:item="item"
						:index="index"
						:selected="cur_chain.prev.selected === index"
						@click="pressedPrev"
					/>
				</div>
			</div>
		</div>
		<div class="cur-col col col-bord">
			<div class="content">
				<FSButton
					v-for="(item, index) in cur_chain.dir.sub"
					:name="item.name"
					:item="item"
					:index="index"
					:selected="index === cur_index"
					@click="pressedNext"
					@hover="hoveredNext"
				/>
			</div>
		</div>
		<div class="preview-col col">
			<div class="content">
				<div v-if="cur_chain.dir.sub.length == 0"></div>
				<div v-else-if="cur_chain.dir.sub[cur_index].kind == 'dir'">
					<FSButton
						v-for="(item, index) in (
							cur_chain.dir.sub[cur_index] as types.FSItemDir
						).sub"
						:name="item.name"
						:item="item"
						:index="index"
						:selected="false"
					/>
				</div>
				<div v-else>
					<Suspense>
						<FSPreview
							:path="cur_path + '/' + cur_chain.dir.sub[cur_index].name"
						/>
						<template #fallback> Loading... </template>
					</Suspense>
				</div>
			</div>
		</div>
	</div>

	<div class="bottom-line">
		<span class="bottom-rights"
			>{{ is_dir ? 'd' : '-' }}rwxr--r--
			<span style="color: var(--quaternary-color)">Kira</span></span
		>
		<span class="bottom-meta">
			<FSMeta
				v-if="
					cur_chain.dir.sub.length > 0 &&
					cur_chain.dir.sub[cur_index].kind == 'file'
				"
				:meta="(cur_chain.dir.sub[cur_index] as types.FSItemFile).meta"
				:path="cur_path + '/' + cur_chain.dir.sub[cur_index].name"
			/>
		</span>
	</div>
	<br />
</template>

<style scoped>
.bottom-rights {
	color: var(--senary-color);
}
.fs-columns {
	display: flex;
	flex-direction: row;
}
.prev-col {
	width: 20%;
}
.cur-col {
	width: 30%;
}
.preview-col {
	width: 50%;
}
.col {
	min-height: 75vh;
	max-height: 75vh;
	overflow-y: auto;
	border-top: solid;
	border-bottom: solid;
	border-width: 1;
}
.col-bord {
	border-right: solid;
}
.content {
	margin: 1vh;
}

.bottom-line {
	width: 80%;
	display: block;
	margin-left: 10%;
	margin-right: 10%;
}
.bottom-rights {
	float: left;
}
.bottom-meta {
	float: right;
}
</style>
