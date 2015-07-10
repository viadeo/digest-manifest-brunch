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
      R.filter  @isValidFile                  # 's' -> true|false
      R.map     @hashedFilePath               # 's' -> {'s' : 'h'}
      R.forEach @renameFile                   # {a} -> {a}
      R.mergeAll                              # merge all references into a single object
    )
    @writeManifest compute( glob.sync('**', cwd: @publicFolder ) )

  ###
  # Returns an url relative to public folder
  #
  # @param {String} url
  # @return {String} normalized url
  ###
  normalizeUrl: (url) => path.resolve(@publicFolder, url)

  ###
  # Returns `true` if given url references a file
  # that is not the manifest itself
  #
  # @param {String} url
  # @return {Boolean} valid file
  #
  # '/relative/path/to/file.ext' -> (is a file) ? '/relative/path/to/file.ext'
  ###
  isValidFile: (url) => fs.statSync( @normalizeUrl url ).isFile() and url isnt @manifestPath

  ###
  # Returns an object describing the link between a resource path
  # and its hashed counterpart
  #
  # @param {String} url
  # @return {Object}
  #
  # '/relative/path/to/file.ext' -> {'/relative/path/to/file.ext' : '/relative/path/to/file.sha1xq0ds.ext'}
  ###
  hashedFilePath: (url) =>
    obj = {}
    data = fs.readFileSync @normalizeUrl(url)
    sha1 = crypto.createHash('sha1').update(data).digest('hex')[0..@sha1Level]
    obj[url] = url.replace(/[.]\w*$/g, (match) -> ".#{sha1}#{match}")
    obj

  ###
  # Renames a file into its hashed counterpart
  #
  # @param {Object} file spec
  # @return {Object} same file spec
  ###
  renameFile: (spec) =>
    key = Object.keys(spec)[0]
    fs.rename(
      @normalizeUrl key
      @normalizeUrl spec[key]
    )

  ###
  # Writes with json format the hash map description object
  # into a file
  #
  # @param {Object} files hash map
  # @return undefined
  ###
  writeManifest: (references) =>
    fs.writeFileSync(
      @normalizeUrl @manifestPath
      JSON.stringify references
      'utf8'
    )

module.exports = DigestManifest
