<script setup lang="ts">
import type { FSItemFileMeta } from '@/types'

const props = defineProps<{
	meta: FSItemFileMeta
	path: string
}>()
</script>

<template>
	<router-link :to="'/VIEW#' + path">VIEW</router-link> {{ props.meta.date }}
</template>

<style scoped></style>
