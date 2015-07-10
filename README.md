# digest-manifest-brunch

### Description

This brunch plugin allows to add a sha1 hash to static resources placed in public folder of your project.

It is a production-mode plugin, meaning you have to run `brunch build --production`.

It will copy existing files adding them a sha1 sequence like following:

```
/<public folder>/path/to/resource.ext
=>
/<public folder>/path/to/resource.sha1sd9c0.ext
```

It will also expose a manifest :
```json
// in /<public folder>/manifest.json
{
  "/<public folder>/path/to/resource.ext" : "/<public folder>/path/to/resource.sha1sd9c0.ext"
}
```

This way you can use that map to link the correct resource on your production env with a custom url helper for example.

### Usage

This is a work in progress, to use it, clone this repo and use `npm link` or add this line in you package.json devDependencies:
```json
"digest-manifest-brunch": "slyg/digest-manifest-brunch"
```

### Todo

- [ ] Tests
- [ ] Dev mode manifest generation
- [ ] Sequence
  - [ ] hash resources like images or fonts
  - [ ] injection of these hashes in non-hashed files like js or css
  - [ ] hash of js and css
