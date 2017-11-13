
# atomicdb browser tutorial (Part 4/4)

## commit Delay

We created the database using the following call.

```js
db = new Atomicdb({
  name: 'test-db',
  storageEngine: localStorage,
  uniqueKey: '_id'
});
```

Whenever we make any kind of changes to the database, the changes are immediately saved in the storage enginge (i.e. localStorage). For a big amount of data, it can slow down the process. It makes much more sense to bundle changes and save after a certain interval (say 100 ms). For this purpose, we will use the `commitDelay` option.

```js
db = new Atomicdb({
  name: 'test-db',
  storageEngine: localStorage,
  uniqueKey: '_id',
  commitDelay: 500
});
```

Here, we set commitDelay to 500. Meaning, there will be at least 500ms gap between two subsequent commits to the storage enginge.

## Manual Commit

Sometimes, it might be necessary to commit immediately. For example, when your user is leaving the page or closing the application. For that, you can call the `db.commit()` method.

Here's an example of calling `db.commit()` when the user closes the page.

```js
window.addEventListener("beforeunload", (e)=> {
  db.commit();
});
```

## Listening to changes

You may want to listen to the changes made to the database. There's a handy `db.observe()` method for that. It takes the name of the collection you want to watch and a function that's called each time the collection is updated.

```js
db.observe('contact', (action)=> {
  console.log("Collection Modified");
});

db.insert('contact', { a: 'something' });
```

