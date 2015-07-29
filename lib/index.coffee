glob          = require 'glob'
fs            = require 'fs'
path          = require 'path'
R             = require 'ramda'
crypto        = require 'crypto'

class DigestManifest

  brunchPlugin: true

  constructor: (@config) ->
    @defaultEnv     = 'production'            # hash task is only activated for a production build
    @publicFolder   = @config.paths.public    # manifest will be placed in the `public` folder
    @sha1Level      = 6                       # sha1 precision level, 6 seems fair
    @manifestPath   = 'manifest.json'         # hashed resources manifest will be placed at the root of `public` folder

  onCompile: ->

    g = glob.sync('**', cwd: @publicFolder )

    i = R.pipe(
      R.filter  @isValidFile
      R.filter  @isImmutableStaticFile
      R.map     @hashedFilePath
      R.forEach @createHashedFile
      R.mergeAll
    )

    m = (immutablesList) =>
      R.pipe(
        R.filter  @isValidFile                  # 's' -> true|false
        R.filter  @isMutableStaticFile          # filter on .js and .css files only
        R.forEach @replaceHashedImmutableRefs(immutablesList) # search and replace
        R.map     @hashedFilePath               # 's' -> {'s' : 'h'}
        R.forEach @createHashedFile             # {a} -> {a}
        R.mergeAll                              # merge all references into a single object
      )

    I = i(g)                                    # immutable resources list+hashing and map
    M = m(I)(g)                                 # mutable resources list+hashing and map

    @writeManifest R.mergeAll([I, M])           # output all hashed resources map

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
  # Returns `true` if given extension is js or css
  #
  # @param {String} url
  # @return {Boolean} valid file
  #
  # '/relative/path/to/file.ext' -> (is a js or css file) ? '/relative/path/to/file.ext'
  ###
  isMutableStaticFile: (url) =>
    ext = path.extname(url)
    ['.js', '.css'].indexOf(ext) > -1

  ###
  # Returns `true` if given extension is an image or a font
  #
  # @param {String} url
  # @return {Boolean} valid file
  #
  # '/relative/path/to/file.ext' -> (is image or font) ? '/relative/path/to/file.ext'
  ###
  isImmutableStaticFile: (url) =>
    ext = path.extname(url)
    ['.png', '.jpg', '.jpeg', '.svg', '.eot', '.ttf', '.woff'].indexOf(ext) > -1

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
  # Creates a hashed version of a file given file
  #
  # @param {Object} file spec
  # @return {Object} same file spec
  ###
  createHashedFile: (spec) =>
    key = Object.keys(spec)[0]
    fs
      .createReadStream(@normalizeUrl key)
      .pipe fs.createWriteStream(@normalizeUrl spec[key])


  ###
  #
  #
  #
  #
  ###
  replaceHashedImmutableRefs: (immutableStaticFilesMap) => (url) =>

    fileContent = fs.readFileSync(@normalizeUrl(url), 'utf8')

    R.mapObjIndexed(
      (num, key, spec) ->
        fileContent = fileContent.replace(key, spec[key])
      immutableStaticFilesMap
    )

    fs.writeFileSync(@normalizeUrl(url), fileContent, 'utf8')


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
