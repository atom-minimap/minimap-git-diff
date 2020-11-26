const { CompositeDisposable } = require('atom')
const { repositoryForPath } = require('./helpers')

class MinimapGitDiffBinding {
	constructor (minimap) {
		this.active = false
		this.updateDiffs = this.updateDiffs.bind(this)
		this.destroy = this.destroy.bind(this)
		this.minimap = minimap
		this.decorations = {}
		this.markers = null
		this.subscriptions = new CompositeDisposable()

		if (!this.minimap) {
			console.warn('minimap-git-diff binding created without a minimap')
			return
		}

		this.editor = this.minimap.getTextEditor()

		this.subscriptions.add(this.minimap.onDidDestroy(this.destroy))

		this.getRepo().then(repo => {
			this.repository = repo
			if (repo) {
				this.subscriptions.add(this.editor.getBuffer().onDidStopChanging(this.updateDiffs))
				this.subscriptions.add(this.repository.onDidChangeStatuses(() => {
					this.scheduleUpdate()
				}))
				this.subscriptions.add(this.repository.onDidChangeStatus(changedPath => {
					if (changedPath === this.editor.getPath()) { this.scheduleUpdate() }
				}))
				this.subscriptions.add(this.repository.onDidDestroy(() => {
					this.destroy()
				}))
				this.subscriptions.add(atom.config.observe('minimap-git-diff.useGutterDecoration', useGutterDecoration => {
					this.useGutterDecoration = useGutterDecoration
					this.scheduleUpdate()
				}))
			}
		})

		this.scheduleUpdate()
	}

	cancelUpdate () {
		clearImmediate(this.immediateId)
	}

	scheduleUpdate () {
		this.cancelUpdate()
		this.immediateId = setImmediate(this.updateDiffs)
	}

	updateDiffs () {
		this.removeDecorations()
		if (this.getPath() && (this.diffs = this.getDiffs())) {
			this.addDecorations(this.diffs)
		}
	}

	addDecorations (diffs) {
		for (const { newStart, oldLines, newLines } of Array.from(diffs)) {
			const startRow = newStart - 1
			const endRow = (newStart + newLines) - 2
			if ((oldLines === 0) && (newLines > 0)) {
				this.markRange(startRow, endRow, '.git-line-added')
			} else if ((newLines === 0) && (oldLines > 0)) {
				this.markRange(startRow, startRow, '.git-line-removed')
			} else {
				this.markRange(startRow, endRow, '.git-line-modified')
			}
		}
	}

	removeDecorations () {
		if (!this.markers) { return }
		for (const marker of Array.from(this.markers)) { marker.destroy() }
		this.markers = null
	}

	markRange (startRow, endRow, scope) {
		if (this.editor.isDestroyed()) { return }
		const marker = this.editor.markBufferRange([[startRow, 0], [endRow, Infinity]], { invalidate: 'never' })
		const type = this.useGutterDecoration ? 'gutter' : 'line'
		this.minimap.decorateMarker(marker, { type, scope: `.minimap .${type} ${scope}`, plugin: 'git-diff' })
		if (!this.markers) { this.markers = [] }
		this.markers.push(marker)
	}

	destroy () {
		this.removeDecorations()
		this.subscriptions.dispose()
		this.diffs = null
		this.minimap = null
	}

	getPath () {
		const buffer = this.editor.getBuffer()
		if (buffer) {
			return buffer.getPath()
		}
	}

	getRepo () { return repositoryForPath(this.editor.getPath()) }

	getDiffs () {
		try {
			const buffer = this.editor.getBuffer()
			if (this.repository && buffer) {
				return this.repository.getLineDiffs(this.getPath(), buffer.getText())
			}
		} catch (e) {}

		return null
	}
}

module.exports = MinimapGitDiffBinding
