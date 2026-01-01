## 0.0.8

* Integrated official GEDCOM 7.0 test files as a git submodule.
* Updated test suite to use the latest official GEDCOM 7.0 samples.

## 0.0.7

* Improved GEDCOM 5.5.1 compatibility (fixed `OCCU` and `FORM` tag handling).
* Enhanced lossless export to preserve structured address data (`ADDR` with sub-tags).
* Added support for UTF-16 encoded GEDCOM files in the test suite.
* Refactored test suite into separate files for GEDCOM 5 and 7.
* Added more compatibility tests for GEDCOM 5.

## 0.0.6

* Full GEDCOM 7.0 compatibility with 100% pass rate on official test suite.
* Support for multiple `FILE` tags in `OBJE` records.
* Improved `NAME` tag preservation with `rawName` support.
* Enhanced `SNOTE` (shared notes) support across all entities.
* Fixed parser regressions and improved lossless synchronization.

## 0.0.5

* Added support for BLOB objects in GEDCOM 5.5.
* Enhanced Media entity to store embedded binary data.
* Verified compatibility with GEDCOM 7.0 (which uses external files instead of BLOBs).

## 0.0.4

* Reordered changelog entries.

## 0.0.3

* Sample added.

## 0.0.2

* Fixed pubspec.

## 0.0.1

* Initial release of the standalone GEDCOM parser.
* Extracted from the Ages project.
* Supports GEDCOM 5.5.1 and 7.0.
* Includes date parsing for Gregorian, Julian, and French Republican calendars.