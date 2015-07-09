glob    = require 'glob'
fs      = require 'fs'
path    = require 'path'
R       = require 'ramda'
crypto  = require 'crypto'

class DigestManifest

  brunchPlugin: true

  constructor: (@config) ->
    @publicFolder = @config.paths.public
    @manifest = []
    @options = {}

  isFile: (url) => fs.statSync(path.resolve(@publicFolder, url)).isFile() and url isnt 'manifest.json'

  sha1Map: (url) =>
    data = fs.readFileSync path.resolve(@publicFolder, url)
    shasum = crypto.createHash 'sha1'
    shasum.update(data)
    return {
      url: url
      sha1: shasum.digest('hex')[0..8]
    }

  hashedFilePath: (spec) => {
    hashedUrl : spec.url.replace('.', ".#{spec.sha1}.")
    url: spec.url
  }

  storeInManifest: (spec) =>
    @manifest.push(spec)
    spec

  writeManifest: (spec) =>
    fs.writeFileSync(
      path.resolve(@publicFolder, 'manifest.json'),
      JSON.stringify(spec),
      'utf8'
    )
    spec

  renameFile: (spec) =>
    fs.renameSync(
      path.resolve(@publicFolder, spec.url),
      path.resolve(@publicFolder, spec.hashedUrl)
    )
    spec.hashedUrl

  onCompile: ->

    filesToHash = =>

      compute = R.compose(

        R.map(@renameFile)

        R.map(@storeInManifest)

        # {
        #   url: '/relative/path/to/file.ext',
        #   sha1: 'sha1xq0ds'
        # } => {
        #   url: '/relative/path/to/file.ext',
        #   hashedUrl: '/relative/path/to/file.sha1xq0ds.ext'
        # }
        R.map(@hashedFilePath)

        # '/relative/path/to/file.ext' => {
        #   url: '/relative/path/to/file.ext',
        #   sha1: 'sha1xq0ds'
        # }
        R.map(@sha1Map)

        # => '/relative/path/to/file.ext'
        R.filter(@isFile)
      )

      compute(glob.sync('**', { cwd: @publicFolder }))


    files = filesToHash()
    @writeManifest(@manifest)


module.exports = DigestManifest
