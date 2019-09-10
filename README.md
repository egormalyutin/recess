# recessjs
Simple and powerfull build system.

## Install
```bash
npm i -g recess-build
```

## Run
```bash
recess <task>
```

## Sample config (recess.coffee)
```coffeescript
use all plugins

task compile: [
  entry: "app/**/*"
  compile
  min
  unwrap "app"
  outDir: "dest"
]
```
