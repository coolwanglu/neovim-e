module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-contrib-coffee'

  grunt.initConfig
    pkg: grunt.file.readJSON('package.json')

    coffee:
      compileJoined:
        options:
          join: true
          sourceMap: true
        files:
          'src/launcher.js': 'src/launcher.coffee'
          'src/nvim/config.js': 'src/nvim/config.coffee'
          'src/nvim/key_handler.js': 'src/nvim/key_handler.coffee'
          'src/nvim/main.js': 'src/nvim/main.coffee'
          'src/nvim/nvim.js': 'src/nvim/nvim.coffee'
          'src/nvim/ui.js': 'src/nvim/ui.coffee'


  grunt.registerTask 'default', ['coffee']
