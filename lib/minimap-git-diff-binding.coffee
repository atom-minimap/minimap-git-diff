{$} = require 'atom'
{Subscriber, Emitter} = require 'emissary'

module.exports =
class MinimapGitDiffBinding
  Subscriber.includeInto(this)
  Emitter.includeInto(this)

  active: false

  constructor: (@editorView, @gitDiffPackage, @minimapPackage) ->
    @minimap = require(@minimapPackage.path)
    @gitDiff = require(@gitDiffPackage.path)

    # @subscribe @editorView, 'editor:display-updated', @renderDiffs
    # @subscribe atom.project.getRepo(), 'statuses-changed', =>
    #   @diffs = {}
    #   @scheduleUpdate()
    # @subscribe atom.project.getRepo(), 'status-changed', (path) =>
    #   delete @diffs[path]
    #   @scheduleUpdate() if path is @editor.getPath()
