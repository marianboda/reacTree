gulp = require 'gulp'
shell = require 'gulp-shell'
coffee = require 'gulp-coffee'
sourcemaps = require 'gulp-sourcemaps'
jade = require 'gulp-jade'
mainBowerFiles = require 'main-bower-files'
coffeelint = require 'gulp-coffeelint'

vinyl = require 'vinyl-source-stream'
changed = require 'gulp-changed'
async = require 'async'
inject = require 'gulp-inject'
ignore = require 'gulp-ignore'
flatten = require 'gulp-flatten'
runSequence = require 'run-sequence'
sass = require 'gulp-ruby-sass'
react = require 'gulp-react'
gulpBrowserify = require 'gulp-browserify'
browserify = require 'browserify'
watchify = require 'watchify'
livereload = require 'gulp-livereload'
rename = require 'gulp-rename'

srcDirs =
  js: 'src'
  jade: 'src'
  sass: 'src/styles'
destDirs =
  js: 'app'
  lib: 'app/lib'
  templates:'app'
  styles:'app/css'

paths =
  csFiles: ["#{srcDirs.js}/**/*.coffee"]
  jadeFiles: ["#{srcDirs.jade}/**/*.jade"]
  sassFiles: ["#{srcDirs.sass}/**/*.sass"]

gulp.task 'bowerFiles', ->
  gulp.src(mainBowerFiles()).pipe(gulp.dest('app/libs'))

gulp.task 'inject', ->
  libs = mainBowerFiles().map((a) -> 'app/libs/'+a.substr(a.lastIndexOf('/')+1))
  libs.push 'app/libs/pure.base.css'
  gulp.src('./app/index.html')
  .pipe(inject(gulp.src(libs, {read: false}),
    {name: 'libs', relative: true}))
  # .pipe(inject(gulp.src('app/libs/**/*', read: false), {name: 'libs', relative: true}))
  .pipe(inject(gulp.src(['app/js/**/*.js','!app/js/app.js'],
    read: false), {name: 'scripts', relative: true}))
  .pipe(inject(gulp.src(['app/css/**/*.css'],
    read: false), {name: 'styles', relative: true}))
  .pipe(gulp.dest './app')

gulp.task 'lint', ->
  gulp.src('./src/*.coffee').pipe(coffeelint()).pipe(coffeelint.reporter())

gulp.task 'coffee', ->
  gulp.src(paths.csFiles)
  .pipe(changed(destDirs.js, {extension: '.js'}))
  .pipe(sourcemaps.init())
  .pipe(coffee({bare: true}).on("error", (e) -> console.log(e); @end()))
  .pipe(sourcemaps.write())
  .pipe(gulp.dest(destDirs.js))

gulp.task 'jade', ->
  gulp.src(paths.jadeFiles)
      .pipe(jade({pretty: true}))
      .pipe(gulp.dest(destDirs.templates))
      # .pipe(livereload())

gulp.task 'jadeAndInject', ->
  runSequence 'jade', 'inject'

gulp.task 'sass', ->
  gulp.src(paths.sassFiles).pipe(sass()).on('error', (e) -> console.log e).pipe(gulp.dest(destDirs.styles))

gulp.task 'watch', ['broWatch'], ->
  # gulp.watch [paths.csFiles],
  # gulp.watch [paths.csFiles], ['gulpBrowserify']
  gulp.watch [paths.jadeFiles], ['jadeAndInject']
  gulp.watch [paths.sassFiles], ['sass']
  livereload.listen(35729)

gulp.task 'broWatch', ->
  args = watchify.args
  args.debug = true
  bundler = watchify(browserify('./src/app.coffee', args))
  bundler.transform('coffeeify')
  rebundle = ->
    console.log 'rebundling..'
    bundler.bundle()
      .on('error', -> console.log 'Browserify Error')
      .pipe(vinyl('bundle.js'))
      .pipe(gulp.dest('app'))
      .pipe(livereload())
  bundler.on 'update', rebundle
  rebundle()

gulp.task 'gulpBrowserify', ->
  gulp.src('src/app.coffee', read: false)
  .pipe(gulpBrowserify
    transform: 'coffeeify'
    extensions: '.coffee'
    debug: true
  )
  .pipe(rename('bundle.js'))
  .pipe(gulp.dest('app'))

gulp.task 'default', ->
  runSequence ['jade', 'sass'], 'gulpBrowserify'
