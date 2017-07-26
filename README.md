# atomicdb
A comprehensive database engine that works with arbitrary storage solutions and runs guaranteed atomic operations with additional support for encryption and compression

[![NPM](https://nodei.co/npm/atomicdb.png?compact=true)](https://npmjs.org/package/atomicdb)

**N/B:** The code/examples in this file are in coffee-script. <!-- [Click here for the JavaScript Version](README-js.md) (coming soon)--> Javascript examples are coming soon.

# Installation (NodeJS)

```
npm install atomicdb --save
```

# Usage (NodeJS)
```coffee-script
{
  Atomicdb
} = require 'atomicdb'

db = new Atomicdb
```

<!-- Browser Area Start -->
# Installation (Browser)

[Download the latest build](https://github.com/iShafayet/atomicdb/blob/master/dist/browser/atomicdb-0.1.2.js) and put it in your application.

```html
<script type="text/javascript" src="atomicdb-0.1.2.js"></script>
```
<!-- Browser Area End -->

# Usage (Browser)
```coffee-script
{
  Atomicdb
} = window.atomicdb

db = new Atomicdb
```

# Documentation

* [constructor `new Atomicdb`](#constructor) (Create a new Instance)


## constructor
`new Atomicdb options`

`options` is an object containing the following keys - 

* `name`: A name for the database. Must be unique on your host/domain. It will be looked up in the `storageEngine` you provide. If a database exists, it will be used. If it does not exist, it will be created.

* `storageEngine`: A storageEngine. Compatible with `window.localStorage`, `window.sessionStorage`. You can set your own. A custom storageEngine has to be roughly compatible with the `window.localStorage` specs. Basically, it needs to implement basic the functions in `window.localStorage`, namely `getItem` and `setItem`. For in-memory operation, we suggest you use [memorystorage module](https://www.npmjs.com/package/memorystorage) by [stijndewitt](https://www.npmjs.com/~stijndewitt)

* `serializationEngine`: A way to serialize object to string and back. JSON.stringify and JSON.parse is a good example. You can of course set your own. As long as it has the `stringify` and `parse` methods, you are golden.

* `encryption`: **atomicdb** allows you to use an encryption engine of your choosing. It applies absolutely no restriction to your choice of algorithm and such. The encryption property takes an object with two mandatory properies. `engine` and `shouldEncryptWholeDatabase`

    1. `engine`. similar to `serializationEngine` you can use any library as long as it implements two methods, `encrypt(text)` and `decrypt(text)`. [Click here] to learn more about creating your custom encryption engine.

    2. `shouldEncryptWholeDatabase`. Set it to true if you want the entire database to be encrypted every time it commits to the storage. Should be avoided for large projects. Useful if you do not want the names of your collections to be known from outside.

* `commitDelay`: Guarantees that there will be at least `commitDelay` miliseconds delay between two subsequent commits. Useful if you have a big database or very frequent database changes. By default it is set to `'none'` which commits synchronously.

* `uniqueKey`: Every document in **atomicdb** has a unique identifier key that can not be altered by the user/developer. You can specify the name of the unique key. It defaults to `_id` as used in mongodb.

**Example:**
```coffee-script
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
```

