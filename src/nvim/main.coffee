window.onload = ->
  try
    new (require('./nvim/nvim'))()
  catch error
    win = require('remote').getCurrentWindow()
    win.setSize 800, 600
    win.center()
    win.show()
    win.openDevTools()
    console.log error.stack ? error
