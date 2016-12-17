# config.coffee
# user configs
# Copyright (c) 2015 Lu Wang <coolwanglu@gmail.com>

{remote} = require 'electron'
path = require 'path'
cson = require 'cson'
{app} = require 'electron'

# default
config =
  fg_color: '#000'
  bg_color: '#fff'
  row: 40
  col: 80
  font: '13px Inconsolata, Monaco, Consolas, \'Source Code Pro\', \'Ubuntu Mono\', \'DejaVu Sans Mono\', \'Courier New\', Courier, monospace'
  blink_cursor: true

module.exports = config
