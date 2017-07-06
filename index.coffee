
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


@Atomicdb = Atomicdb


