# ui.coffee
# handle redraw events from neovim
# Copyright (c) 2015 Lu Wang <coolwanglu@gmail.com>

shell = require 'shell'
EventEmitter = require('events').EventEmitter

# keyIdentifier -> vim key name
KEYMAP =
  8 : 'BS'
  9 : 'Tab'
  13 : 'Enter'
  27 : 'Esc'
  32 : 'Space'
  33 : 'PageUp'
  34 : 'PageDown'
  35 : 'End'
  36 : 'Home'
  37 : 'Left'
  38 : 'Up'
  39 : 'Right'
  40 : 'Down'
  45 : 'Insert'
  46 : 'Del'
  112 : 'F1'
  113 : 'F2'
  114 : 'F3'
  115 : 'F4'
  116 : 'F5'
  117 : 'F6'
  118 : 'F7'
  119 : 'F8'
  120 : 'F9'
  121 : 'F10'
  122 : 'F11'
  123 : 'F12'
  127 : 'Del' # mac?

KEYS_TO_INTERCEPT_UPON_KEYDOWN = {}
KEYS_TO_INTERCEPT_UPON_KEYDOWN[k] = 1 for k in [
  'Esc', 'Tab', 'BS'
  'Up', 'Down', 'Left', 'Right'
  'Del'
  'Home', 'End'
  'PageUp', 'PageDown'
]

MOUSE_BUTTON_NAME = [ 'Left', 'Middle', 'Right' ]

# TODO handle shiftKey if necessary
get_vim_key_name = (key, e) ->
  if not (e.ctrlKey or e.atlKey)
    if e.charCode and key.length == 1
      if key == '<' then '<lt>' else key
    else '<' + key + '>'
  else
    kn = '<'
    kn += 'C-' if e.ctrlKey
    kn += 'A-' if e.altKey
    if e.ctrlKey and 1 <= e.charCode and e.charCode <= 26
      key = String.fromCharCode(96 + e.charCode)
    kn += key + '>'
    kn

get_vim_button_name = (button, e) ->
  kn = '<'
  kn += 'S-' if e.shiftKey
  kn += 'C-' if e.ctrlKey
  kn += 'A-' if e.altKey
  kn += button + '>'
  kn

# visualize neovim's abstract-ui
class UI extends EventEmitter
  constructor: ->
    super()
    @init_DOM()
    @init_state()
    @init_font()
    @init_input_handlers()

  init_DOM: ->
    @canvas = document.getElementById 'nvas-canvas'
    @ctx = @canvas.getContext '2d'
    @cursor = document.getElementById 'nvas-cursor'
    @font_test_node = document.getElementById 'nvas-font-test'
    @devicePixelRatio = window.devicePixelRatio ? 1

  init_state: ->
    @total_col = 80
    @total_row = 40

    @cursor_col = 0
    @cursor_row = 0

    @scroll_top = 0
    @scroll_bottom = 0
    @scroll_left = 0
    @scroll_right = 0

    @mouse_enabled = true
    @mouse_button_pressed = null

    @fg_color = '#fff'
    @bg_color = '#000'
    @sp_color = '#f00'
    @attrs = {}

  init_font: ->
    @font = '12px monospace'
    @font_test_node.style.font = @font
    @font_test_node.innerHTML = 'm'

    @char_width = Math.max 1, @font_test_node.clientWidth
    @char_height = Math.max 1, @font_test_node.clientHeight
    @canvas_char_width = @char_width * @devicePixelRatio
    @canvas_char_height = @char_height * @devicePixelRatio

    @cursor.style.width = @char_width + 'px'
    @cursor.style.height = @char_height + 'px'

  init_input_handlers: ->
    document.addEventListener 'keypress', (e) =>
      key = switch e.charCode
        when 13 then KEYMAP[e.charCode]
        else String.fromCharCode(e.charCode)
      e.preventDefault()
      @emit 'input', get_vim_key_name(key, e)

    document.addEventListener 'keydown', (e) =>
      key = KEYMAP[e.keyCode]
      if key of KEYS_TO_INTERCEPT_UPON_KEYDOWN
        e.preventDefault()
        @emit 'input', get_vim_key_name(key, e)

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

  get_color_string: (rgb) ->
    bgr = []
    for i in [0...3]
      bgr.push rgb & 0xff
      rgb = rgb >> 8
    'rgb('+bgr[2]+','+bgr[1]+','+bgr[0]+')'

  clear_block: (col, row, width, height) ->
    @ctx.fillStyle = @get_cur_bg_color()
    @ctx.fillRect \
      col * @canvas_char_width, \
      row * @canvas_char_height, \
      width * @canvas_char_width, \
      height * @canvas_char_height

  clear_all: ->
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
        # optimize for put, we group the chars together
        if handler?
          if e[0] == 'put'
            handler.call @, (i[0] for i in e.slice(1)).join ''
          else
            for args in e[1..]
              handler.apply @, args
        else console.log 'Redraw event not handled: ' + JSON.stringify e
      catch ex
        console.log 'Error when processing event!'
        console.log JSON.stringify e
        console.log ex.stack || ex
    @update_cursor()

  nv_bell: -> shell.beep()

  nv_clear: -> @clear_all()

  nv_cursor_goto: (row, col) ->
    @cursor_row = row
    @cursor_col = col
  nv_cursor_off: -> @cursor.style.display = 'none'
  nv_cursor_on: -> @cursor.style.display = 'block'

  nv_eol_clear: -> @clear_block @cursor_col, @cursor_row, @total_col - @cursor_col + 1, 1

  nv_highlight_set: (attrs) ->
    @attrs = {}
    if attrs.bold? then @attrs.bold = attrs.bold
    if attrs.italic? then @attrs.italic = attrs.italic
    if attrs.reverse? then @attrs.reverse = attrs.reverse
    if attrs.foreground? then @attrs.fg_color = @get_color_string(attrs.foreground)
    if attrs.background? then @attrs.bg_color = @get_color_string(attrs.background)

  nv_insert_mode: -> document.body.className = 'insert-mode'

  nv_mouse_off: -> @mouse_enabled = false
  nv_mouse_on: -> @mouse_enabled = true

  nv_normal_mode: -> document.body.className = 'normal-mode'

  nv_put: (str) ->
    return if str.length == 0
    # paint background
    @clear_block @cursor_col, @cursor_row, str.length, 1

    # paint string
    @ctx.font = @get_canvas_font()
    @ctx.textBaseline = 'bottom'

    @ctx.fillStyle = @get_cur_fg_color()
    @ctx.fillText str, \
      @cursor_col * @canvas_char_width, \
      (@cursor_row + 1) * @canvas_char_height, \
      str.length * @canvas_char_width

    @cursor_col += str.length

  nv_resize: (col, row) ->
    @total_col = col
    @total_row = row
    @canvas.width = @canvas_char_width * col
    @canvas.height = @canvas_char_height * row
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
      row_count = -row_count - 32 if row_count > -32 # walkaround for msgpack5 bug #14
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
    @clear_block \
      @scroll_left, \
      clr_top, \
      @scroll_right - @scroll_left + 1, \
      clr_bottom - clr_top + 1

  nv_set_scroll_region: (top, bottom, left, right) ->
    @scroll_top = top
    @scroll_bottom = bottom
    @scroll_left = left
    @scroll_right = right

  nv_update_fg: (rgb) -> @cursor.style.borderColor = @fg_color = @get_color_string(rgb)
  nv_update_bg: (rgb) -> @bg_color = @get_color_string(rgb)

module.exports = UI
