
{ expect, assert } = require('chai')

{ Atomicdb } = require './../index.coffee'

describe 'atomicdb', ->

  it 'During Dev (Observing)', ->

    { LocalStorage } = require('node-localstorage')
    localStorage = new LocalStorage('./scratch.temp')  
    localStorage.clear()

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

    observedStringList = []

    fn = (action, id, args...)->
      observedStringList.push [ action, id ]

    db.observe 'user', fn

    id1 = db.insert 'user', {
      name: 'Charles'
      age: 30
    }

    db.update 'user', (({name})-> name is 'Charles'), (user)->
      user.name = 'Mark'
      return user

    id2 = db.insert 'user', {
      name: 'Curl'
      age: 50
    }

    list = db.find 'user'

    db.remove 'user', (({name})-> name is 'Curl')

    db.unobserve 'user', fn

    id2 = db.insert 'user', {
      name: 'Hurl'
      age: 50
    }

    expect(observedStringList).to.deep.equal [ 
      [ 'insert', 0 ],
      [ 'update', 0 ],
      [ 'insert', 1 ],
      [ 'remove', 1 ] 
    ]