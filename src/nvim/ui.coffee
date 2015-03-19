# ui.coffee
# handle redraw events from neovim
# Copyright (c) 2015 Lu Wang <coolwanglu@gmail.com>

shell = require 'shell'
EventEmitter = require('events').EventEmitter
remote = require 'remote'
config = require './config'
{keystrokeForKeyboardEvent} = require './key_handler'

MOUSE_BUTTON_NAME = [ 'Left', 'Middle', 'Right' ]

# neovim/vim scrolls by 3 rows for every ScrollWheel{Up,Down}
# and 6 colums per ScrollWheel{Left,Right} (:h scroll-mouse-wheel)
ROWS_PER_SCROLL = 3
COLS_PER_SCROLL = 6

get_vim_button_name = (button, e) ->
  kn = '<'
  kn += 'S-' if e.shiftKey
  kn += 'C-' if e.ctrlKey
  kn += 'A-' if e.altKey
  kn += button + '>'
  kn

# visualize neovim's abstract-ui
class UI extends EventEmitter
  constructor: (row, col)->
    super()
    @init_DOM()
    @init_state()
    @init_font()
    @init_cursor()
    @init_event_handlers()
    @nv_resize col, row

  init_DOM: ->
    @canvas = document.getElementById 'nvas-canvas'
    @ctx = @canvas.getContext '2d'
    @cursor = document.getElementById 'nvas-cursor'
    @font_test_node = document.getElementById 'nvas-font-test'
    @devicePixelRatio = window.devicePixelRatio ? 1

  init_state: ->
    # @total_row/col, @scroll_top/bottom/left/right will be set in @nv_resize
    @cursor_col = 0
    @cursor_row = 0

    @mouse_enabled = true
    @mouse_button_pressed = null
    @wheelDeltaY = 0
    @wheelDeltaX = 0

    @fg_color = '#fff'
    @bg_color = '#000'
    @sp_color = '#f00'
    @attrs = {}

    @resize_timer = null

  init_font: ->
    @font = config.font
    @font_test_node.style.font = @font
    @font_test_node.innerHTML = 'm'

    @char_width = Math.max 1, @font_test_node.clientWidth
    @char_height = Math.max 1, @font_test_node.clientHeight
    @canvas_char_width = @char_width * @devicePixelRatio
    @canvas_char_height = @char_height * @devicePixelRatio

  init_cursor: ->
    @cursor.style.width = @char_width + 'px'
    @cursor.style.height = @char_height + 'px'

    if config.blink_cursor
      @cursor.classList.add('blink')
    else
      @cursor.classList.remove('blink')

  init_event_handlers: ->
    document.addEventListener 'keydown', (e) =>
      keystroke = keystrokeForKeyboardEvent(e)
      @emit 'input', keystroke if keystroke

    document.addEventListener 'mousedown', (e) =>
      return if not @mouse_enabled
      e.preventDefault()
      @mouse_button_pressed = MOUSE_BUTTON_NAME[e.button]
      @emit 'input',
        get_vim_button_name(@mouse_button_pressed + 'Mouse', e) \
          + '<' + Math.floor(e.clientX / @char_width) \
          + ',' + Math.floor(e.clientY / @char_height) \
          + '>'

    document.addEventListener 'mouseup', (e) =>
      return if not @mouse_enabled
      e.preventDefault()
      @mouse_button_pressed = null

    document.addEventListener 'mousemove', (e) =>
      return if not @mouse_enabled or not @mouse_button_pressed
      e.preventDefault()
      @emit 'input',
        get_vim_button_name(@mouse_button_pressed + 'Drag', e) \
          + '<' + Math.floor(e.clientX / @char_width) \
          + ',' + Math.floor(e.clientY / @char_height) \
          + '>'

    window.addEventListener 'resize', (e) =>
      if not @resize_timer
        @resize_timer = setTimeout =>
          @resize_timer = null
          col = Math.floor window.innerWidth / @char_width
          row = Math.floor window.innerHeight / @char_height

          if col != @total_col or row != @total_row
            @emit 'resize', col, row

        , 250

    @canvas.addEventListener 'wheel', (e) =>
      return if not @mouse_enabled
      e.preventDefault()

      # Total distance scrolled in pixels
      @wheelDeltaX += e.wheelDeltaX
      @wheelDeltaY += e.wheelDeltaY

      # Get the number of row/column scroll events to send. Reporting a single
      # row scrolled will actually scroll by ROWS_PER_SCROLL, so divide accordingly
      cols = Math.round(@wheelDeltaX / @char_width / COLS_PER_SCROLL)
      rows = Math.round(@wheelDeltaY / @char_height / ROWS_PER_SCROLL)

      if rows == 0 && cols == 0
        return

      if cols != 0
        @wheelDeltaX = 0
        direction = if cols > 0 then 'Left' else 'Right'
      if rows != 0
        @wheelDeltaY = 0
        direction = if rows > 0 then 'Up' else 'Down'

      @emit 'input', get_vim_button_name('ScrollWheel' + direction, e) \
        + '<' + cols + ',' + rows + '>'

  get_color_string: (rgb) ->
    bgr = []
    for i in [0...3]
      bgr.push rgb & 0xff
      rgb = rgb >> 8
    'rgb('+bgr[2]+','+bgr[1]+','+bgr[0]+')'

  clear_block: (col, row, width, height) ->
    @fill_block(col, row, width, height, @get_cur_bg_color())

  fill_block: (col, row, width, height, color) ->
    @ctx.fillStyle = color
    @ctx.fillRect \
      col * @canvas_char_width, \
      row * @canvas_char_height, \
      width * @canvas_char_width, \
      height * @canvas_char_height

  clear_all: ->
    document.body.style.background = @get_cur_bg_color()
    @ctx.fillStyle = @get_cur_bg_color()
    @ctx.fillRect 0, 0, @canvas.width, @canvas.height

  # the font set to canvas might need to be scaled
  # when devicePixelRatio != 1
  get_canvas_font: ->
    font = @font
    if @attrs?.bold then font = 'bold ' + font
    if @attrs?.italic then font = 'italic ' + font
    try
      l = @font.split /([\d]+)(?=in|[cem]m|ex|p[ctx])/
      l[1] = parseFloat(l[1]) * @devicePixelRatio
      l.join ''
    catch
      @font

  get_cur_fg_color: -> if @attrs.reverse then @attrs.bg_color ? @bg_color else @attrs.fg_color ? @fg_color
  get_cur_bg_color: -> if @attrs.reverse then @attrs.fg_color ? @fg_color else @attrs.bg_color ? @bg_color

  update_cursor: ->
    @cursor.style.top = (@cursor_row * @char_height) + 'px'
    @cursor.style.left = (@cursor_col * @char_width) + 'px'


  #####################
  # neovim redraw events
  # in alphabetical order
  handle_redraw: (events) ->
    for e in events
      try
        handler = @['nv_'+e[0]]
        if handler?
          # optimize for put, we group the chars together
          if e[0].toString() == 'put'
            handler.call @, e[1..]
          else
            for args in e[1..]
              handler.apply @, args
        else console.log 'Redraw event not handled: ' + e.toString()
      catch ex
        console.log 'Error when processing event!'
        console.log e.toString()
        console.log ex.stack || ex
    @update_cursor()

  nv_bell: -> shell.beep()

  nv_busy_start: -> @cursor.style.display = 'none'
  nv_busy_stop: -> @cursor.style.display = 'block'

  nv_clear: -> @clear_all()

  nv_cursor_goto: (row, col) ->
    @cursor_row = row
    @cursor_col = col

  nv_eol_clear: -> @clear_block @cursor_col, @cursor_row, @total_col - @cursor_col + 1, 1

  nv_highlight_set: (attrs) ->
    @attrs = {}
    @attrs.bold = attrs.bold
    @attrs.italic = attrs.italic
    @attrs.reverse = attrs.reverse
    @attrs.underline = attrs.underline
    @attrs.undercurl = attrs.undercurl
    if attrs.foreground? then @attrs.fg_color = @get_color_string(attrs.foreground)
    if attrs.background? then @attrs.bg_color = @get_color_string(attrs.background)

  nv_insert_mode: -> document.body.className = 'insert-mode'

  nv_mouse_off: -> @mouse_enabled = false
  nv_mouse_on: -> @mouse_enabled = true

  nv_normal_mode: -> document.body.className = 'normal-mode'

  nv_put: (chars) ->
    return if chars.length == 0

    # paint background
    @clear_block @cursor_col, @cursor_row, chars.length, 1

    # paint string
    @ctx.font = @get_canvas_font()
    @ctx.textBaseline = 'bottom'

    x = @cursor_col * @canvas_char_width
    y = (@cursor_row + 1) * @canvas_char_height
    w = chars.length * @canvas_char_width

    @ctx.fillStyle = @get_cur_fg_color()

    # Paint each char individually in order to ensure they
    # line up as expected
    char_x = x
    for char in chars
      @ctx.fillText char, char_x, y
      char_x += @canvas_char_width

    if @attrs.underline
      @ctx.strokeStyle = @get_cur_fg_color()
      @ctx.lineWidth = @devicePixelRatio
      @ctx.beginPath()
      @ctx.moveTo x, y - @devicePixelRatio / 2
      @ctx.lineTo x + w, y - @devicePixelRatio / 2
      @ctx.stroke()

    if @attrs.undercurl
      offs = [1.5, 0.8, 0.5, 0.8, 1.5, 2.2, 2.5, 2.2]
      # should use sp_color, but neovim does not support it
      @ctx.strokeStyle = @get_cur_fg_color()
      @ctx.lineWidth = @devicePixelRatio
      @ctx.beginPath()
      @ctx.moveTo x, y - @devicePixelRatio * offs[(x / @devicePixelRatio) % 8]
      for xx in [x+@devicePixelRatio..x+w] by @devicePixelRatio
        @ctx.lineTo xx, y - @devicePixelRatio * offs[(xx / @devicePixelRatio) % 8]
      @ctx.stroke()

    @cursor_col += chars.length

  nv_resize: (col, row) ->
    @total_col = col
    @total_row = row

    @scroll_top = 0
    @scroll_bottom = @total_row - 1
    @scroll_left = 0
    @scroll_right = @total_col - 1

    @canvas.width = @canvas_char_width * col
    @canvas.height = @canvas_char_height * row

    @canvas.style.width = @char_width * col + "px"
    @canvas.style.height = @char_height * row + "px"

    window_col = Math.floor window.innerWidth / @char_width
    window_row = Math.floor window.innerHeight / @char_height

    if col != window_col || row != window_row
      window.resizeTo \
        @char_width * col + window.outerWidth - window.innerWidth, \
        @char_height * row + window.outerHeight - window.innerHeight

  # adapted from neovim/python-client
  nv_scroll: (row_count) ->
    src_top = dst_top = @scroll_top
    src_bottom = dst_bottom = @scroll_bottom

    if row_count > 0 # move up
      src_top += row_count
      dst_bottom -= row_count
      clr_top = dst_bottom + 1
      clr_bottom = src_bottom
    else
      src_bottom += row_count
      dst_top -= row_count
      clr_top = src_top
      clr_bottom = dst_top - 1

    img = @ctx.getImageData \
      @scroll_left * @canvas_char_width, \
      src_top * @canvas_char_height, \
      (@scroll_right - @scroll_left + 1) * @canvas_char_width, \
      (src_bottom - src_top + 1) * @canvas_char_height
    @ctx.putImageData img, \
      @scroll_left * @canvas_char_width, \
      dst_top * @canvas_char_height

    @fill_block \
      @scroll_left, \
      clr_top, \
      @scroll_right - @scroll_left + 1, \
      clr_bottom - clr_top + 1, \
      @bg_color

  nv_set_icon: (icon) -> remote.getCurrentWindow().setRepresentedFilename? icon.toString()

  nv_set_title: (title) ->
    title = title.toString()
    match = /(.*) - VIM$/.exec(title)
    document.title = if match? then match[1] + ' - Neovim.AS' else title

  nv_set_scroll_region: (top, bottom, left, right) ->
    @scroll_top = top
    @scroll_bottom = bottom
    @scroll_left = left
    @scroll_right = right

  nv_update_fg: (rgb) -> @cursor.style.borderColor = @fg_color = if rgb == -1 then config.fg_color else @get_color_string(rgb)
  nv_update_bg: (rgb) -> @bg_color = if rgb == -1 then config.bg_color else @get_color_string(rgb)

module.exports = UI
