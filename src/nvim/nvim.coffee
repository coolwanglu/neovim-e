remote = require 'remote'
child_process = require 'child_process'
msgpack = require('msgpack5')()

RPC =
  REQUEST: 0
  RESPONSE: 1
  NOTIFY: 2
  MAX_SEQ: 2**32-1

class NVim
  constructor: ->
    @cmd_seq = 0
    @callbacks = {}

    @nvim_process = child_process.spawn 'nvim', ['--embed'], stdio: ['pipe', 'pipe', process.stderr]
    console.log 'child process spawned: ', @nvim_process.pid

    @nvim_process.on 'close', => console.log 'child process closed'

    @decoder = msgpack.decoder header: false
    @decoder.on 'data', (data) => @on_data(data)
    @nvim_process.stdout.pipe @decoder

    @get_vim_api()
#    @send('vim_get_api_info', [])

  on_data: (data) ->
    switch data[0]
      when RPC.RESPONSE
        msg_id = data[1]
        if @callbacks[msg_id]?
          callback = @callbacks[msg_id]
          delete @callbacks[msg_id]

        if data[3]? and callback[0]? #success
          callback[0] data[3]
        else if data[2]? #error
          (callback[1] ? (data) -> console.log 'child ERR: ', data) data[2]
      when RPC.NOTIFY
        console.log 'child NOTIFY: ', data[1], data[2]
      else console.log 'unknown msgpack message: ', JSON.stringify data

  send: (cmd, args, response_callback, error_callback) ->
    if response_callback or error_callback
      @callbacks[@cmd_seq] = [response_callback, error_callback]
    buf = msgpack.encode([RPC.REQUEST, @cmd_seq, cmd, args])
    if buf instanceof Buffer
      @nvim_process.stdin.write buf
    else
      bl.pipe @nvim_process.stdin
    @cmd_seq += 1
    if @cmd_seq > RPC.MAX_SEQ
      @cmd_seq = 0

  get_vim_api: ->
    @send 'vim_get_api_info', [], (res) =>
      console.log res

module.exports = NVim
