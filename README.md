# digest-manifest-brunch

### Description

This brunch plugin allows to add a sha1 hash to static resources placed in public folder of your project.

It is a production-mode plugin, meaning you have to run `brunch build --production` to run it.

It will copy existing files adding them a sha1 sequence like following:

```
/public/path/to/resource.ext => /public/path/to/resource.sha1sd9c0.ext
```

And will expose a manifest :
```javascript
// in /<public folder>/manifest.json
{
  ...
  "/<public_folder>/path/to/resource.ext" : "/<public_folder>/path/to/resource.sha1sd9c0.ext"
  ...
}
```

This way you can use that map to link the correct resource on your production env with a custom url helper in your views for example.

### Usage

This is a work in progress, to use it, clone this repo and use `npm link` or add this line in you package.json devDependencies:
```javascript
{
  ...
  "digest-manifest-brunch": "viadeo/digest-manifest-brunch"
  ...
}
```

### Todo

- [ ] Tests
- [x] Sequence
  - [x] hash resources like images or fonts
  - [x] injection of these hashes in non-hashed files like js or css
  - [x] hash of js and css
