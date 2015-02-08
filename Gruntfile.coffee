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
          'src/nvim/nvim.js': 'src/nvim/nvim.coffee'
          'src/nvim/main.js': 'src/nvim/main.coffee'


  grunt.registerTask 'default', ['coffee']
