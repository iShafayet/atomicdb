
{ expect, assert } = require('chai')

atomicdb = require './../index.coffee'

describe 'atomicdb', ->

  it 'Existence', ->

    expect(atomicdb).to.be.an('object')  
