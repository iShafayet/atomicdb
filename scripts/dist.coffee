
cslib = require 'coffee-script'
fslib = require 'fs'
pathlib = require 'path'


## INPUT

path = (pathlib.join process.cwd(), '/index.coffee')

input = fslib.readFileSync path, {encoding: 'utf8'}

## PROCESSING

output = cslib.compile input

output = "window['atomicdb'] = {};\n\n" + output

if (index = output.lastIndexOf '}).call(this);') is -1
  throw new Error 'Something went wrong, 1'

output = output.slice 0, index

output += '}).call(window[\'atomicdb\']);\n\n'

## OUTPUT

path = (pathlib.join process.cwd(), 'package.json')

directives = fslib.readFileSync path, {encoding: 'utf8'}

directives = JSON.parse directives

version = directives.version

path = process.cwd()

path = (pathlib.join path, '/dist')

fslib.mkdirSync path unless fslib.existsSync path

path = (pathlib.join path, '/browser')

fslib.mkdirSync path unless fslib.existsSync path

filenameList = fslib.readdirSync path
for filename in filenameList
  fslib.unlink (pathlib.join path, filename)

path = (pathlib.join path, "/atomicdb-#{version}.js")

fslib.writeFileSync path, output, {encoding:'utf8'}

console.log "Compiled to \"#{path}\"\n\n"

jsFilePath = path

readmeFilePath = (pathlib.join process.cwd(), 'README.md')

makeBrowserAreaString = (version) ->
  return """
  <!-- Browser Area Start -->
  # Installation (Browser)

  [Download the latest build](https://github.com/iShafayet/atomicdb/blob/master/dist/browser/atomicdb-#{version}.js) and put it in your application.

  ```html
  <script type="text/javascript" src="atomicdb-#{version}.js"></script>
  ```
  <!-- Browser Area End -->
  """

content = fslib.readFileSync readmeFilePath, { encoding: 'utf8' }

firstIndex = content.indexOf '<!-- Browser Area Start -->'

lastIndex = (content.indexOf '<!-- Browser Area End -->') + ('<!-- Browser Area End -->'.length)

left = content.substr 0, (firstIndex)

right = content.substr lastIndex

medium = left + (makeBrowserAreaString version) + right

fslib.writeFileSync readmeFilePath, medium, { encoding: 'utf8' }


