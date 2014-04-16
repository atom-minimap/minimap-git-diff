MinimapGitDiffBinding = require './minimap-git-diff-binding'

module.exports =
  bindings: {}
  pluginActive: false
  isActive: -> @pluginActive
  activate: (state) ->
    gitDiff = atom.packages.getLoadedPackage('git-diff')
    minimap = atom.packages.getLoadedPackage('minimap')

    return @deactivate() unless gitDiff? and minimap?
    return @deactivate() unless atom.project.getRepo()?

    atom.workspaceView.eachEditorView (editor) =>
      id = editor.getModel().id
      binding = new MinimapGitDiffBinding editor, gitDiff, minimap
      @bindings[id] = binding

      binding.activate() if @pluginActive

    minimapModule = require minimap.path
    minimapModule.registerPlugin 'git-diff', this

  deactivate: ->
    binding.destroy() for id,binding of @bindings
    @bindings = {}

  activatePlugin: ->
    return if @pluginActive

    @pluginActive = true
    binding.activate() for id,binding of @bindings

  deactivatePlugin: ->
    return unless @pluginActive

    @pluginActive = false
    binding.deactivate() for id,binding of @bindings
