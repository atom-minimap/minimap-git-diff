{CompositeDisposable} = require 'event-kit'
MinimapGitDiffBinding = require './minimap-git-diff-binding'

class MinimapGitDiff

  bindings: {}
  pluginActive: false
  constructor: ->
    @subscriptions = new CompositeDisposable

  isActive: -> @pluginActive
  activate: (state) ->
    @gitDiff = atom.packages.getLoadedPackage('git-diff')
    @minimap = atom.packages.getLoadedPackage('minimap')

    return @deactivate() unless @gitDiff? and @minimap?
    return @deactivate() unless atom.project.getRepo()?

    @minimapModule = require @minimap.path

    return @deactivate() unless @minimapModule.versionMatch('3.x')
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

    @subscriptions.add @minimapModule.onDidActivate @createBindings
    @subscriptions.add @minimapModule.onDidDeactivate @destroyBindings

  deactivatePlugin: ->
    return unless @pluginActive

    @pluginActive = false
    @subscriptions.dispose()
    @destroyBindings()

  createBindings: =>
    @minimapModule.eachMinimapView ({view}) =>
      editorView = view.editorView
      editor = view.editor

      return unless editor?

      id = editor.id
      binding = new MinimapGitDiffBinding editorView, @gitDiff, view
      @bindings[id] = binding

      binding.activate()

  destroyBindings: =>
    binding.destroy() for id,binding of @bindings
    @bindings = {}

module.exports = new MinimapGitDiff
