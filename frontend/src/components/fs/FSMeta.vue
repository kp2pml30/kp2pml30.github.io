<script setup lang="ts">
import type { FSItemFileMeta } from '@/types'

const props = defineProps<{
	meta: FSItemFileMeta
	path: string
}>()
</script>

<template>
	<a :href="'/view/' + path">VIEW</a> {{ props.meta.date }}
</template>

<style scoped></style>
