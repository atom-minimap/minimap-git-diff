/** @babel */

const MinimapGitDiff = require('../lib/minimap-git-diff')

describe('MinimapGitDiff', () => {
	let workspace

	beforeEach(async () => {
		workspace = atom.views.getView(atom.workspace)
		jasmine.attachToDOM(workspace)

		// Package activation will be deferred to the configured, activation hook, which is then triggered
		// Activate activation hook
		atom.packages.triggerDeferredActivationHooks()
		atom.packages.triggerActivationHook('core:loaded-shell-environment')
		await atom.packages.activatePackage('minimap')
	})

	describe('when the package is activated', () => {
		beforeEach(async () => {
			await atom.packages.activatePackage('minimap-git-diff')
		})

		it('should activate', () => {
			expect(MinimapGitDiff.isActive()).toBe(true)
		})
	})
})
