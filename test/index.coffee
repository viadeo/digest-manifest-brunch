expect = require('chai').expect
DigestManifest = require '../lib'

describe 'DigestManifest', ->

  digest = undefined

  beforeEach ->
    digest = new DigestManifest(
      paths: public: 'test/fixtures'
    )

  describe 'normalizeUrl method', ->

    it 'normalizes passed url with given public folder', ->
      expect(digest.normalizeUrl 'stuff.js').to.eql "#{ process.cwd() }/test/fixtures/stuff.js"

  describe 'isValidFile method', ->

    it 'returns true if given path is a file and isn\'t in manifest.json path', ->
      expect(digest.isValidFile 'file.js').to.be.true
      expect(digest.isValidFile 'manifest.json').to.be.false
      expect(digest.isValidFile 'folder/').to.be.false

  describe 'isScriptResource method', ->

    it 'returns true when filename has a script extension', ->
      expect(digest.isScriptResource 'file.js').to.be.true
      expect(digest.isScriptResource 'file.css').to.be.true
      expect(digest.isScriptResource 'manifest.json').to.be.false
      expect(digest.isScriptResource 'file.png').to.be.false

  describe 'isStaticResource method', ->

    it 'returns true when filename has a static resource extension', ->
      expect(digest.isStaticResource 'file.js').to.be.false
      expect(digest.isStaticResource 'file.css').to.be.false
      expect(digest.isStaticResource 'manifest.json').to.be.false
      expect(digest.isStaticResource 'file.png').to.be.true

  describe 'hashFilePath method', ->

    it 'returns hash map of given file url', ->
      expect(digest.hashFilePath 'file.js').to.deep.equal(
        'file.js': 'file.da39a3e.js'
      )
