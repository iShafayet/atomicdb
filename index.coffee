
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

    return doc[@uniqueKey]

@Atomicdb = Atomicdb


