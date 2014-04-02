MinimapGitDiffBinding = require './minimap-git-diff-binding'

module.exports =
  bindings: {}
  activate: (state) ->
    gitDiff = atom.packages.getLoadedPackage('git-diff')
    minimap = atom.packages.getLoadedPackage('minimap')

    return @deactivate() unless gitDiff? and minimap?

    atom.workspaceView.eachEditorView (editor) =>
      id = editor.getModel().id
      @bindings[id] = new MinimapGitDiffBinding editor, gitDiff, minimap

  deactivate: ->
    binding.destroy() for id,binding of @bindings
    @bindings = {}
