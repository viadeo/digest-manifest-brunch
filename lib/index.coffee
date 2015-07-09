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

  onCompile: ->

    compute = R.pipe(

      # '/relative/path/to/file.ext' -> (is a file) ? '/relative/path/to/file.ext'
      # 's' -> ?'s'
      R.filter(@isValidFile)

      # '/relative/path/to/file.ext' -> {'/relative/path/to/file.ext' : '/relative/path/to/file.sha1xq0ds.ext'}
      # 's' -> {'s' : 'h'}
      R.map(@hashedFilePath)

      # Rename filename with hash
      # {a} -> {a}
      R.map(@renameFile)

      # merge all references into a single object
      R.mergeAll

    )

    @writeManifest(compute(glob.sync('**', { cwd: @publicFolder })))


  isValidFile: (url) => fs.statSync(path.resolve(@publicFolder, url)).isFile() and url isnt @manifestPath

  hashedFilePath: (url) =>
    obj = {}
    data = fs.readFileSync path.resolve(@publicFolder, url)
    sha1 = crypto
      .createHash('sha1')
      .update(data)
      .digest('hex')[0..@sha1Level]
    addSha1 = (match) -> ".#{sha1}#{match}"
    obj[url] = url.replace(/[.]\w*$/g, addSha1)
    return obj

  renameFile: (spec) =>
    key = Object.keys(spec)[0]
    fs.renameSync(
      path.resolve(@publicFolder, key),
      path.resolve(@publicFolder, spec[key])
    )
    return spec

  writeManifest: (spec) =>
    fs.writeFileSync(
      path.resolve(@publicFolder, @manifestPath),
      JSON.stringify(spec),
      'utf8'
    )

module.exports = DigestManifest
