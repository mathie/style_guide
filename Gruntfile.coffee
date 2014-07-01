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

    coffee:
      development:
        files: [
          expand: true,
          cwd: 'app/assets/javascripts'
          src: [ '**/*.coffee' ]
          dest: 'build/javascripts'
          ext: '.js'
        ]

    # Watch source files for changes and rebuild the associated assets
    watch:
      options:
        livereload: true
        spawn: false
      gruntfile:
        files: [ "Gruntfile.coffee"]
        options:
          reload: true
      stylesheets:
        files: [
          "app/assets/stylesheets/**/*.less",
          "bower_components/**/*.less"
        ]
        tasks: [ "less" ]
      coffee:
        files: [
          "app/assets/javascripts/**/*.coffee"
        ]
        tasks: [ "coffee" ]

  grunt.loadNpmTasks('grunt-contrib-less')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-coffee')

  grunt.registerTask "default", [ "build" ]
  grunt.registerTask "build", [ "less", "coffee" ]
  grunt.registerTask "dev", [ "build", "watch" ]
