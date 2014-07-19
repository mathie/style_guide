module.exports = (grunt) ->
  grunt.initConfig
    # Import package metadata from package.json, just in case it's useful.
    pkg: grunt.file.readJSON('package.json')

    mkdir:
      options:
        mode: '0755'
      build:
        options:
          create: [ 'build' ]
      assets:
        options:
          create: [
            'public/assets/stylesheets',
            'public/assets/javascripts',
            'public/assets/images',
          ]

    # less tasks for converting less source to CSS.
    less:
      options:
        paths: [ 'bower_components' ]
      development:
        files:
          "public/assets/stylesheets/application.css": "app/assets/stylesheets/application.less"

    coffee:
      options:
        sourceMap: true
        joinExt: '.coffee'
      development:
        files:
          'build/javascripts/application.js': [
            'app/assets/javascripts/**/*.coffee'
          ]

    uglify:
      options:
        sourceMap: true
        sourceMapIn: 'build/javascripts/application.js.map'
      development:
        files:
          'public/assets/javascripts/application.js': [
            'bower_components/jquery/dist/jquery.js',
            'bower_components/bootstrap/dist/bootstrap.js',
            'build/javascripts/application.js'
          ]

    imagemin:
      development:
        files: [
          expand: true
          cwd: 'app/assets/images'
          src: [ '**/*.{jpg,png,gif}' ]
          dest: 'public/assets/images'
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
        tasks: [ "css" ]
      coffee:
        files: [
          "app/assets/javascripts/**/*.coffee"
        ]
        tasks: [ "js" ]
      images:
        files: [
          "app/assets/images/**/*.{jpg,png,gif}"
        ]
        tasks: [ "imagemin" ]

    clean:
      assets:
        src: [ "public/assets" ]
      build:
        src: [ "build" ]

  grunt.loadNpmTasks('grunt-contrib-less')
  grunt.loadNpmTasks('grunt-contrib-watch')
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-contrib-clean')
  grunt.loadNpmTasks('grunt-contrib-imagemin')
  grunt.loadNpmTasks('grunt-contrib-uglify')
  grunt.loadNpmTasks('grunt-mkdir')

  grunt.registerTask "default", [ "build" ]
  grunt.registerTask "js", [ "coffee", "uglify" ]
  grunt.registerTask "css", [ "less" ]
  grunt.registerTask "build", [ "mkdir", "imagemin", "css", "js" ]
  grunt.registerTask "dev", [ "clean", "build", "watch" ]
