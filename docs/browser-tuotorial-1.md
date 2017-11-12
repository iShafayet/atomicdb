
# atomicdb browser tutorial (Part 1/3)

## Creating a database

Let us create a basic database that stores and retrieves data to localStorage. We'll call the db `test-db`. This avoids conflicts when you want multiple dbs for multiple purposes.

```js
db = new Atomicdb({
  name: 'test-db'.
  storageEngine: localStorage
  uniqueKey: '_id'
});
```

As we specified `_id` as the `uniqueKey`, all the documents we insert in the db will have an `_id` property assigned automatically which is a unique number.

## Defining collections.

Unlike mongodb or similar, you need to define a collection before you can use it. This helps prevent accidental typos.

You simply call `db.defineCollection` like - 

```js
db.defineCollection({
  name: 'contact'
});
```

There are a few advanced options like validation and row-level encryption. We will discuss those later.

## Initializing the database

Before we can use the database, we need to initialize it. It ensures any kind of version mismatch and checks for corruption.

```js
db.initializeDatabase();
```

## Inserting data

Take the following table of data. We are going to insert it into our db.

| name  | age | phone        |   |   |
|-------|-----|--------------|---|---|
| James | 26  | 555 454 3434 |   |   |
| Blake | 32  | 555 232 1231 |   |   |
| Tyler | 22  | 544 533 5425 |   |   |

atomicdb stores data as documents (as in mongodb). Let's insert the document.

```js
let doc = {
  name: "James",
  age: 26,
  phone: "555 454 3434"
}
let id = db.insert('user', doc);
```

The `insert` method returns the id of the doc you just inserted, in case you need it for some other reason.

Let's insert the rest.

```js
db.insert('user', {
  name: "Blake",
  age: 32,
  phone: "555 232 1231"
});
db.insert('user', {
  name: "Tyler",
  age: 22,
  phone: "544 533 5425"
});
```

We could also use the `insertMany` method to insert multiple documents at the same time.

```js
db.insertMany('user', [
  {
    name: "Blake",
    age: 32,
    phone: "555 232 1231"
  },
  {
    name: "Tyler",
    age: 22,
    phone: "544 533 5425"
  }
]);
```

*Note:* atomicdb only allows you to insert non-null objects.

# Summary

Here's a code snippet that you can copy paste into your test script file.

```js
// Create database (or load if exists already)
db = new Atomicdb({
  name: 'test-db'.
  storageEngine: localStorage
  uniqueKey: '_id'
});

// Define collections
db.defineCollection({
  name: 'contact'
});

// Initialize the database
db.initializeDatabase();

// Insert our data
db.insertMany('user', [
  {
    name: "James",
    age: 26,
    phone: "555 454 3434"
  },
  {
    name: "Blake",
    age: 32,
    phone: "555 232 1231"
  },
  {
    name: "Tyler",
    age: 22,
    phone: "544 533 5425"
  }
]);
``` 

# Continue

[Continue to the next part](browser-tuotorial-2.md)