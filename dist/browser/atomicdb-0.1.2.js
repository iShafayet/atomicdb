window['atomicdb'] = {};

(function() {
  var Atomicdb,
    slice = [].slice,
    indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  Atomicdb = (function() {
    Atomicdb.IdentifierPrefix = 'atomicdb-db-';

    Atomicdb.DefaultDocumentUniqueKey = '_id';

    function Atomicdb(options) {
      var encryption, ref;
      if (options == null) {
        options = {};
      }
      this.name = options.name, this.storageEngine = options.storageEngine, this.serializationEngine = options.serializationEngine, this.commitDelay = options.commitDelay, this.uniqueKey = options.uniqueKey, encryption = options.encryption, this.verbosity = options.verbosity;
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
      encryption || (encryption = {});
      this.encryptionEngine = encryption.engine, this.shouldEncryptWholeDatabase = encryption.shouldEncryptWholeDatabase;
      this.encryptionEngine || (this.encryptionEngine = null);
      this.shouldEncryptWholeDatabase || (this.shouldEncryptWholeDatabase = false);
      this.verbosity || (this.verbosity = 'error');
      if ((ref = this.verbosity) !== 'error' && ref !== 'all' && ref !== 'none') {
        throw new Error("Unexpected verbosity");
      }
      this.databaseIdentifier = this.constructor.IdentifierPrefix + this.name;
      this.database = null;
      this.definition = {};
      this._lastTimeoutId = null;
      this._collectionObserverMap = {};
    }

    Atomicdb.prototype._saveDatabase = function() {
      var rawContent;
      this.database.lastSavedDatetimeStamp = (new Date).getTime();
      rawContent = this.serializationEngine.stringify(this.database);
      if (this.shouldEncryptWholeDatabase) {
        rawContent = this.encryptionEngine.encrypt(rawContent);
      }
      return this.storageEngine.setItem(this.databaseIdentifier, rawContent);
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
      var error, ex, rawContent, ref, ref1;
      rawContent = this.storageEngine.getItem(this.databaseIdentifier);
      if (this.shouldEncryptWholeDatabase) {
        try {
          rawContent = this.encryptionEngine.decrypt(rawContent);
        } catch (error1) {
          ex = error1;
          error = new Error("Database corrupted. Was unable to decrypt using given encryption.engine.");
          if ((ref = this.verbosity) === 'all' || ref === 'error') {
            if (console.error) {
              console.error(ex);
            } else {
              console.log(ex);
            }
          }
          throw error;
        }
      }
      try {
        this.database = this.serializationEngine.parse(rawContent);
      } catch (error1) {
        ex = error1;
        error = new Error("Database corrupted. Was unable to parse using given serializationEngine.");
        if ((ref1 = this.verbosity) === 'all' || ref1 === 'error') {
          if (console.error) {
            console.error(ex);
          } else {
            console.log(ex);
          }
        }
        throw error;
      }
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
      var name, shouldEncrypt, validatorFn;
      name = options.name, validatorFn = options.validatorFn, shouldEncrypt = options.shouldEncrypt;
      validatorFn || (validatorFn = null);
      shouldEncrypt || (shouldEncrypt = false);
      return this.definition[name] = {
        name: name,
        validatorFn: validatorFn,
        shouldEncrypt: shouldEncrypt
      };
    };

    Atomicdb.prototype._getDefinition = function(collectionName) {
      if (!(collectionName in this.definition)) {
        throw new Error("Unknown collection '" + collectionName + "'");
      }
      return this.definition[collectionName];
    };

    Atomicdb.prototype._encryptCollectionInPlace = function(collection) {
      var rawContent;
      if (!collection.docList) {
        return;
      }
      rawContent = this.serializationEngine.stringify(collection.docList);
      collection.encryptedData = this.encryptionEngine.encrypt(rawContent);
      delete collection.docList;
      return void 0;
    };

    Atomicdb.prototype._decryptCollectionInPlace = function(collection) {
      var rawContent;
      if (!collection.encryptedData) {
        return;
      }
      rawContent = this.encryptionEngine.decrypt(collection.encryptedData);
      collection.docList = this.serializationEngine.parse(rawContent);
      delete collection.encryptedData;
      return void 0;
    };

    Atomicdb.prototype._getCollection = function(collectionName) {
      var collectionDefinition;
      collectionDefinition = this._getDefinition(collectionName);
      if (!(collectionName in this.database.collections)) {
        this.database.collections[collectionName] = {
          docList: [],
          serialSeed: 0
        };
        if (collectionDefinition.shouldEncrypt) {
          this._encryptCollectionInPlace(this.database.collections[collectionName]);
        }
      }
      if (collectionDefinition.shouldEncrypt) {
        this._decryptCollectionInPlace(this.database.collections[collectionName]);
      }
      return this.database.collections[collectionName];
    };

    Atomicdb.prototype._deepCopy = function(doc) {
      return this.serializationEngine.parse(this.serializationEngine.stringify(doc));
    };

    Atomicdb.prototype._notifyDatabaseChange = function() {
      var argList, collectionDefinition, collectionName, fn, i, len, ref, type;
      type = arguments[0], collectionName = arguments[1], argList = 3 <= arguments.length ? slice.call(arguments, 2) : [];
      collectionDefinition = this._getDefinition(collectionName);
      if (collectionDefinition.shouldEncrypt) {
        this._encryptCollectionInPlace(this._getCollection(collectionName));
      }
      if (collectionName in this._collectionObserverMap) {
        ref = this._collectionObserverMap[collectionName];
        for (i = 0, len = ref.length; i < len; i++) {
          fn = ref[i];
          fn.apply(null, [type].concat(argList));
        }
      }
      if (this.commitDelay === 'none') {
        return this._saveDatabase();
      } else {
        if (!this.alreadyCommitRequestPending) {
          this.alreadyCommitRequestPending = true;
          return this._lastTimeoutId = setTimeout(((function(_this) {
            return function() {
              _this._saveDatabase();
              _this._lastTimeoutId = null;
              return _this.alreadyCommitRequestPending = false;
            };
          })(this)), this.commitDelay);
        }
      }
    };

    Atomicdb.prototype._setAtomicProperty = function(doc, createdDatetimeStamp, lastModifiedDatetimeStamp) {
      Object.defineProperty(doc, '__atomic__', {
        enumerable: false,
        value: {},
        configurable: true,
        writable: true
      });
      doc.__atomic__.createdDatetimeStamp = createdDatetimeStamp;
      return doc.__atomic__.lastModifiedDatetimeStamp = lastModifiedDatetimeStamp;
    };

    Atomicdb.prototype.observe = function(collectionName, fn) {
      if (!(collectionName in this._collectionObserverMap)) {
        this._collectionObserverMap[collectionName] = [];
      }
      if (indexOf.call(this._collectionObserverMap[collectionName], fn) < 0) {
        return this._collectionObserverMap[collectionName].push(fn);
      }
    };

    Atomicdb.prototype.unobserve = function(collectionName, fn) {
      var index;
      if (!(collectionName in this._collectionObserverMap)) {
        return;
      }
      if ((index = this._collectionObserverMap[collectionName].indexOf(fn)) > -1) {
        return this._collectionObserverMap[collectionName].splice(index, 1);
      }
    };

    Atomicdb.prototype.insert = function(collectionName, doc) {
      var collection, collectionDefinition, datetimeStamp, error;
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
      datetimeStamp = (new Date).getTime();
      this._setAtomicProperty(doc, datetimeStamp, datetimeStamp);
      collection.docList.push(doc);
      this._notifyDatabaseChange('insert', collectionName, doc[this.uniqueKey]);
      return doc[this.uniqueKey];
    };

    Atomicdb.prototype.find = function(collectionName, filterFn) {
      var collection, collectionDefinition, doc, i, index, len, matchedDocList, ref;
      if (filterFn == null) {
        filterFn = null;
      }
      collectionDefinition = this._getDefinition(collectionName);
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
      if (collectionDefinition.shouldEncrypt) {
        this._encryptCollectionInPlace(collection);
      }
      return matchedDocList;
    };

    Atomicdb.prototype.update = function(collectionName, selector, replacement) {
      var collection, datetimeStamp, doc, i, index, len, newDoc, ref, updatedCount;
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
        datetimeStamp = (new Date).getTime();
        this._setAtomicProperty(newDoc, doc.__atomic__.createdDatetimeStamp, datetimeStamp);
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
        this._notifyDatabaseChange('remove', collectionName, indexToRemove);
      }
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

    Atomicdb.prototype.safelyCloseDatabase = function() {
      if (this._lastTimeoutId !== null) {
        clearTimeout(this._lastTimeoutId);
      }
      return this._saveDatabase();
    };

    return Atomicdb;

  })();

  this.Atomicdb = Atomicdb;

}).call(window['atomicdb']);

