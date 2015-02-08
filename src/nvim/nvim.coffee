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

    @nvim_process = child_process.spawn 'nvim', ['--embed'], stdio: ['pipe', 'pipe', 2]
    @nvim_process.on 'close', => console.log 'child process closed'
    console.log 'child process spawned: ', @nvim_process.pid

    @decoder = msgpack.decoder header: false
    @decoder.on 'data', (data) => @on_data(data)
    @nvim_process.stdout.pipe @decoder

    @send('vim_get_api_info', [])

  on_data: (data) ->
    console.log 'received: ', data

  send: (cmd, args, callback) ->
    #TODO: register callback
    #msgpack.encode([RPC.REQUEST, @cmd_seq, cmd, args]).pipe @nvim_process.stdin
    buf = msgpack.encode([RPC.REQUEST, @cmd_seq, cmd, args])
    if buf instanceof Buffer
      @nvim_process.stdin.write(buf)
    else
      bl.pipe @nvim_process.stdin
    @cmd_seq += 1
    if @cmd_seq > RPC.MAX_SEQ
      @cmd_seq = 0


module.exports = NVim
