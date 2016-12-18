# main.coffee
# entry point of the renderer
# Copyright (c) 2015 Lu Wang <coolwanglu@gmail.com>

window.onload = ->
  try
    window.nvim = new (require('./nvim/nvim'))()
  catch error
    win = require('electron').remote.getCurrentWindow()
    win.setSize 800, 600
    win.center()
    win.show()
    win.openDevTools()
    console.log error.stack ? error
