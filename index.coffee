
class Atomicdb

  @IdentifierPrefix = 'atomicdb-db-'

  @DefaultDocumentUniqueKey = '_id'

  constructor: (options = {})->
    {
      @name
      @storageEngine
      @serializationEngine
      @commitDelay
      @uniqueKey
      encryption
      @verbosity
    } = options
    unless (@name and typeof @name is 'string')
      throw new Error "Expected 'name' of database"
    unless @storageEngine
      throw new Error "Expected 'storageEngine'"
    unless @serializationEngine
      throw new Error "Expected 'serializationEngine'"
    @commitDelay or= 'none'
    @uniqueKey or= @constructor.DefaultDocumentUniqueKey
    encryption or= {}
    { engine: @encryptionEngine, @shouldEncryptWholeDatabase } = encryption
    @encryptionEngine or= null
    @shouldEncryptWholeDatabase or= false
    @verbosity or= 'error'
    unless @verbosity in [ 'error', 'all', 'none' ]
      throw new Error "Unexpected verbosity"

    @databaseIdentifier = @constructor.IdentifierPrefix + @name
    @database = null
    @definition = {}

    @_lastTimeoutId = null

  _saveDatabase: ->
    @database.lastSavedDatetimeStamp = (new Date).getTime()
    rawContent = (@serializationEngine.stringify @database)
    if @shouldEncryptWholeDatabase
      rawContent = @encryptionEngine.encrypt rawContent
    @storageEngine.setItem @databaseIdentifier, rawContent

  _createNewDatabase: ->
    @database = {} 
    @database.collections = {}
    datetimeStamp = (new Date).getTime()
    @database.createdDatetimeStamp = datetimeStamp
    @database.lastModifiedDatetimeStamp = datetimeStamp 
    @_saveDatabase()

  _loadExistingDatabase: ->
    rawContent = @storageEngine.getItem @databaseIdentifier
    if @shouldEncryptWholeDatabase
      try
        rawContent = @encryptionEngine.decrypt rawContent
      catch ex
        error = new Error "Database corrupted. Was unable to decrypt using given encryption.engine."
        if @verbosity in [ 'all', 'error' ]
          if console.error then console.error ex else console.log ex
        throw error
    try
      @database = @serializationEngine.parse rawContent
    catch ex
      error = new Error "Database corrupted. Was unable to parse using given serializationEngine."
      if @verbosity in [ 'all', 'error' ]
        if console.error then console.error ex else console.log ex
      throw error
      
    @_saveDatabase()

  removeExistingDatabase: ->
    @database = null
    @storageEngine.removeItem @databaseIdentifier

  initializeDatabase: (options = {})->
    { removeExisting } = options
    removeExisting or= false

    if @storageEngine.getItem @databaseIdentifier
      if removeExisting
        @removeExistingDatabase()
        return @_createNewDatabase()
      else
        return @_loadExistingDatabase()
    else
      return @_createNewDatabase()

  defineCollection: (options)->
    {
      name
      validatorFn
      shouldEncrypt
    } = options
    validatorFn or= null
    shouldEncrypt or= false

    @definition[name] = {
      name
      validatorFn
      shouldEncrypt
    }

  _getDefinition: (collectionName)->
    unless collectionName of @definition
      throw new Error "Unknown collection '#{collectionName}'"
    return @definition[collectionName]

  _encryptCollectionInPlace: (collection)->
    return unless collection.docList
    rawContent = @serializationEngine.stringify collection.docList
    collection.encryptedData = @encryptionEngine.encrypt rawContent
    delete collection.docList
    return undefined

  _decryptCollectionInPlace: (collection)->
    return unless collection.encryptedData
    rawContent = @encryptionEngine.decrypt collection.encryptedData
    collection.docList = @serializationEngine.parse rawContent
    delete collection.encryptedData
    return undefined

  _getCollection: (collectionName)->
    collectionDefinition = @_getDefinition collectionName
    unless collectionName of @database.collections
      @database.collections[collectionName] = {
        docList: []
        serialSeed: 0
      }
      if collectionDefinition.shouldEncrypt
        @_encryptCollectionInPlace @database.collections[collectionName]
    if collectionDefinition.shouldEncrypt
      @_decryptCollectionInPlace @database.collections[collectionName]
    return @database.collections[collectionName]

  _deepCopy: (doc)->
    @serializationEngine.parse @serializationEngine.stringify doc

  _notifyDatabaseChange: (type, collectionName, argList...)->
    collectionDefinition = @_getDefinition collectionName
    if collectionDefinition.shouldEncrypt
      @_encryptCollectionInPlace @_getCollection collectionName
    if @commitDelay is 'none'
      @_saveDatabase()
    else
      unless @alreadyCommitRequestPending
        @alreadyCommitRequestPending = true
        @_lastTimeoutId = setTimeout (=> 
          @_saveDatabase()
          @_lastTimeoutId = null
          @alreadyCommitRequestPending = false
        ), @commitDelay

  _setAtomicProperty: (doc, createdDatetimeStamp, lastModifiedDatetimeStamp)->
    Object.defineProperty doc, '__atomic__', { enumerable: false, value: {}, configurable: true, writable: true }
    doc.__atomic__.createdDatetimeStamp = createdDatetimeStamp
    doc.__atomic__.lastModifiedDatetimeStamp = lastModifiedDatetimeStamp

  insert: (collectionName, doc)->
    unless doc and typeof doc is 'object'
      throw new Error "doc must be a non-null 'object'"

    doc = @_deepCopy doc

    collectionDefinition = @_getDefinition collectionName

    if collectionDefinition.validatorFn
      if (error = validatorFn doc)
        throw error

    collection = @_getCollection collectionName

    doc[@uniqueKey] = collection.serialSeed
    collection.serialSeed += 1

    datetimeStamp = (new Date).getTime()
    @_setAtomicProperty doc, datetimeStamp, datetimeStamp

    collection.docList.push doc
    @_notifyDatabaseChange 'insert', collectionName, doc[@uniqueKey]

    return doc[@uniqueKey]

  find: (collectionName, filterFn = null)->
    collectionDefinition = @_getDefinition collectionName
    collection = @_getCollection collectionName

    matchedDocList = []
    for doc, index in collection.docList
      if filterFn
        unless filterFn doc
          continue
      matchedDocList.push @_deepCopy doc

    if collectionDefinition.shouldEncrypt
      @_encryptCollectionInPlace collection

    return matchedDocList

  update: (collectionName, selector, replacement)->
    @_getDefinition collectionName
    collection = @_getCollection collectionName

    updatedCount = 0
    for doc, index in collection.docList
      if (typeof selector) is 'function'
        unless selector doc
          continue
      else
        unless doc[@uniqueKey] is selector
          continue

      if (typeof replacement) is 'function'
        newDoc = replacement @_deepCopy doc
      else
        newDoc = @_deepCopy replacement
      unless newDoc and typeof newDoc is 'object'
        throw new Error "newDoc must be a non-null 'object'"

      newDoc[@uniqueKey] = doc[@uniqueKey]

      datetimeStamp = (new Date).getTime()
      @_setAtomicProperty newDoc, doc.__atomic__.createdDatetimeStamp, datetimeStamp

      collection.docList.splice index, 1, newDoc
      @_notifyDatabaseChange 'update', collectionName, newDoc[@uniqueKey]
      updatedCount += 1

    return updatedCount

  remove: (collectionName, selector)->
    @_getDefinition collectionName
    collection = @_getCollection collectionName

    indicesToRemove = []
    for doc, index in collection.docList
      if (typeof selector) is 'function'
        unless selector doc
          continue
      else
        unless doc[@uniqueKey] is selector
          continue
      indicesToRemove.push index
    
    indicesToRemove.reverse()
    for indexToRemove, index in indicesToRemove
      collection.docList.splice indexToRemove, 1

    @_notifyDatabaseChange 'remove', collectionName, indicesToRemove.length

    return indicesToRemove.length

  upsert: (collectionName, selector, replacement, newDoc)->
    updatedCount = @update collectionName, selector, replacement
    if updatedCount > 0
      return [ updatedCount ]
    return [ 0, (@insert collectionName, newDoc) ]

  computeTotalSpaceTaken: ->
    return (@storageEngine.getItem @databaseIdentifier).length

  getCollectionNameList: ->
    return Object.keys(@definition)
  
  safelyCloseDatabase: ->
    if @_lastTimeoutId isnt null
      clearTimeout @_lastTimeoutId
    @_saveDatabase()

@Atomicdb = Atomicdb


