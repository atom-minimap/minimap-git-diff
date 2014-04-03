{$} = require 'atom'
{Subscriber, Emitter} = require 'emissary'

module.exports =
class MinimapGitDiffBinding
  Subscriber.includeInto(this)
  Emitter.includeInto(this)

  active: false

  constructor: (@editorView, @gitDiffPackage, @minimapPackage) ->
    {@editor} = @editorView
    @minimap = require(@minimapPackage.path)
    @gitDiff = require(@gitDiffPackage.path)

    @subscribe @editorView, 'editor:path-changed', @subscribeToBuffer
    @subscribe @editorView, 'editor:contents-modified', @renderDiffs
    @subscribe atom.project.getRepo(), 'statuses-changed', =>
      @scheduleUpdate()
    @subscribe atom.project.getRepo(), 'status-changed', (path) =>
      @scheduleUpdate()

    @subscribeToBuffer()

    if @minimap.active
      @subscribeToMinimapView()
    else
      @subscribe @minimap, 'activated', @subscribeToMinimapView

  scheduleUpdate: ->
    setImmediate(@updateDiffs)

  updateDiffs: =>
    return unless @buffer?
    return unless @minimap.active

    @renderDiffs()

  renderDiffs: =>
    return unless @editorView.getPane()?
    return unless @editorView is @editorView.getPane().activeView

    minimapView = @minimap.minimapForEditorView(@editorView)
    lines = minimapView.find('.lines')[0].childNodes[0].childNodes

    @removeDiffs()

    diffs = @getDiffs()
    displayBuffer = @editor.displayBuffer

    for {newLines, oldLines, newStart, oldStart} in diffs
      if oldLines is 0 and newLines > 0
        for row in [newStart...newStart + newLines]
          start = displayBuffer.screenRowForBufferRow(row)
          end = displayBuffer.lastScreenRowForBufferRow(row)
          @decorateLines(lines, start, end, 'added')

      else if newLines is 0 and oldLines > 0
        start = displayBuffer.screenRowForBufferRow(newStart)
        end = displayBuffer.lastScreenRowForBufferRow(newStart)
        @decorateLines(lines, start, end, 'removed')

      else
        for row in [newStart...newStart + newLines]
          start = displayBuffer.screenRowForBufferRow(row)
          end = displayBuffer.lastScreenRowForBufferRow(row)
          @decorateLines(lines, start, end, 'modified')

  decorateLines: (lines, start, end, status) ->
    for row in [start..end]
      lines[row - 1].className += " git-line-#{status}"

  removeDiffs: ->
    return unless @editorView.getPane()?
    minimapView = @minimap.minimapForEditorView(@editorView)

    minimapView.find('[class*="git-line-"]')
    .removeClass('git-line-added git-line-removed git-line-modified')

  destroy: ->
    @unsubscribe()

  getPath: -> @buffer.getPath()

  getRepo: -> atom.project.getRepo()

  getDiffs: ->
    @getRepo()?.getLineDiffs(@getPath(), @editorView.getText())

  unsubscribeFromBuffer: ->
    if @buffer?
      @removeDiffs()
      @buffer = null

  subscribeToBuffer: =>
    @unsubscribeFromBuffer()

    if @buffer = @editor.getBuffer()
      @buffer.on 'contents-modified', @updateDiffs

  subscribeToMinimapView: =>
    return unless @editorView.getPane()?
    minimapView = @minimap.minimapForEditorView(@editorView)

    @subscribe minimapView.miniEditorView, 'minimap:updated', =>
      @updateDiffs()
