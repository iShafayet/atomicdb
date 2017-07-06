
class Atomicdb

  @IdentifierPrefix = 'atomicdb-db-'

  @UniqueDocumentKey = '_id'

  constructor: (options = {})->

    {
      @name
      @storageEngine
      @serializationEngine
      @commitDelay
    } = options
    unless (@name and typeof @name is 'string')
      throw new Error "Expected 'name' of database"
    unless @storageEngine
      throw new Error "Expected 'storageEngine'"
    unless @serializationEngine
      throw new Error "Expected 'serializationEngine'"
    @commitDelay or= 'none'

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

    if @storageEngine.hasItem @databaseIdentifier
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
        meta: {}
      }
    return @database.collections[collectionName]



@Atomicdb = Atomicdb


