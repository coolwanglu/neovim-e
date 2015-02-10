async = require 'async'
child_process = require 'child_process'
msgpack = require('msgpack5')()
remote = require 'remote'
UI = require './ui'

RPC =
  REQUEST: 0
  RESPONSE: 1
  NOTIFY: 2
  MAX_SEQ: 2**32-1

# connect to an neovim process
class NVim
  constructor: ->
    @cmd_seq = 0
    @callbacks = {}
    @ui = new UI()

    # Atom Shell apps are run as 'Atom <path> <args>'
    # might need a better way to locate the arguments
    nvim_args = ['--embed'].concat remote.process.argv[2..]
    console.log nvim_args

    @nvim_process = child_process.spawn 'nvim', nvim_args, stdio: ['pipe', 'pipe', process.stderr]
    console.log 'child process spawned: ', @nvim_process.pid

    @nvim_process.on 'close', =>
      console.log 'child process closed'
      remote.require('app').quit()

    @decoder = msgpack.decoder header: false
    @decoder.on 'data', (data) => @on_data(data)
    @nvim_process.stdout.pipe @decoder

    async.series [
      (_) => @get_vim_api(_),
      (_) => @ui_attach(_)
    ]

    document.addEventListener 'keypress', (e) =>
      e.preventDefault()
      @send 'vim_input', [String.fromCharCode e.which]

    document.addEventListener 'keydown', (e) =>
      if not e.altKey
        translation = @translateCode(e.which, e.shiftKey, e.ctrlKey)
        if translation != ""
          console.log 'down:'+translation+'*'
          false
      else
        true

   translateCode: (code, shift, control) ->
    if control && code>=65 && code<=90
      String.fromCharCode(code-64)
    else if code>=8 && code<=10 || code==13 || code==27
      String.fromCharCode(code)
    else if code==37
      String.fromCharCode(27)+'[D'
    else if code==38
      String.fromCharCode(27)+'[A'
    else if code==39
      String.fromCharCode(27)+'[C'
    else if code==40
      String.fromCharCode(27)+'[B'
    else
      ""


  on_data: (data) ->
    switch data[0]
      when RPC.RESPONSE
        msg_id = data[1]
        if @callbacks[msg_id]?
          callback = @callbacks[msg_id]
          delete @callbacks[msg_id]

        if data[3]? and callback? #success
          callback data[3]
        else if data?[2] #error
          console.log 'child ERR: ', @clone_and_decode data[2]

      when RPC.NOTIFY
        method = @clone_and_decode data[1]
        args = @clone_and_decode data[2]
        if method == 'redraw' then @ui.handle_redraw args
        else console.log 'child NOTIFY: ', method, args

      else console.log 'unknown msgpack message: ', JSON.stringify data

  send: (cmd, args, response_callback) ->
    if response_callback? then @callbacks[@cmd_seq] = response_callback
    buf = msgpack.encode([RPC.REQUEST, @cmd_seq, cmd, args])
    if buf instanceof Buffer
      @nvim_process.stdin.write buf
    else # must be BufferList
      buf.pipe @nvim_process.stdin
    @cmd_seq += 1
    if @cmd_seq > RPC.MAX_SEQ
      @cmd_seq = 0

  clone_and_decode: (obj) ->
    switch
      when obj instanceof Buffer then obj.toString()
      when obj instanceof Array then @clone_and_decode i for i in obj
      when obj instanceof Object
        obj2 = {}
        for own k,v of obj
          obj2[@clone_and_decode k] = @clone_and_decode v
        obj2
      else obj

  get_vim_api: (callback) ->
    @send 'vim_get_api_info', [], (res) =>
      @channel_id = res[0]

      # extract types
      @types = {}
      for name, obj of res[1].types
        @types[obj.id] = name

      # extract functions
      @functions = {}
      for obj in res[1].functions
        name = obj.name.toString()
        @functions[name] = @clone_and_decode(obj)

      callback()

  ui_attach: (callback) ->
    @send 'ui_attach', [80, 40, true], (res) =>
      callback()


module.exports = NVim
