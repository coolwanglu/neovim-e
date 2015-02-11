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
  'Esc'
  'Tab'
  'BS'
  'Up', 'Down', 'Left', 'Right'
  'Home', 'End'
  'Del'
  'PageUp', 'PageDown'
]

get_vim_key_name = (key, e) ->
  if not (e.ctrlKey or e.atlKey or e.shiftKey)
    return (if e.keyCode of KEYMAP then '<' + key + '>' else key)
  kn = '<'
  kn += 'S-' if e.shiftKey
  kn += 'C-' if e.ctrlKey
  kn += 'A-' if e.altKey
  if e.ctrlKey and 1 <= e.charCode and e.charCode <= 26
    key = String.fromCharCode(96 + e.charCode)
  kn += key + '>'
  kn

# visualize neovim's abstract-ui
class UI extends EventEmitter
  constructor: ->
    super()

    @canvas = document.getElementById('nvas-canvas')
    @ctx = @canvas.getContext('2d')
    @devicePixelRatio = window.devicePixelRatio ? 1

    @font = '12px monospace'
    @font_test_node = document.getElementById('nvas-font-test')

    @char_height = 1
    @char_width = 1

    @total_col = 80
    @total_row = 40
    @cursor_col = 0
    @cursor_row = 0

    @fg_color = '#fff'
    @bg_color = '#000'
    @sp_color = '#f00'
    @attrs = {}

    @init_font()
    @init_key_handlers()

  init_font: ->
    @font_test_node.style.font = @font
    @font_test_node.innerHTML = 'm'
    @char_height = Math.max 1, @font_test_node.clientHeight * @devicePixelRatio
    @char_width = Math.max 1, @font_test_node.clientWidth * @devicePixelRatio
    console.log 'char width: ', @char_width
    console.log 'char height: ', @char_height

  init_key_handlers: ->
    document.addEventListener 'keypress', (e) =>
      key = switch e.charCode
        when 13 then KEYMAP[e.charCode]
        else String.fromCharCode(e.charCode)
      e.preventDefault()
      @emit 'key', get_vim_key_name(key, e)

    document.addEventListener 'keydown', (e) =>
      key = KEYMAP[e.keyCode]
      if key of KEYS_TO_INTERCEPT_UPON_KEYDOWN
        e.preventDefault()
        console.log 'name' + get_vim_key_name(key, e)
        @emit 'key', get_vim_key_name(key, e)

  get_color_string: (rgb) ->
    bgr = []
    for i in [0...3]
      bgr.push rgb & 0xff
      rgb = rgb >> 8
    'rgb('+bgr[2]+','+bgr[1]+','+bgr[0]+')'

  clear_block: (col, row, width, height) ->
    @ctx.fillStyle = @get_cur_bg_color()
    @ctx.fillRect col * @char_width, row * @char_height, width * @char_width, height * @char_height

  clear_all: ->
    @ctx.fillStyle = @get_cur_bg_color()
    @ctx.fillRect 0, 0, @canvas.width, @canvas.height

  # the font set to canvas might need to be scaled when devicePixelRatio != 1
  get_canvas_font: ->
    font = @font
    if @attrs?.bold then font = 'bold ' + @font
    try
      l = @font.split /([\d]+)(?=in|[cem]m|ex|p[ctx])/
      l[1] = parseFloat(l[1]) * @devicePixelRatio
      l.join ''
    catch
      @font

  get_cur_fg_color: -> @attrs.fg_color ? @fg_color
  get_cur_bg_color: -> @attrs.bg_color ? @bg_color

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
        else console.log 'Redraw event not handled: ', e
      catch ex
        console.log 'Error when processing event!'
        console.log JSON.stringify e
        console.log e.stack || e

  nv_bell: -> shell.beep()

  nv_clear: -> @clear_all()

  nv_cursor_goto: (row, col) ->
    @cursor_row = row
    @cursor_col = col

  nv_cursor_off: -> #todo

  nv_cursor_on: -> #todo

  nv_eol_clear: ->
    @clear_block @cursor_col, @cursor_row, @total_row - @cursor_col + 1, 1

  nv_highlight_set: (attrs) ->
    @attrs = {}
    if attrs.bold? then @attrs.bold = attrs.bold
    if attrs.foreground? then @attrs.fg_color = @get_color_string(attrs.foreground)
    if attrs.background? then @attrs.bg_color = @get_color_string(attrs.background)

  nv_mouse_off: -> #todo

  nv_mouse_on: -> #todo

  nv_normal_mode: -> #todo

  nv_put: (str) ->
    return if str.length == 0
    # paint background
    @clear_block @cursor_col, @cursor_row, str.length, 1

    # paint string
    @ctx.font = @get_canvas_font()
    @ctx.textBaseline = 'bottom'

    @ctx.fillStyle = @get_cur_fg_color()
    @ctx.fillText str, @cursor_col * @char_width, (@cursor_row + 1) * @char_height, str.length * @char_width

    @cursor_col += str.length

  nv_resize: (col, row) ->
    @total_col = col
    @total_row = row
    w = @canvas.width = @char_width * col
    h = @canvas.height = @char_height * row
    window.resizeTo w / @devicePixelRatio, h / @devicePixelRatio

  nv_set_scroll_region: (top, bottom, left, right) -> #todo

  nv_update_fg: (rgb) -> @fg_color = @get_color_string(rgb)

  nv_update_bg: (rgb) -> @canvas.style.backgroundColor = @bg_color = @get_color_string(rgb)

module.exports = UI
