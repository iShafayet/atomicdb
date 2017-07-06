
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
    } = options
    unless (@name and typeof @name is 'string')
      throw new Error "Expected 'name' of database"
    unless @storageEngine
      throw new Error "Expected 'storageEngine'"
    unless @serializationEngine
      throw new Error "Expected 'serializationEngine'"
    @commitDelay or= 'none'
    @uniqueKey or= @constructor.DefaultDocumentUniqueKey

    @databaseIdentifier = @constructor.IdentifierPrefix + @name
    @database = null
    @definition = {}

  _saveDatabase: ->
    @database.lastSavedDatetimeStamp = (new Date).getTime()
    @storageEngine.setItem @databaseIdentifier, (@serializationEngine.stringify @database)

  _createNewDatabase: ->
    @database = {} 
    @database.collections = {}
    datetimeStamp = (new Date).getTime()
    @database.createdDatetimeStamp = datetimeStamp
    @database.lastModifiedDatetimeStamp = datetimeStamp 
    @_saveDatabase()

  _loadExistingDatabase: ->
    @database = @serializationEngine.parse @storageEngine.getItem @databaseIdentifier
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
    } = options
    validatorFn or= null

    @definition[name] = {
      name
      validatorFn
    }

  _getDefinition: (collectionName)->
    unless collectionName of @definition
      throw new Error "Unknown collection '#{collectionName}'"
    return @definition[collectionName]

  _getCollection: (collectionName)->
    unless collectionName of @database.collections
      @database.collections[collectionName] = {
        docList: []
        serialSeed: 0
      }
    return @database.collections[collectionName]

  _deepCopy: (doc)->
    @serializationEngine.parse @serializationEngine.stringify doc

  _notifyDatabaseChange: (type, argList...)->
    ## TODO Factor in @options.commitDelay
    @_saveDatabase()

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

    collection.docList.push doc
    @_notifyDatabaseChange 'insert', collectionName, doc[@uniqueKey]

    return doc[@uniqueKey]

  find: (collectionName, filterFn = null)->
    @_getDefinition collectionName
    collection = @_getCollection collectionName

    matchedDocList = []
    for doc, index in collection.docList
      if filterFn
        unless filterFn doc
          continue
      matchedDocList.push @_deepCopy doc

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

@Atomicdb = Atomicdb


