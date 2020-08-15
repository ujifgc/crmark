# warning! this repo is no longer maintained

# crmark

Crystal port of markdown-it parser and renderer. CommonMark and syntax extensions support.

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  crmark:
    github: ujifgc/crmark
```


## Usage


```crystal
require "crmark"

cm_parser = MarkdownIt::Parser.new(:commonmark)
cm_parser.render(input)

mdi_parser = MarkdownIt::Parser.new(:markdownit)
mdi_parser.render(input)
```

## Contributors

- [Igor Bochkariov](https://github.com/ujifgc) Igor Bochkariov - creator, maintainer

## References

[markdown-it](https://github.com/markdown-it/markdown-it) - JavaScript Markdown parser done right. Fast and easy to extend.  
[CommonMark](https://github.com/jgm/CommonMark) - CommonMark spec
