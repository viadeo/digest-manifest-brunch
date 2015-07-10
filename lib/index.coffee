glob    = require 'glob'
fs      = require 'fs'
path    = require 'path'
R       = require 'ramda'
crypto  = require 'crypto'

class DigestManifest

  brunchPlugin: true

  constructor: (@config) ->
    @defaultEnv     = 'production'            # hash task is only activated for a production build
    @publicFolder   = @config.paths.public    # manifest will be placed in the `public` folder
    @sha1Level      = 6                       # sha1 precision level, 6 seems fair
    @manifestPath   = 'manifest.json'         # hashed resources manifest will be placed at the root of `public` folder

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


  normalizeUrl: (url) => path.resolve(@publicFolder, url)

  isValidFile: (url) => fs.statSync(@normalizeUrl(url)).isFile() and url isnt @manifestPath

  hashedFilePath: (url) =>
    obj = {}
    data = fs.readFileSync @normalizeUrl(url)
    sha1 = crypto.createHash('sha1').update(data).digest('hex')[0..@sha1Level]
    addSha1 = (match) -> ".#{sha1}#{match}"
    obj[url] = url.replace(/[.]\w*$/g, addSha1)
    return obj

  renameFile: (spec) =>
    key = Object.keys(spec)[0]
    fs.rename(@normalizeUrl(key), @normalizeUrl(spec[key]))
    return spec

  writeManifest: (spec) => fs.writeFileSync(@normalizeUrl(@manifestPath), JSON.stringify(spec), 'utf8')

module.exports = DigestManifest
