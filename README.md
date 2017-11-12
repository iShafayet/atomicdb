# atomicdb
A comprehensive database engine that works with arbitrary storage solutions (on brower and nodejs) and runs guaranteed atomic operations with additional support for encryption and compression. 

It is fully documented and comes with a tutorial for the browser.

[![NPM](https://nodei.co/npm/atomicdb.png?compact=true)](https://npmjs.org/package/atomicdb)

# Resources

[Installation &amp; Usage](#installation)

[Complete Tutorial for the browser](docs/browser-tuotorial-1.md)

[API Reference](docs/api-index.md)

[Testing](#Testing)

# Installation 

## NodeJS

```
npm install atomicdb --save
```

```js
const { Atomicdb } = require('atomicdb');
let db = new Atomicdb();
```

## Browser

Either use [bower](https://bower.io/) (recommended) or [Download the latest build](https://github.com/iShafayet/atomicdb/blob/master/dist/browser/atomicdb-0.1.8.js) yourself.

Import the html using html imports.
```html
<link rel="import" src="../bower_components/atomicdb/atomicdb.html>
```

Or, import the script manually.

```html
<script type="text/javascript" src="atomicdb-0.1.8.js"></script>
```

Then you can use it like (ES6)

```js
const { Atomicdb } = window.atomicdb;
let db = new Atomicdb();
```

Or, in ES5

```js
var db = new window.atomicdb.Atomicdb();
```


