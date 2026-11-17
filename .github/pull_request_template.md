## What and why
<!-- Two or three sentences on what changed and why. Ticket: CA-... -->

## Size
<!-- Lines changed in production code, without tests and generated files. -->
<!-- Count lib/ and bin/; leave out test/ and example/. -->

## How it was tested
<!-- The command you ran and its result. -->
`flutter test` →
`dart analyze lib/ test/ bin/` →

## Checklist
- [ ] I read the PR text again after the last change, and every sentence is still true.
- [ ] Every "later" or "out of scope" item has a CA ticket number.
- [ ] Every TODO has its own ticket and link.
- [ ] New public code has `///` docs.
- [ ] For a new rule: docs page, docs/Home.md row, example file, standalone checker and its test count, version bump and CHANGELOG (here or in a stacked bump PR).
- [ ] I replied on every review thread with what I changed, or why I did not change it.
