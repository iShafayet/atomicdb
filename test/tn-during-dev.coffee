
{ expect, assert } = require('chai')

{ Atomicdb } = require './../index.coffee'

describe 'atomicdb', ->

  it 'Generic', ->

    { LocalStorage } = require('node-localstorage')
    localStorage = new LocalStorage('./scratch.temp')  

    db = new Atomicdb {
      name: 'test-db'
      storageEngine: localStorage
      serializationEngine: JSON
      commitDelay: 'none'
      uniqueKey: '_aid'
    }

    db.initializeDatabase()

    db.defineCollection {
      name: 'user'
    }

    id = db.insert 'user', {
      name: 'Charles'
      age: 30
    }

    expect(db.database.collections.user.docList).to.deep.equal [{
      _aid: id
      name: 'Charles'
      age: 30
    }]
