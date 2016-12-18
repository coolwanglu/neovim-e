# config.coffee
# user configs
# Copyright (c) 2015 Lu Wang <coolwanglu@gmail.com>

{remote} = require 'electron'
path = require 'path'
cson = require 'cson'
{remote: {app}} = require 'electron'

# default
config =
  fg_color: '#000'
  bg_color: '#fff'
  row: 40
  col: 80
  font: '13px Inconsolata, Monaco, Consolas, \'Source Code Pro\', \'Ubuntu Mono\', \'DejaVu Sans Mono\', \'Courier New\', Courier, monospace'
  blink_cursor: true

user_config_file_name = path.join app.getPath('userData'), 'config.cson'
try
  user_config = cson.load user_config_file_name
  if user_config not instanceof Error
    for k of config
      if user_config[k]?
        config[k] = user_config[k]

module.exports = config
