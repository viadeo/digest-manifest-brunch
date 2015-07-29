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

    hashAndMap = R.pipe(
      R.map     @hashedFilePath               # 's' -> {'s' : 'h'}
      R.forEach @createHashedFile             # {a} -> {a}
      R.mergeAll                              # [{a}, {a}, ...] -> {A} # merge all references into a single object
    )

    # valid public folder filetree list
    g = R.filter(@isValidFile, glob.sync('**', cwd: @publicFolder ))

    # static resources list transformation pipeline
    staticP = R.pipe(
      R.filter  @isStaticResource
      hashAndMap
    )

    # script resources list transformation pipeline
    scriptP = (staticsList) =>
      R.pipe(
        R.filter  @isScriptResource           # filter on .js and .css files only
        R.forEach @replaceRefs(staticsList)   # search and replace
        hashAndMap
      )

    staticR = staticP(g)                      # static resources list+hashing and map
    scriptR = scriptP(staticR)(g)             # script resources list+hashing and map

    # output all hashed resources map
    @writeManifest R.mergeAll([staticR, scriptR])

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
  isScriptResource: (url) =>
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
  isStaticResource: (url) =>
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
  ###
  replaceRefs: (staticFilesMap) => (url) =>

    fileContent = fs.readFileSync(@normalizeUrl(url), 'utf8')

    R.mapObjIndexed(
      (num, key, spec) ->
        fileContent = fileContent.replace(key, spec[key])
      staticFilesMap
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
