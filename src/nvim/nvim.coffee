# nvim.coffee
# communicate with neovim process
# Copyright (c) 2015 Lu Wang <coolwanglu@gmail.com>

child_process = require 'child_process'
Session = require 'msgpack5rpc'
remote = require 'remote'
UI = require './ui'

class NVim
  constructor: ->
    @ui = new UI()

    # Atom Shell apps are run as 'Atom <path> <args>'
    # might need a better way to locate the arguments
    nvim_args = ['--embed'].concat remote.process.argv[2..]

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

    @session.request 'ui_attach', [80, 40, true], =>
      @ui.on 'input', (e) =>
        @session.request 'vim_input', [e], =>


module.exports = NVim
