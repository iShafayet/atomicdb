
{ expect, assert } = require('chai')

{ Atomicdb } = require './../index.coffee'

describe 'atomicdb', ->

  it 'During Dev - with collection level encryption', ->

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
        shouldEncryptWholeDatabase: false
      commitDelay: 'none'
      uniqueKey: '_aid'
    }

    db.initializeDatabase()

    db.defineCollection {
      name: 'user'
      shouldEncrypt: true
    }


    db.defineCollection {
      name: 'unencryptedUser'
      shouldEncrypt: false
    }

    id1 = db.insert 'user', {
      name: 'Charles'
      age: 30
    }

    id2 = db.insert 'user', {
      name: 'Curl'
      age: 50
    }

    id1a = db.insert 'unencryptedUser', {
      name: 'Charles'
      age: 30
    }

    id2a = db.insert 'unencryptedUser', {
      name: 'Curl'
      age: 50
    }

    expect(db.database.collections.user).to.have.property('encryptedData')
    expect(db.database.collections.user).to.not.have.property('docList')

    list = db.find 'user'

    expect(db.database.collections.user).to.have.property('encryptedData')
    expect(db.database.collections.user).to.not.have.property('docList')

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

    expect(db.database.collections.unencryptedUser).to.not.have.property('encryptedData')
    expect(db.database.collections.unencryptedUser).to.have.property('docList')

    list = db.find 'unencryptedUser'

    expect(db.database.collections.unencryptedUser).to.not.have.property('encryptedData')
    expect(db.database.collections.unencryptedUser).to.have.property('docList')

    expect(list).to.deep.equal [
      {
        _aid: id1a
        name: 'Charles'
        age: 30
      },
      {
        _aid: id2a
        name: 'Curl'
        age: 50
      }
    ]
    