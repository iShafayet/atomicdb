
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

    updatedCount = db.update 'user', (({_aid})-> _aid is id2), (doc)-> 
      doc.isVerified = true
      return doc
    
    expect(updatedCount).to.equal(1)

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
        isVerified: true
      }
    ]

    updatedCount = db.update 'user', id1, (doc)-> 
      doc.isVerified = true
      return doc

    expect(updatedCount).to.equal(1)

    list = db.find 'user'
   
    expect(list).to.deep.equal [
      {
        _aid: id1
        name: 'Charles'
        age: 30
        isVerified: true
      },
      {
        _aid: id2
        name: 'Curl'
        age: 50
        isVerified: true
      }
    ]

    updatedCount = db.update 'user', id1, {
      _aid: 454654654
      name: 'Charles Xavier'
      age: 30
      isVerified: true
    }

    expect(updatedCount).to.equal(1)

    list = db.find 'user'
   
    expect(list).to.deep.equal [
      {
        _aid: id1
        name: 'Charles Xavier'
        age: 30
        isVerified: true
      },
      {
        _aid: id2
        name: 'Curl'
        age: 50
        isVerified: true
      }
    ]

    updatedCount = db.update 'user', (()-> true), (doc)-> 
      doc.isCertified = true
      return doc

    expect(updatedCount).to.equal(2)

    list = db.find 'user'

    expect(list).to.deep.equal [
      {
        _aid: id1
        name: 'Charles Xavier'
        age: 30
        isVerified: true
        isCertified: true
      },
      {
        _aid: id2
        name: 'Curl'
        age: 50
        isVerified: true
        isCertified: true
      }
    ]

    removedCount = db.remove 'user', id1

    expect(removedCount).to.equal(1)

    list = db.find 'user'

    expect(list).to.deep.equal [
      {
        _aid: id2
        name: 'Curl'
        age: 50
        isVerified: true
        isCertified: true
      }
    ]

    id1 = db.insert 'user', {
      name: 'Charles'
      age: 30
    }

    removedCount = db.remove 'user', (()-> true)

    expect(removedCount).to.equal(2)