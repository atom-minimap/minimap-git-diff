{Subscriber} = require 'emissary'
MinimapGitDiffBinding = require './minimap-git-diff-binding'

class MinimapGitDiff
  Subscriber.includeInto(this)

  bindings: {}
  pluginActive: false
  isActive: -> @pluginActive
  activate: (state) ->
    @gitDiff = atom.packages.getLoadedPackage('git-diff')
    @minimap = atom.packages.getLoadedPackage('minimap')

    return @deactivate() unless @gitDiff? and @minimap?
    return @deactivate() unless atom.project.getRepo()?

    @minimapModule = require @minimap.path
    @minimapModule.registerPlugin 'git-diff', this

  deactivate: ->
    binding.destroy() for id,binding of @bindings
    @bindings = {}
    @gitDiff = null
    @minimap = null
    @minimapModule = null

  activatePlugin: ->
    return if @pluginActive

    @createBindings()

    @pluginActive = true

    @subscribe @minimapModule, 'activated', @createBindings
    @subscribe @minimapModule, 'deactivated', @destroyBindings

  deactivatePlugin: ->
    return unless @pluginActive

    @pluginActive = false
    @unsubscribe()
    @destroyBindings()

  createBindings: =>
    atom.workspaceView.eachEditorView (editor) =>
      id = editor.getModel().id
      binding = new MinimapGitDiffBinding editor, @gitDiff, @minimap
      @bindings[id] = binding

      binding.activate()

  destroyBindings: =>
    binding.destroy() for id,binding of @bindings
    @bindings = {}

module.exports = new MinimapGitDiff
