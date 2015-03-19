# config.coffee
# user configs
# Copyright (c) 2015 Lu Wang <coolwanglu@gmail.com>

remote = require 'remote'
path = require 'path'
cson = require 'cson'
app = remote.require 'app'

user_config_file_name = path.join app.getPath('userData'), 'config.cson'

# default
config =
  fg_color: '#000'
  bg_color: '#fff'
  row: 80
  col: 40
  font: '13px Inconsolata, Monaco, Consolas, \'Source Code Pro\', \'Ubuntu Mono\', \'DejaVu Sans Mono\', \'Courier New\', Courier, monospace'
  blink_cursor: true
  # user_path: user_config_file_name
  user_path: app.getPath("userData")
  reload: ->
    changed = false
    try
      user_config = cson.load user_config_file_name
      if user_config not instanceof Error
        for k of config
          if user_config[k]?
            changed = true if @[k] != user_config[k]
            @[k] = user_config[k]
    return changed

config.reload()

module.exports = config
