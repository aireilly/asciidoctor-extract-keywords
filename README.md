# Extracting AsciiDoc keywords to YAML for further processing

This simple ruby script takes an input assembly, processes the file, resolves all includes and outputs a commented AST of the input and a YAML file with all the keywords attributes.

To test the script, run the following:

```
ruby extract-asciidoc-keywords.rb doc/validating-an-installation.adoc > ast.adoc
```