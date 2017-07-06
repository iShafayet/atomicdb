
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

    id1 = db.insert 'user', {
      name: 'Charles'
      age: 30
    }

    expect(db.database.collections.user.docList).to.deep.equal [{
      _aid: id1
      name: 'Charles'
      age: 30
    }]

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

    list = db.find 'user', ({age})-> age > 40

    expect(list).to.deep.equal [
      {
        _aid: id2
        name: 'Curl'
        age: 50
      }
    ]

    
