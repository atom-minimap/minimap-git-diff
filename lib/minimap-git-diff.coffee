{CompositeDisposable, Disposable} = require 'event-kit'
MinimapGitDiffBinding = require './minimap-git-diff-binding'

requirePackages = (packages...) ->
  new Promise (resolve, reject) ->
    required = []
    promises = []
    failures = []
    remains = packages.length

    solved = ->
      remains--
      return unless remains is 0
      return reject(failures) if failures.length > 0
      resolve(required)

    packages.forEach (pkg, i) ->
      promises.push(atom.packages.activatePackage(pkg)
      .then (activatedPackage) ->
        required[i] = activatedPackage.mainModule
        solved()
      .fail (reason) ->
        failures[i] = reason
        solved()
      )

class MinimapGitDiff

  bindings: {}
  pluginActive: false
  constructor: ->
    @subscriptions = new CompositeDisposable

  isActive: -> @pluginActive
  activate: (state) ->
    requirePackages('minimap', 'git-diff').then ([@minimap, @gitDiff]) =>
      return @deactivate() unless @minimap.versionMatch('3.x')
      @minimap.registerPlugin 'git-diff', this

  deactivate: ->
    binding.destroy() for id,binding of @bindings
    @bindings = {}
    @gitDiff = null
    @minimap = null

  activatePlugin: ->
    return if @pluginActive

    @activateBinding()
    @pluginActive = true

    @subscriptions.add @minimap.onDidActivate @activateBinding
    @subscriptions.add @minimap.onDidDeactivate @destroyBindings

  deactivatePlugin: ->
    return unless @pluginActive

    @pluginActive = false
    @subscriptions.dispose()
    @destroyBindings()

  activateBinding: =>
    @createBindings() if atom.project.getRepo()?

    @subscriptions.add @asDisposable atom.project.on 'path-changed', =>
      if atom.project.getRepo()?
        @createBindings()
      else
        @destroyBindings()

  createBindings: =>
    @minimap.eachMinimapView ({view}) =>
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

  asDisposable: (subscription) -> new Disposable -> subscription.off()

module.exports = new MinimapGitDiff
