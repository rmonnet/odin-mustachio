# README

This repository contains the Mustachio library and executable.
Mustachio is an [Odin][odin-website] implementation of the [Mustache templating language][mustache-website] geared towards generating Odin source code from [JSON][json-website] data.

The Mustache templating language is a simple language where name between double brackets (`{{name}}`) are replaced by their value in an associated data view (data dictionary like structure), hence the name Mustache.

## License

This code is copyrighted © Robert Monnet 2025 and released under the [MIT License](./LICENSE.txt).

## Implementation Specific Features

Because this implementation is geared towards code rather than HTML generation, it deviates from the [Mustache specifications][mustache-specification] as follow:

- **No HTML escape by default**: While the original Mustache tags expand to HTML escaped text by default unless you use triple brackets (`{{{name}}}`), Mustachio will not escape HTML unless you add a Mustache comment (`{{!escape=on}}`). All tags after the comment will be HTML escaped until the comment `{{!escape=off}}` is encountered.
- **Triple brackets are not supported**


[mustache-website]: https://mustache.github.io/
[mustache-specification]: https://github.com/mustache/spec/tree/master
[json-website]: https://www.json.org/json-en.html
[odin-website]: https://odin-lang.org/