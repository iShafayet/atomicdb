
# atomicdb browser tutorial (Part 3/4)

Currently our `contact` collection looks like this - 

| name  | age | phone        |   |   |
|-------|-----|--------------|---|---|
| James | 26  | 555 343 6568 |   |   |
| Blake | 32  | 555 232 1231 |   |   |
| Tyler | 22  | 544 533 5425 |   |   |

## Upserting

Suppose you met Blake and he just gave you his new number. But you forgot whether you already have him in your contacts. You could do -

```js
if (db.findOne('contact', ({ name }) => name === "Blake")) {
  db.update('contact', ({ name }) => name === "Blake", (contact) => {
    contact.phone = "555 454 7674";
    return contact;
  });
} else {
  db.insert('contact', {
    name: "Blake",
    age: 32,
    phone: "555 454 7674"
  });
}
```

But since you are a wise person, you are going to take advantage of the `upsert` method. `upsert` is just like `update` but has one extra parameter that contains the doc you want to insert in case there's no document matching your query.

```js
db.upsert('contact', ({ name }) => name === "Blake", (contact) => {
  contact.phone = "555 454 7674";
  return contact;
}, {
    name: "Blake",
    age: 32,
    phone: "555 454 7674"
  }
);
```

## Removing documents

Removing documents is just like `db.find`. You simple call `db.remove` instead.

```js
db.remove('contact', ({ name }) => name === "Tyler");
```

And, if you don't provide any query, you can wipe out the whole collection.

```js
db.remove('contact');
```

# Summary

Here's a code snippet that you can copy paste at the end of your your test script file.

```js
db.upsert('contact', ({ name }) => name === "Blake", (contact) => {
  contact.phone = "555 454 7674";
  return contact;
}, {
    name: "Blake",
    age: 32,
    phone: "555 454 7674"
  }
);

db.remove('contact', ({ name }) => name === "Tyler");
``` 

# Continue

You now have all the information you need to make a great app with atomicdb. However, there's always more to learn.

[Continue to the next part](browser-tuotorial-4.md) where we will discuss a few advanced features like how often to save to localStorage, listening to changes made to the database and so on.
