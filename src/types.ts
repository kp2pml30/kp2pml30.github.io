export type FSItemDir = {
	kind: 'dir'
	name: string
	sub: FSItem[]
}

export type FSItemFileMeta = {
	date: string
}

export type FSItemFile = {
	kind: 'file'
	name: string
	meta: FSItemFileMeta
}

export type FSItem = FSItemDir | FSItemFile

export type ButtonData = {
	name: string
	item: FSItem
	index: number
}

export type FSButtonMethods = {}

export type FSData = {
	name: string
	item: FSItem
	onClick: (self: FSData) => void
	onHover: (self: FSData) => void
}
