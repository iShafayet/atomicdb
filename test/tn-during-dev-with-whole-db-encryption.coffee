
{ expect, assert } = require('chai')

{ Atomicdb } = require './../index.coffee'

describe 'atomicdb', ->

  it 'During Dev - with whole db encryption', ->

    { LocalStorage } = require('node-localstorage')
    localStorage = new LocalStorage('./scratch.temp')  
    localStorage.clear()

    crypto = require('crypto')
    algorithm = 'aes-256-ctr'
    password = 'd6F3Efeq'

    encryptionEngine = 
      encrypt: (text) ->
        cipher = crypto.createCipher(algorithm, password)
        crypted = cipher.update(text, 'utf8', 'hex')
        crypted += cipher.final('hex')
        return crypted
      
      decrypt: (text) ->
        decipher = crypto.createDecipher(algorithm, password)
        dec = decipher.update(text, 'hex', 'utf8')
        dec += decipher.final('utf8')
        return dec

    db = new Atomicdb {
      name: 'test-db'
      storageEngine: localStorage
      serializationEngine: JSON
      encryption: 
        engine: encryptionEngine
        shouldEncryptWholeDatabase: true
      commitDelay: 'none'
      uniqueKey: '_aid'
    }

    db.initializeDatabase()

    db.defineCollection {
      name: 'user'
    }

    id1 = db.insert 'user', {
      name: 'Charles'
      age: 30
    }

    id2 = db.insert 'user', {
      name: 'Curl'
      age: 50
    }

    list = db.find 'user'

    expect(list).to.deep.equal [
      {
        _aid: id1
        name: 'Charles'
        age: 30
      },
      {
        _aid: id2
        name: 'Curl'
        age: 50
      }
    ]

    db = new Atomicdb {
      name: 'test-db'
      storageEngine: localStorage
      serializationEngine: JSON
      encryption: 
        engine: encryptionEngine
        shouldEncryptWholeDatabase: true
      commitDelay: 'none'
      uniqueKey: '_aid'
    }

    db.initializeDatabase()

    db.defineCollection {
      name: 'user'
    }

    list = db.find 'user'

    expect(list).to.deep.equal [
      {
        _aid: id1
        name: 'Charles'
        age: 30
      },
      {
        _aid: id2
        name: 'Curl'
        age: 50
      }
    ]

    db = new Atomicdb {
      name: 'test-db'
      storageEngine: localStorage
      serializationEngine: JSON
      encryption: 
        engine: encryptionEngine
        shouldEncryptWholeDatabase: false
      commitDelay: 'none'
      uniqueKey: '_aid'
      verbosity: 'none'
    }

    expect(=> db.initializeDatabase()).to.throw('Database corrupted. Was unable to parse using given serializationEngine.')
