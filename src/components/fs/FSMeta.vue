<script setup lang="ts">
import type { FSItemFileMeta } from '@/types'

const props = defineProps<{
	meta: FSItemFileMeta
	path: string
}>()
</script>

<template>
	<router-link :to="'/view/' + path">VIEW</router-link> {{ props.meta.date }}
</template>

<style scoped></style>
