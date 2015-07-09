glob    = require 'glob'
fs      = require 'fs'
path    = require 'path'
R       = require 'ramda'
crypto  = require 'crypto'

class DigestManifest

  brunchPlugin: true

  constructor: (@config) ->
    @publicFolder   = @config.paths.public
    @sha1Level      = 6
    @manifestPath   = 'manifest.json'
    @manifest       = {}
    @options        = {}

  onCompile: ->

    compute = R.pipe(

      # '/relative/path/to/file.ext' => is a file ? '/relative/path/to/file.ext'
      R.filter(@isValidFile)

      # '/relative/path/to/file.ext' => {
      #   url: '/relative/path/to/file.ext',
      #   sha1: 'sha1xq0ds'
      # }
      R.map(@sha1Map)

      # {
      #   url: '/relative/path/to/file.ext',
      #   sha1: 'sha1xq0ds'
      # }
      # => {'/relative/path/to/file.ext' : '/relative/path/to/file.sha1xq0ds.ext'}
      R.map(@hashedFilePath)

      # store reference
      R.map(@storeInManifest)

      # Rename filename with hash
      R.map(@renameFile)

    )

    compute(glob.sync('**', { cwd: @publicFolder }))
    @writeManifest(@manifest)


  isValidFile: (url) => fs.statSync(path.resolve(@publicFolder, url)).isFile() and url isnt @manifestPath

  sha1Map: (url) =>
    data = fs.readFileSync path.resolve(@publicFolder, url)
    return {
      url: url
      sha1: crypto
        .createHash('sha1')
        .update(data)
        .digest('hex')[0..@sha1Level]
    }

  hashedFilePath: (spec) =>
    obj = {}
    addSha1 = (match) -> ".#{spec.sha1}#{match}"
    obj[spec.url] = spec.url.replace(/[.]\w*$/g, addSha1)
    obj


  storeInManifest: (spec) =>
    @manifest[Object.keys(spec)[0]] = spec[Object.keys(spec)[0]]
    spec

  writeManifest: (spec) =>
    fs.writeFileSync(
      path.resolve(@publicFolder, @manifestPath),
      JSON.stringify(spec),
      'utf8'
    )
    spec

  renameFile: (spec) =>
    fs.renameSync(
      path.resolve(@publicFolder, Object.keys(spec)[0]),
      path.resolve(@publicFolder, spec[Object.keys(spec)[0]])
    )
    spec


module.exports = DigestManifest
