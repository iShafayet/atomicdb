
{ expect, assert } = require('chai')

{ Atomicdb } = require './../index.coffee'

describe 'atomicdb', ->

  it 'During Dev', ->

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

    db.insert 'user', {
      name: 'Charles'
      age: 30
    }

    db.insert 'user', {
      name: 'Charles'
      age: 40
    }

    db.insert 'user', {
      name: 'Charles'
      age: 50
    }

    db.insert 'user', {
      name: 'Charles'
      age: 60
    }

    removedCount = db.remove 'user', (()-> true)

    expect(removedCount).to.equal(5)

    list = db.find 'user'

    expect(list).to.deep.equal []

    id1 = db.insert 'user', {
      name: 'Charles'
      age: 30
    }

    id2 = db.insert 'user', {
      name: 'James'
      age: 40
    }

    [ updatedCount, upsertedId ] = db.upsert 'user', (({_aid})-> false), ((doc)-> 
      doc.iWillNeverBeCalled = true
      return doc
    ), {
      name: 'Jill'
      age: 60
    }
    
    expect(updatedCount).to.equal(0)

    list = db.find 'user'
    
    expect(list).to.deep.equal [
      {
        _aid: id1
        name: 'Charles'
        age: 30
      },
      {
        _aid: id2
        name: 'James'
        age: 40
      },
      {
        _aid: upsertedId
        name: 'Jill'
        age: 60
      }
    ]