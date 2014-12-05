{$} = require 'atom'
{CompositeDisposable} = require 'event-kit'

module.exports =
class MinimapGitDiffBinding

  active: false

  constructor: (@editorView, @gitDiff, @minimapView) ->
    @editor = @editorView.getModel()
    @decorations = {}
    @markers = null
    @subscriptions = new CompositeDisposable

  activate: ->
    @subscriptions.add @editor.onDidChangePath @subscribeToBuffer
    if @editor.onDidChangeScreenLines?
      @subscriptions.add @editor.onDidChangeScreenLines @updateDiffs
    else
      @subscriptions.add @editor.onDidChange @updateDiffs

    repository = @getRepo()

    @subscriptions.add repository.onDidChangeStatuses @scheduleUpdate
    @subscriptions.add repository.onDidChangeStatus @scheduleUpdate

    @subscribeToBuffer()

    @updateDiffs()

  deactivate: ->
    @removeDecorations()
    @subscriptions.dispose()
    @diffs = null

  scheduleUpdate: => setImmediate(@updateDiffs)

  updateDiffs: =>
    @removeDecorations()
    if @getPath() and @diffs = @getDiffs()
      @addDecorations(@diffs)

  addDecorations: (diffs) ->
    for {oldStart, newStart, oldLines, newLines} in diffs
      startRow = newStart - 1
      endRow = newStart + newLines - 2
      if oldLines is 0 and newLines > 0
        @markRange(startRow, endRow, '.minimap .git-line-added')
      else if newLines is 0 and oldLines > 0
        @markRange(startRow, startRow, '.minimap .git-line-removed')
      else
        @markRange(startRow, endRow, '.minimap .git-line-modified')

  removeDecorations: ->
    return unless @markers?
    marker.destroy() for marker in @markers
    @markers = null

  markRange: (startRow, endRow, scope) ->
    return if @editor.getBuffer().isDestroyed()
    marker = @editor.markBufferRange([[startRow, 0], [endRow, Infinity]], invalidate: 'never')
    @minimapView.decorateMarker(marker, type: 'line', scope: scope)
    @markers ?= []
    @markers.push(marker)

  destroy: ->
    @removeDecorations()
    @deactivate()

  getPath: -> @buffer?.getPath()

  getRepositories: -> atom.project?.getRepositories()

  getRepo: -> @getRepositories()?[0]

  getDiffs: ->
    @getRepo()?.getLineDiffs(@getPath(), @buffer.getText())

  unsubscribeFromBuffer: ->
    if @buffer?
      @bufferSubscription.dispose()
      @removeDecorations()
      @buffer = null

  subscribeToBuffer: =>
    @unsubscribeFromBuffer()

    if @buffer = @editor.getBuffer()
      @bufferSubscription = @buffer.onDidStopChanging @updateDiffs
