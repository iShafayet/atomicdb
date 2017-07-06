window['atomicdb'] = {};

(function() {
  var Atomicdb,
    slice = [].slice;

  Atomicdb = (function() {
    Atomicdb.IdentifierPrefix = 'atomicdb-db-';

    Atomicdb.DefaultDocumentUniqueKey = '_id';

    function Atomicdb(options) {
      if (options == null) {
        options = {};
      }
      this.name = options.name, this.storageEngine = options.storageEngine, this.serializationEngine = options.serializationEngine, this.commitDelay = options.commitDelay, this.uniqueKey = options.uniqueKey;
      if (!(this.name && typeof this.name === 'string')) {
        throw new Error("Expected 'name' of database");
      }
      if (!this.storageEngine) {
        throw new Error("Expected 'storageEngine'");
      }
      if (!this.serializationEngine) {
        throw new Error("Expected 'serializationEngine'");
      }
      this.commitDelay || (this.commitDelay = 'none');
      this.uniqueKey || (this.uniqueKey = this.constructor.DefaultDocumentUniqueKey);
      this.databaseIdentifier = this.constructor.IdentifierPrefix + this.name;
      this.database = null;
      this.definition = {};
    }

    Atomicdb.prototype._saveDatabase = function() {
      this.database.lastSavedDatetimeStamp = (new Date).getTime();
      return this.storageEngine.setItem(this.databaseIdentifier, this.serializationEngine.stringify(this.database));
    };

    Atomicdb.prototype._createNewDatabase = function() {
      var datetimeStamp;
      this.database = {};
      this.database.collections = {};
      datetimeStamp = (new Date).getTime();
      this.database.createdDatetimeStamp = datetimeStamp;
      this.database.lastModifiedDatetimeStamp = datetimeStamp;
      return this._saveDatabase();
    };

    Atomicdb.prototype._loadExistingDatabase = function() {
      this.database = this.serializationEngine.parse(this.storageEngine.getItem(this.databaseIdentifier));
      return this._saveDatabase();
    };

    Atomicdb.prototype.removeExistingDatabase = function() {
      this.database = null;
      return this.storageEngine.removeItem(this.databaseIdentifier);
    };

    Atomicdb.prototype.initializeDatabase = function(options) {
      var removeExisting;
      if (options == null) {
        options = {};
      }
      removeExisting = options.removeExisting;
      removeExisting || (removeExisting = false);
      if (this.storageEngine.getItem(this.databaseIdentifier)) {
        if (removeExisting) {
          this.removeExistingDatabase();
          return this._createNewDatabase();
        } else {
          return this._loadExistingDatabase();
        }
      } else {
        return this._createNewDatabase();
      }
    };

    Atomicdb.prototype.defineCollection = function(options) {
      var name, validatorFn;
      name = options.name, validatorFn = options.validatorFn;
      validatorFn || (validatorFn = null);
      return this.definition[name] = {
        name: name,
        validatorFn: validatorFn
      };
    };

    Atomicdb.prototype._getDefinition = function(collectionName) {
      if (!(collectionName in this.definition)) {
        throw new Error("Unknown collection '" + collectionName + "'");
      }
      return this.definition[collectionName];
    };

    Atomicdb.prototype._getCollection = function(collectionName) {
      if (!(collectionName in this.database.collections)) {
        this.database.collections[collectionName] = {
          docList: [],
          serialSeed: 0
        };
      }
      return this.database.collections[collectionName];
    };

    Atomicdb.prototype._deepCopy = function(doc) {
      return this.serializationEngine.parse(this.serializationEngine.stringify(doc));
    };

    Atomicdb.prototype._notifyDatabaseChange = function() {
      var argList, type;
      type = arguments[0], argList = 2 <= arguments.length ? slice.call(arguments, 1) : [];
      if (this.commitDelay === 'none') {
        return this._saveDatabase();
      } else {
        if (!this.alreadyCommitRequestPending) {
          this.alreadyCommitRequestPending = true;
          return setTimeout(((function(_this) {
            return function() {
              _this._saveDatabase();
              return _this.alreadyCommitRequestPending = false;
            };
          })(this)), this.commitDelay);
        }
      }
    };

    Atomicdb.prototype.insert = function(collectionName, doc) {
      var collection, collectionDefinition, error;
      if (!(doc && typeof doc === 'object')) {
        throw new Error("doc must be a non-null 'object'");
      }
      doc = this._deepCopy(doc);
      collectionDefinition = this._getDefinition(collectionName);
      if (collectionDefinition.validatorFn) {
        if ((error = validatorFn(doc))) {
          throw error;
        }
      }
      collection = this._getCollection(collectionName);
      doc[this.uniqueKey] = collection.serialSeed;
      collection.serialSeed += 1;
      collection.docList.push(doc);
      this._notifyDatabaseChange('insert', collectionName, doc[this.uniqueKey]);
      return doc[this.uniqueKey];
    };

    Atomicdb.prototype.find = function(collectionName, filterFn) {
      var collection, doc, i, index, len, matchedDocList, ref;
      if (filterFn == null) {
        filterFn = null;
      }
      this._getDefinition(collectionName);
      collection = this._getCollection(collectionName);
      matchedDocList = [];
      ref = collection.docList;
      for (index = i = 0, len = ref.length; i < len; index = ++i) {
        doc = ref[index];
        if (filterFn) {
          if (!filterFn(doc)) {
            continue;
          }
        }
        matchedDocList.push(this._deepCopy(doc));
      }
      return matchedDocList;
    };

    Atomicdb.prototype.update = function(collectionName, selector, replacement) {
      var collection, doc, i, index, len, newDoc, ref, updatedCount;
      this._getDefinition(collectionName);
      collection = this._getCollection(collectionName);
      updatedCount = 0;
      ref = collection.docList;
      for (index = i = 0, len = ref.length; i < len; index = ++i) {
        doc = ref[index];
        if ((typeof selector) === 'function') {
          if (!selector(doc)) {
            continue;
          }
        } else {
          if (doc[this.uniqueKey] !== selector) {
            continue;
          }
        }
        if ((typeof replacement) === 'function') {
          newDoc = replacement(this._deepCopy(doc));
        } else {
          newDoc = this._deepCopy(replacement);
        }
        if (!(newDoc && typeof newDoc === 'object')) {
          throw new Error("newDoc must be a non-null 'object'");
        }
        newDoc[this.uniqueKey] = doc[this.uniqueKey];
        collection.docList.splice(index, 1, newDoc);
        this._notifyDatabaseChange('update', collectionName, newDoc[this.uniqueKey]);
        updatedCount += 1;
      }
      return updatedCount;
    };

    Atomicdb.prototype.remove = function(collectionName, selector) {
      var collection, doc, i, index, indexToRemove, indicesToRemove, j, len, len1, ref;
      this._getDefinition(collectionName);
      collection = this._getCollection(collectionName);
      indicesToRemove = [];
      ref = collection.docList;
      for (index = i = 0, len = ref.length; i < len; index = ++i) {
        doc = ref[index];
        if ((typeof selector) === 'function') {
          if (!selector(doc)) {
            continue;
          }
        } else {
          if (doc[this.uniqueKey] !== selector) {
            continue;
          }
        }
        indicesToRemove.push(index);
      }
      indicesToRemove.reverse();
      for (index = j = 0, len1 = indicesToRemove.length; j < len1; index = ++j) {
        indexToRemove = indicesToRemove[index];
        collection.docList.splice(indexToRemove, 1);
      }
      this._notifyDatabaseChange('remove', collectionName, indicesToRemove.length);
      return indicesToRemove.length;
    };

    Atomicdb.prototype.upsert = function(collectionName, selector, replacement, newDoc) {
      var updatedCount;
      updatedCount = this.update(collectionName, selector, replacement);
      if (updatedCount > 0) {
        return [updatedCount];
      }
      return [0, this.insert(collectionName, newDoc)];
    };

    Atomicdb.prototype.computeTotalSpaceTaken = function() {
      return (this.storageEngine.getItem(this.databaseIdentifier)).length;
    };

    Atomicdb.prototype.getCollectionNameList = function() {
      return Object.keys(this.definition);
    };

    return Atomicdb;

  })();

  this.Atomicdb = Atomicdb;

}).call(window['atomicdb']);

