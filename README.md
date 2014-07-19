# Front End web app development 101

I could easily be labelled as a “[Ruby on] Rails Developer” and I’m quite content with the asset pipeline for managing various front-end web development assets (Javascript, CSS, client side templates, images, fonts, etc). But since I’m playing around with [Go](http://golang.org/) for back end development on my current project, I thought I’d investigate current practices for managing assets on the front end. This is a rambling log of what I learned while I was playing around.

Here are the goals I’m aiming for:

* [x] versioned package management for the client side, including their dependencies, giving us a consistent set of source files used to deliver the web site, both in development and in production;
* [x] using [{less}](http://lesscss.org) as a preprocessor for generating CSS (or [Sass](http://sass-lang.com), maybe, if that’s what my CSS framework of choice happens to use);
* [x] using [Twitter Bootstrap][bootstrap] as a CSS framework to make my app look pretty enough while I’m developing it, while encouraging me to write semantic CSS and HTML so a real designer can do something sensible with it;
* [x] using [CoffeeScript](http://coffeescript.org) as a preprocessor, at least for any front end code I have to write;
* [ ] dependency management for my JavaScript code so things are pulled in and used in the right order;
* [x] efficient delivery of assets in production (where my understanding of “efficient delivery” is concatenation to minimise HTTP requests, and minification to reduce file size);
* [x] a smooth workflow in development (automatically producing assets from my source files when I change them, live reloading of pages, that kind of thing).
	* [x] for CSS; and
	* [x] Javascript.
* the ability to debug in-browser errors, mapping them back to the source that caused them:
	* [x] for CSS; and
	* [x] JavaScript.

Hopefully, as I work through this guide, I’ll achieve most of these goals!

## Project background

Let’s have a worked example to keep us on track. Let’s say I’m building a style guide — a tiny application which shows off my “house style” for CSS and JavaScript components. As it turns out, my house style is *identical* to the default Twitter Bootstrap one, so there’s not much to the app. ;-)

## Creating the project

Since I’m building a [Go](http://golang.org/) web app for the backend, let’s start out by having a simple project which serves static files from a `public/` directory. I’m assuming that I already have a Go workspace set up. (If you don’t, follow along with the instructions in [Writing Go Code](http://golang.org/doc/code.html) to create a workspace and set up your environment.) My Go workspace for this project is rooted at `~/Development/Go`, so my `$GOPATH` is set accordingly:

    export GOPATH=${HOME}/Development/Go

First of all, let’s create the project and stash it in a git repository to keep track of what I’m doing:

```shell
mkdir -p ${GOPATH}/src/github.com/mathie/style_guide
cd ${GOPATH}/src/github.com/mathie/style_guide
cat > README.md << EOF
# Style Guide

Welcome to the house style guide.
EOF
git init && git add . && git commit -m “Empty project.”
```

I won’t continue to nag you to commit changes as we’re going along; that’s up to you!

## A static file server

This isn’t about Go, so it isn’t the most exciting web application server, either. I’ve created a basic server which will serve static files from the `public/` folder. Call it `main.go` in the project root:

```go
// A simple Go web application which serves static files from the `public`
// folder in the project. By default, it listens on port 8080, though you can
// change that below, if you like.
package main

import (
	"net/http"
)

// The main function is the entry point into the application. It creates a file
// server which will serve static files from the `public` folder, listening on
// port 8080.
func main() {
	http.Handle("/", http.FileServer(http.Dir("public")))
	http.ListenAndServe(":8080", nil)
}
```

That’s it. I can run the application server directly with:

```shell
go run main.go
```

and visit <http://localhost:8080/> which will display `404 page not found` since we don’t have any content to serve yet. Let’s fix that, by creating `public/index.html` with the default template that Bootstrap recommends:

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Style Guide</title>

    <link href=“/assets/stylesheets/application.css” rel="stylesheet">
  </head>
  <body>
    <h1>Style Guide</h1>

    <p>Welcome to my style guide.</p>

    <script src=“/assets/javascripts/application.js”></script>
  </body>
</html>
```

It’s currently referencing a couple of assets that don’t yet exist. That’s OK, I just wanted to set myself a target for what files should be generated when we get to that. At least visiting <http://localhost:8080/> now should succeed, and show our plain, un-styled, style guide. Now we can get on with meeting some of the goals!

## Installing client side packages

We have identified a single dependency for the front end application: [Twitter Bootstrap][bootstrap]. Since we’re making use of some of the Javascript components, we also indirectly depend on [jQuery][]. Hopefully, I won’t have to think about recursive dependencies though. After doing a bit of a dig around online, and in my own “stuff I’ve read recently” list, it seems like [Bower][] is good enough for the job.

### Installing Node & Bower

The easiest way to install it on Mac OS X seems to be through [npm][] which, in turn, can be installed as part of [NodeJS][] with [Homebrew][] (it really is [package managers all the way down](http://en.wikipedia.org/wiki/Turtles_all_the_way_down)):

    brew install node
    npm install -g bower

I’ll use `npm` to track development dependencies (i.e. bower) and their versions, so I’ve got a consistent environment wherever I’m doing development. Create a starting point for `package.json` in the project root:

```json
{
  "name": "style_guide",
  "version": "0.1.0",
  "description": "My simple CSS style guide.",
  "author": "Graeme Mathieson <mathie@woss.name> (http://woss.name/)",
  "homepage": "https://github.com/mathie/style_guide”,
  “repository”: "https://github.com/mathie/style_guide"
}
```

Now I’ve got enough basics to stop `npm` from warning me about missing bits, I can add my first development dependency:

```shell
npm install --save bower
```

This both installs bower locally, in a `node_modules/` folder at the root of the project, and adds it as a versioned dependency in `package.json`. (I did toy with the idea of wanting to tidy up the unpacked local copy of the modules into `vendor/node/` or equivalent, but it looks like that would involve a fight.)

I’ll also add `node_modules/` to my project’s `.gitignore` file — I’m happy enough that we’ve fixed a reference to the version of the package we’re using, so I don’t feel the need to vendor it, too. Your mileage and opinions will, of course, vary.

### Managing client side dependencies with Bower

Now we’ve got bower installed, it needs a configuration file at the root of the project, called `bower.json` to hold its configuration. Let’s create a sensible default:

```json
{
  "name": "style_guide",
  "version": "0.1.0",
  "private": true,
  "ignore": [
    "node_modules",
    "bower_components"
  ]
}
```

The name and version are the same as `package.json`. Wouldn’t it be nice if they could be shared instead of being repeated? I guess there’s a reason for them being separate, but I loathe duplication, particularly with things like version numbers, which are so easy to forget to change before distribution a new release!

Anyway. I’ve set `private` to true, which should prevent me from accidentally distributing my application as a bower module, and I’ve set it to ignore folders containing the packages we’re setting up to manage. (This is suggested as a default, anyway, so seems sensible.)

### Installing Grunt

Grunt is a task runner, which manages dependencies amongst tasks, just like `make`. It seems to be a rite of passage that every programming language on every platform must reinvent `make`. (I think it’s something to do with an allergic reaction to tab characters.) Let’s install grunt and make it a “development” dependency (i.e. a dependency that’s only required if I’m developing, or packaging, this application, not if I’m just running it in production):

    npm install --save-dev grunt

This downloads and unpacks the grunt into the `node_modules` folder, and adds it to `package.json`. In addition, in order to run the grunt command line tool, I need to globally install the `grunt-cli` package:

    npm install -g grunt-cli

All this command line tool does is to find the version of grunt that’s associated with the `Gruntfile` it’s attempting to use, then invoke it.

### Installing Twitter Bootstrap

Finally, we can install Bootstrap:

    bower install --save bootstrap

This downloads both Bootstrap and jQuery, unpacks them into the `bower_components` folder, and adds a note of the versioned dependency into our `bower.json` so it knows which version to install next time (which gives us our “consistent set of source files” goal).

We haven’t yet got to the stage where we can serve up these components, though, since they are outside the web root. Let’s get the CSS sorted, first, then worry about the Javascript in a bit.

## Building stylesheets with Less

Since Bootstrap is developed with Less (even if there is now an automagic Sass port for the Rails punters who like fewer dependencies), let’s use that for our own stylesheets, too. I’ll use Less’s import mechanism to generate a single CSS file. Since I’m a Rails weenie, and I’m quite happy with its folder structure, I’m looking to turn `app/assets/stylesheets/application.less` into `public/assets/stylesheets/application.css`.

Fortunately, grunt has an officially maintained module for that, called [`grunt-contrib-less`](https://www.npmjs.org/package/grunt-contrib-less). Let’s install that as a development dependency:

    npm install --save-dev grunt-contrib-less

Now let’s configure grunt to take some of the grunt work out of producing CSS files. The bulk of the configuration happens in the `Gruntfile`. Now this file can either be `Gruntfile.js` or `Gruntfile.coffee`, depending on what you’d rather write. I’m quite fond of CoffeeScript, but most of the examples are in straight JS, so there’s a fine line between paths of insanity. Let’s give CoffeeScript a go. Create `Gruntfile.coffee` with the following content:

```coffeescript
module.exports = (grunt) ->
  grunt.initConfig
    # Import package metadata from package.json, just in case it's useful.
    pkg: grunt.file.readJSON('package.json')

  grunt.loadNpmTasks('grunt-contrib-less')
```

All that remains to do is configure the less task. This code block is inserted as part of the JS object that’s passed as an argument to `grunt.initConfig()`:

```coffeescript
    # less tasks for converting less source to CSS.
    less:
      options:
        paths: [ 'bower_components' ]
      development:
        files:
          "public/assets/stylesheets/application.css": "app/assets/stylesheets/application.less"
```

It’s pretty straightforward, with two things happening:

* The generated file in `public/assets/stylesheets/application.css` is generated from the source file, `app/assets/stylesheets/application.less`. (It in turn imports other files, but that’s our entry point into {{less}}][lesscss]-land.)
* The `bower_components` folder is added to the search path.

The latter allows, more sensible imports inside a less file, to be able to:

```less
@import ‘bootstrap/less/bootstrap.less’;
```

instead of:

```less
@import ‘../../../bower_components/bootstrap/less/bootstrap.less’;
```

which is a bit unwieldy. I can regenerate the CSS by running `grunt less`:

    grunt less
    Running "less:development" (less) task
    File public/assets/stylesheets/application.css created: 0 B → 21.4 kB

    Done, without errors.

Reloading <http://localhost:8080/> shows up the page with the stylesheet applied. I’ve got a simple set of stylesheets so far, split into a couple of files just to prove that less is successfully importing files:

>     @import 'base.less';

<cite>from `app/assets/stylesheets/application.less`</cite>

>     // Pull in the minimal bits of Bootstrap I need right now:
>     
>     // Core variables and mixins
>     @import 'bootstrap/less/mixins.less';
>     @import 'bootstrap/less/variables.less';
>     
>     // Bootstrap reset
>     @import 'bootstrap/less/normalize.less';
>     @import 'bootstrap/less/print.less';
>     
>     // Core CSS
>     @import 'bootstrap/less/scaffolding.less';
>     @import 'bootstrap/less/type.less';
>     
>     // Customise some of the bootstrap variables.
>     @import 'variables.less';

<cite>from `app/assets/stylesheets/base.less`</cite>

>     @body-bg: #ccc;

<cite>from `app/assets/stylesheets/variables.less`</cite>

I’ve also added `/public/assets` to my `.gitignore` so I don’t accidentally check in generated files if I can possibly avoid it.

## Watching for file changes

The trouble is that the workflow here isn’t terribly elegant: every time I make a change to a less source file, I have to run `grunt less`, wait for it to complete, and reload the page to see the effect of the change. Let’s fix that with the grunt [watch](https://www.npmjs.org/package/grunt-contrib-watch) plugin (another one that’s officially maintained by the Grunt team). First of all, install it:

    npm install --save-dev grunt-contrib-watch

Now to configure it, I’ve added the following configuration inside the `grunt.initConfig()` arguments:

```coffeescript
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
```

and load the module in the main `module.exports` method:

```coffeescript
  grunt.loadNpmTasks('grunt-contrib-watch')
```

This tells it to watch all the less files in `app/assets/stylesheets` and `bower_components` and, if any of them change, trigger the `less` task, which will rebuild them all. If, in future, I find this is taking too long to complete, and that I have different entry point stylesheets for different parts of the app, I can break this down to be more fine grained, but it’ll do nicely for now.

There’s also a task in there to watch for changes to the `Gruntfile.coffee` and reload, so I don’t have to restart it manually when I’m mucking around with it. Now start it up with:

    grunt watch

Leave that running in a terminal. It’ll let you know when one or more tasks are triggered.

The watch plugin also has built in support for [Live Reload](http://livereload.com/) so if you’ve got the browser plugin installed and enabled (I’m using the [Google Chrome Live Reload extension](https://chrome.google.com/webstore/detail/livereload/jnihajbhpnppcggbcgedagnkighmdlei) it will automatically refresh your page when the stylesheets have been rebuilt.

## Delivering JavaScript

I’ve never really considered myself a JavaScript developer — I spend most of my time in the back end, thinking of client side JS as being the kind of polish the design team to improve user experience. That changed when I built a JS-heavy application where every open browser window was essentially the eventually consistent state of an auction room.

Fortunately, [CoffeeScript][] had my back, papering over the gnarly cracks of JavaScript that were bound to trip me up. I’ve come to rather like it, so I’d like to develop code in CoffeeScript and have it all bundled up, ready to be delivered to browser. Let’s install the [grunt coffee plugin](https://github.com/gruntjs/grunt-contrib-coffee):

    npm install --save-dev grunt-contrib-coffee

Now to configure it, add options to the `grunt.initConfig`:

```coffeescript
    coffee:
      development:
        files: [
          expand: true,
          cwd: 'app/assets/javascripts'
          src: [ '**/*.coffee' ]
          dest: 'build/javascripts'
          ext: '.js'
        ]
```

and get Grunt to load up the tasks:

```coffeescript
  grunt.loadNpmTasks('grunt-contrib-coffee')
```

This will compile each of the files in `app/assets/javascripts` from CoffeeScript down to JavaScript, and spit them out in a build folder. We’ve got a little more work to do before we’re done, though. Let’s also create a watch job to look out for changes and automatically rebuild the JS file on demand:

```coffeescript
      coffee:
        files: [
          "app/assets/javascripts/**/*.coffee"
        ]
        tasks: [ "coffee" ]
```

## Building everything at once

Now we’re getting to the stage where I’ve got several tasks I need to run in order to get everything built, which is slowing down my workflow (and, worse, making me forget to do bits!). Let’s get back to automating that. I want two targets right now:

* `build`, which will produce all the public assets, ready to serve; and
* `dev` which will build everything at first, then watch for changes and rebuild them on demand.

For bonus points, if you run `grunt` without any arguments, it will look for, and invoke, the `default` task. Let’s take advantage of that so it defaults to building all the project’s assets. Add the following inside the `grunt.initConfig()` function:

```coffeescript
grunt.registerTask "default", [ "build" ]
grunt.registerTask "build", [ "less", "coffee" ]
grunt.registerTask "dev", [ "build", "watch" ]
```

That’s enough to deal with our own code, but how about the third party JS? And how about managing the order in which JS code is included, so dependent bits get loaded first?

## Cleaning up

It’s always nice to clean up after ourselves, so we know we can build the app from a pristine environment. Grunt helpfully provides a [`grunt-contrib-clean`](https://github.com/gruntjs/grunt-contrib-clean) plugin that does the job. Install the plugin with:

    npm install --save-dev grunt-contrib-clean

Configure it to clean up all the results of the build and interim working files with the following in `grunt.initConfig()`:

```coffeescript
    clean:
      assets:
        src: [ "public/assets" ]
      build:
        src: [ "build" ]
```

and load the task:

```coffeescript
  grunt.loadNpmTasks('grunt-contrib-clean')
```

I can now clean up all the generated files with:

    grunt clean

I’ve also modified the `build` task so that it cleans and rebuilds everything from scratch:

```coffeescript
grunt.registerTask "build", [ “clean”, ”less", "coffee" ]
```

## Optimising images

I didn’t set out to include this in the workflow, but having tripped across the grunt plugin to enable it, I thought I might as well add optimised images to my workflow, too. It’s great to have high resolution image assets in the source tree, while being able to deliver (bandwidth-) optimised versions to users in production. So, why not?

The image optimisation plugin needs the target directory to already exist for it to work, so I’ve also added a task to create all the target directories (it doesn’t hurt the JS and CSS pipelines to make sure their target folders exist, either). Install the packages with:

    npm install --save-dev grunt-contrib-imagemin grunt-mkdir

and load their tasks as before:

```coffeescript
  grunt.loadNpmTasks('grunt-contrib-imagemin')
  grunt.loadNpmTasks('grunt-mkdir')
```

<cite>from `Gruntfile.coffee`</cite>

I’ve configured the `mkdir` task to create the `javascripts`, `stylesheets`, and `images` folders in the `public` directory, and to create the intermediate `build` directory, with this:

```coffeescript
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
```

<cite>from `Gruntfile.coffee`</cite>

To configure the image optimisation plugin, I’ve asked it to create minified versions of all images in the `app/assets/images` folder, and put them into `public/images` with the following task:

```coffeescript
    imagemin:
      development:
        files: [
          expand: true
          cwd: 'app/assets/images'
          src: [ '**/*.{jpg,png,gif}' ]
          dest: 'public/assets/images'
        ]
```

<cite>from `Gruntfile.coffee`</cite>

And I’ve added extra configuration to the file watcher, so that every time an image changes, it re-minifies them:

```coffeescript
      images:
        files: [
          "app/assets/images/**/*.{jpg,png,gif}"
        ]
        tasks: [ "imagemin" ]
```

<cite>from `Gruntfile.coffee`</cite>

In principle, this will eventually get pretty slow — every time a single image gets changed, it will regenerate all of them — but that’s a problem I can solve (by getting it to only update the images that have changed) when it becomes a pain point.

I’ve changed the `build` and `dev` tasks so that they incorporate creating directories and minifying images into the build process:

```coffeescript
  grunt.registerTask "build", [ "mkdir", "imagemin", "less", "coffee" ]
  grunt.registerTask "dev", [ "clean", "build", "watch" ]
```

<cite>from `Gruntfile.coffee`</cite>

Of course, all this was a distraction from figuring out how to implement dependency management with the JavaScript. Let’s tackle that next.

## Incorporating Third Party JS

This turned into a bit of a fight, so I’ve gone with something “easy” that will do for now, and I can always fix it later (by which I mean, “please do investigate, and submit pull requests!”). For now, all I’m doing is concatenating together all the bower components that are JS dependencies, in order, then concatenating together all my own Javascript code (converted from CoffeeScript already) into a single JavaScript file that’s served to the browser.

The CoffeeScript plugin already has the ability to concatenate source files, and to produce a source map. Let’s tweak the existing `coffee` configuration to do that:

```coffeescript
      options:
        sourceMap: true
        joinExt: '.coffee'
       development:
        files:
          'build/javascripts/application.js': [
            'app/assets/javascripts/**/*.coffee'
          ]
```

<cite>from `Gruntfile.coffee`</cite>

This will take all our CoffeeScript source and compile it down to a single `build/javascripts/application.js`, while also creating a source map, `build/javascripts/application.js.map`.

In order to generate the single JavaScript file that we deliver to the browser, let’s use [`grunt-contrib-uglify`](https://github.com/gruntjs/grunt-contrib-uglify):

    npm install —save-dev grunt-contrib-uglify

and load the task into `Gruntfile.coffee`:

    grunt.loadNpmTasks('grunt-contrib-uglify')

I’ve configured it inside `initConfig()` with the following:

```coffeescript
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
```

<cite>from `Gruntfile.coffee`</cite>

It takes the compiled coffee script code, and the distribution files from the bower components, then produces the final application.js and its associated map file. It’s enough that I get working JS in the browser, and I get a reference back to my source file on errors in the browser, so I’m content with that for now.

## Summary

Perhaps I started out by asking for too much in the first place, but this seemed harder than it needed to be! Still, I have a build pipeline which takes version third party dependencies for CSS, images, and JavaScript, along with my own styles, CoffeeScript, and images, and it pushes them into the browser. I’m reasonably confident I can continue to work with the pipeline, adding new components as I need them. At some point I’d like to figure out proper dependency management for the JS side (like CommonJS or RequireJS or some equivalent) so I can declare the dependencies where they’re required rather than carefully ordering the build. But it’ll keep me going for now.

[bootstrap]: <http://getbootstrap.com/> (Twitter Bootstrap: The most popular front-end framework for developing responsive, mobile first projects on the web)
[jquery]: <http://jquery.com> (jQuery: Write less, do more)
[bower]: <http://bower.io> (Bower: A package manager for the web)
[npm]: <https://www.npmjs.org> (Node Package Manager)
[nodejs]: <http://nodejs.org> (NodeJS)
[homebrew]: <http://brew.sh> (Homebrew: The missing package manager for OS X)
[coffeescript]: <http://coffeescript.org> (CoffeeScript: a little language that compiles into JavaScript)
[browserify]: <http://browserify.org> (Browserify lets you require(‘modules’) in the browser by bundling up all your dependencies.)
