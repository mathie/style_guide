module.exports = (grunt) ->
  grunt.initConfig
    # Import package metadata from package.json, just in case it's useful.
    pkg: grunt.file.readJSON('package.json')

    # less tasks for converting less source to CSS.
    less:
      options:
        paths: [ 'bower_components' ]
      development:
        files:
          "public/assets/stylesheets/application.css": "app/assets/stylesheets/application.less"

  grunt.loadNpmTasks('grunt-contrib-less')
