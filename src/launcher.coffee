# launcher.coffee
# entry point of the app
# Copyright (c) 2015 Lu Wang <coolwanglu@gmail.com>

app = require 'app'
BrowserWindow = require 'browser-window'

process.on 'uncaughtException', (error={}) ->
  console.log error.message  if error.message?
  console.log error.stack  if error.stack?

app.on 'window-all-closed', -> app.quit()

win = null
app.on 'ready', ->
  win = new BrowserWindow width: 800, height: 600
  win.loadUrl 'file://' + __dirname + '/nvim.html'
