## Zig const pointers

Constant pointers which alias a mutable variable
can be defined as follows:
```
var v: u64 = 123;	// A mutable variable
const cp: *u64 = &v;	// A constnat pointer to a mutable variable
```
Such pairs have the following properties:
- v: mutable
- cp: must be initialized when defined and never mutated
- cp == &v: always
- cp.\* == v: always

Previous failing cases are now fixed and all tests are now passing.
