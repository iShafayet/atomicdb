
# Documentation

* [`new Atomicdb`](#constructor) (Create a new Instance)
* [Atomicdb#initializeDatabase](#initializedatabase)
* [Atomicdb#defineCollection](#defineCollection)


## constructor
`new Atomicdb options`

`options` is an object containing the following keys - 

* `name`: A name for the database. Must be unique on your host/domain. It will be looked up in the `storageEngine` you provide. If a database exists, it will be used. If it does not exist, it will be created.

* `storageEngine`: A storageEngine. Compatible with `window.localStorage`, `window.sessionStorage`. You can set your own. A custom storageEngine has to be roughly compatible with the `window.localStorage` specs. Basically, it needs to implement basic the functions in `window.localStorage`, namely `getItem` and `setItem`. For in-memory operation, we suggest you use [memorystorage module](https://www.npmjs.com/package/memorystorage) by [stijndewitt](https://www.npmjs.com/~stijndewitt)

* `serializationEngine`: A way to serialize object to string and back. JSON.stringify and JSON.parse is a good example. You can of course set your own. As long as it has the `stringify` and `parse` methods, you are golden.

* `encryption`: **atomicdb** allows you to use an encryption engine of your choosing. If you ommit this property, no encryption will be used. It applies absolutely no restriction to your choice of algorithm and such. The encryption property takes an object with two mandatory properies. `engine` and `shouldEncryptWholeDatabase`

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

## defineCollection
`db.defineCollection options`

`options` is an object containing the following keys - 

* `name`: A name for the collection. Must be unique on your database. (i.e. "user", "articles" etc..)

* `shouldEncrypt`: If set to `true`, the data in the collection will be encrypted if an encryption engine is provided during constructor call. Defaults to `false`.


## initializeDatabase
`db.initializeDatabase options`

`options` is an optional object containing the following keys - 

* `removeExisting`: If set to `true`, any existing database will be wiped clean. Defaults to `false`
