# atomicdb
A comprehensive database engine that works with arbitrary storage solutions and runs guaranteed atomic operations with additional support for encryption and compression

[![NPM](https://nodei.co/npm/atomicdb.png?compact=true)](https://npmjs.org/package/atomicdb)

**N/B:** The code/examples in this file are in coffee-script. <!-- [Click here for the JavaScript Version](README-js.md) (coming soon)--> Javascript examples are coming soon.

# Installation (NodeJS)

```
npm install atomicdb --save
```

# Usage (NodeJS)
```
{
  Atomicdb
} = require 'atomicdb'

db = new Atomicdb
```

<!-- Browser Area Start -->
# Installation (Browser)

[Download the latest build](https://github.com/iShafayet/atomicdb/blob/master/dist/browser/atomicdb-0.1.0.js) and put it in your application.

```html
<script type="text/javascript" src="atomicdb-0.1.0.js"></script>
```
<!-- Browser Area End -->

# Features

* [constructor `new Atomicdb`](#constructor) (Create a new Instance)


## constructor
`new Atomicdb [options]`

**Example:**
```coffee-script
db = new Atomicdb {
    storageEngine: localStorage
    encryptionEngine: null
    compressionEngine: null
    enableCompression: false
    enableEncryption: false
    commitDelay: 'none'
  }
```