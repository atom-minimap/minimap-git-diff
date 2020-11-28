const { CompositeDisposable } = require('atom')

let MinimapGitDiffBinding = null

module.exports = {
	config: {
		useGutterDecoration: {
			type: 'boolean',
			default: false,
			description: 'When enabled the git diffs will be displayed as thin vertical lines on the left side of the minimap.',
		},
	},

	isActive () {
		return this.pluginActive
	},

	activate () {
		this.pluginActive = false
		this.subscriptions = new CompositeDisposable()
		this.bindings = new WeakMap()
		require('atom-package-deps').install('minimap-git-diff')
	},

	consumeMinimapServiceV1 (minimap) {
		this.minimap = minimap
		return this.minimap.registerPlugin('git-diff', this)
	},

	deactivate () {
		this.destroyBindings()
		this.minimap = null
	},

	activatePlugin () {
		if (this.pluginActive) { return }

		try {
			this.createBindings()
			this.pluginActive = true

			this.subscriptions.add(this.minimap.onDidActivate(this.createBindings.bind(this)))
			this.subscriptions.add(this.minimap.onDidDeactivate(this.destroyBindings.bind(this)))
		} catch (e) {
			console.log(e)
		}
	},

	deactivatePlugin () {
		if (!this.pluginActive) { return }

		this.pluginActive = false
		this.subscriptions.dispose()
		this.destroyBindings()
	},

	createBindings () {
		if (!MinimapGitDiffBinding) { MinimapGitDiffBinding = require('./minimap-git-diff-binding') }

		this.subscriptions.add(this.minimap.observeMinimaps(o => {
			const minimap = o.view ? o.view : o
			const editor = minimap.getTextEditor()

			if (!editor) { return }

			const binding = new MinimapGitDiffBinding(minimap)
			this.bindings.set(minimap, binding)
		}),
		)
	},

	destroyBindings () {
		if (!this.minimap || !this.minimap.editorsMinimaps) { return }
		this.minimap.editorsMinimaps.forEach(minimap => {
			const minimapBinding = this.bindings.get(minimap)
			if (minimapBinding) {
				minimapBinding.destroy()
			}
			this.bindings.delete(minimap)
		})
	},
}
