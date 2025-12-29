# Gedcom Parser Example

This example demonstrates how to use the `gedcom_parser` package to parse GEDCOM data.

## Running the example

To run this example, use the following command from the root of the package:

```bash
dart example/main.dart
```

## What it does

1.  Defines a simple GEDCOM content as a list of strings.
2.  Uses `GedcomParser` to parse these lines into a `GedcomData` object.
3.  Iterates through the parsed persons and families to print their details.
