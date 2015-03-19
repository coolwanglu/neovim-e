# nvim.coffee
# communicate with neovim process
# Copyright (c) 2015 Lu Wang <coolwanglu@gmail.com>

child_process = require 'child_process'
Session = require 'msgpack5rpc'
remote = require 'remote'
UI = require './ui'
config = require './config'
fs = require 'fs'


# Returns a function, that, as long as it continues to be invoked, will not
# be triggered. The function will be called after it stops being called for
# N milliseconds. If `immediate` is passed, trigger the function on the
# leading edge, instead of the trailing.
debounce = (func, wait, immediate) ->
  timeout = undefined
  ->
    context = this
    args = arguments
    later = ->
      timeout = null
      func.apply context, args  unless immediate
      return
    callNow = immediate and not timeout
    clearTimeout timeout
    timeout = setTimeout(later, wait)
    func.apply context, args  if callNow
    return

class NVim
  constructor: ->
    @ui = new UI(config.row, config.col)

    # Atom Shell apps are run as 'Atom <path> <args>'
    # might need a better way to locate the arguments
    nvim_args = ['--embed'].concat remote.process.argv[3..]

    @nvim_process = child_process.spawn 'nvim', nvim_args, stdio: ['pipe', 'pipe', process.stderr]
    console.log 'child process spawned: ' + @nvim_process.pid

    @nvim_process.on 'close', =>
      console.log 'child process closed'
      @session.detach()
      remote.require('app').quit()

    @session = new Session
    @session.attach @nvim_process.stdin, @nvim_process.stdout
    @session.on 'notification', (method, args) =>
      @ui.handle_redraw args if method == 'redraw'

    @session.request 'ui_attach', [config.col, config.row, true], =>
      @ui.on 'input', (e) =>
        @session.request 'vim_input', [e], ->
      @ui.on 'resize', (col, row) =>
        @session.request 'ui_try_resize', [col, row], ->

    ui = @ui
    # Watch the directory because vim replaces a file.
    # We could also watch both the file and the directory and
    # rely on the debounce to handle it.
    fs.watch config.user_path, persistent: true, config_handler(ui)

config_handler = (ui) ->
  debounce (event) ->
    if config.reload()
      console.log JSON.stringify(config)
      ui.init_font()
      ui.init_cursor()
      ui.nv_resize config.col, config.row
    else
      console.log "samesies"
  , 250



module.exports = NVim
