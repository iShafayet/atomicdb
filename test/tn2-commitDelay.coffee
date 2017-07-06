
{ expect, assert } = require('chai')

{ Atomicdb } = require './../index.coffee'

describe 'atomicdb', ->

  it 'commitDelay option', (done)->

    { LocalStorage } = require('node-localstorage')
    localStorage = new LocalStorage('./scratch.temp')  
    localStorage.clear()

    db = new Atomicdb {
      name: 'test-db'
      storageEngine: localStorage
      serializationEngine: JSON
      commitDelay: 200
      uniqueKey: '_aid'
    }

    db.initializeDatabase()

    db.defineCollection {
      name: 'user'
    }

    timesCalled = 0
    token = (new Date).getTime()
    db._saveDatabase = ->
      timesCalled += 1
      now = (new Date).getTime()
      unless (now - token) >= 200
        throw new Error "Did not wait long enough"
    
    setTimeout (=>
      expect(timesCalled).to.equal(1)
      done()
    ), 500

    id1 = db.insert 'user', {
      name: 'Charles'
      age: 30
    }

    id1 = db.insert 'user', {
      name: 'Charles'
      age: 30
    }

    id1 = db.insert 'user', {
      name: 'Charles'
      age: 30
    }
