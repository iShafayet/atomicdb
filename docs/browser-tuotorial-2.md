
# atomicdb browser tutorial (Part 2/3)

Previously, we created a database and inserted the following data into it.

| name  | age | phone        |   |   |
|-------|-----|--------------|---|---|
| James | 26  | 555 454 3434 |   |   |
| Blake | 32  | 555 232 1231 |   |   |
| Tyler | 22  | 544 533 5425 |   |   |

## Getting all data in a collection

Fetching data is extremely simple. You just need to call `db.find` with the name of the collection.

```js
let contactList = db.find('contact');

// contactList contains the following array 
// [
//   {
//     name: "James",
//     age: 26,
//     phone: "555 454 3434"
//   },
//   {
//     name: "Blake",
//     age: 32,
//     phone: "555 232 1231"
//   },
//   {
//     name: "Tyler",
//     age: 22,
//     phone: "544 533 5425"
//   }
// ]
```

Atomicdb is fast and synchronous. Meaning you don't have to handle any promises/callbacks. You just call the method and in the next line you have the data for whatever your purpose is.

## Querying 

For querying the data, you simply pass a function to `db.find`. It's extremely similar to `Array#forEach` or `Array.map`. The function you pass will be called with the document. If your function returns true, the documment is accepted.

Let's find out the contacts that are less than 30 years old.

```js
let contactList = db.find('contact', ({ age }) => age < 30);

// contactList contains the following array 
// [
//   {
//     name: "James",
//     age: 26,
//     phone: "555 454 3434"
//   },
//   {
//     name: "Tyler",
//     age: 22,
//     phone: "544 533 5425"
//   }
// ]
```

Here's an ES5 example of the same code.

```js
var contactList = db.find('contact', function (contact) {
  return contact.age < 30;
});
```

## Getting a single value

If you need a single value, you can use the similar `db.findOne` method. It's the same as `db.find` but returns only the first matching document. If there's no matching document, it'll return null.

```js
let contact = db.findOne('contact', ({ name }) => name === "James");
if (contact) {
  // maybe invite him to your party..
}
```

## Updating values

Suppose Tyler changed his phone number. So, you need to update his number on your contact table. It's as simple as finding his document and then making necessary changes to it.

```js
let updatedCount = db.update('contact', ({ name }) => name === "James", (contact)=>{
  contact.phone = "555 343 6568";
  return contact;
})
```

The last `return contact` bit is very important. Whatever you return is used to replace the existing document. Updated documents retain the original `_id`.

The `updatedCount` value returned by `db.update` tells you how many documents were updated.

# Summary

Here's a code snippet that you can copy paste at the end of your your test script file.

```js
let contactList = db.find('contact');
console.log('All Contacts', contactList);

contactList = db.find('contact', ({ age }) => age < 30);
console.log('Contacts less than 30 years old', contactList);

let contact = db.findOne('contact', ({ name }) => name === "James");
console.log('James', contact);

let updatedCount = db.update('contact', ({ name }) => name === "James", (contact)=>{
  contact.phone = "555 343 6568";
  return contact;
});
if (updatedCount){
  console.log("Jame's new contact number has been saved");
}
``` 

# Continue

[Continue to the next part](browser-tuotorial-3.md) where we will handle *upsert*ing and removing documents.
