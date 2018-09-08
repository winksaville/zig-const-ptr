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

I have found the above holds when both the constant pointers, cp,
and mutable variables, v, are local to a function. But if the either
the cp or the v are global the cp.\* == v fails if the v is mutated.
In particular the cp.\* has the "old" value after v is mutated,
the other properites do hold.

# The following tests pass:
```
$ cat const_ptr.zig 
const assert = @import("std").debug.assert;

const cgp_gv: *u64 = &gv;
var gv: u64 = 123;

test "change const cgp_gv, correct compiler error" {
    var lv: u64 = 47;
    //lcgp_gv = &lv; // compiler correctly generated "error: cannot assign to constant"
}

test "change const clp_lv, correct compiler error" {
    var lv: u64 = 456;
    const clp_lv: *u64 = &lv;

    //clp_lv = &lv; // compiler correctly generated "error: cannot assign to constant"
}

test "Initialize clp_lv after declaration, correct compiler error" {
    const clp_lv: *u64 = undefined; // This could be expected to be a compiler error but
                                    // in zig typically ignores many errors if entities
                                    // are not used. So this is probably WAI.
    //clp_lv = &gv; // compiler correctly generated "error: cannot assign to constant"
}

test "local variable and const clp_lv initialization" {
    var lv: u64 = 456;
    const clp_lv: *u64 = &lv;

    assert(&lv == clp_lv);
    assert(lv == 456);
    assert(clp_lv.* == 456);
}

test "local variable mutation and const clp_lv.* should see mutation" {
    var lv: u64 = 456;
    const clp_lv: *u64 = &lv;

    lv = 4567;
    assert(&lv == clp_lv);
    assert(lv == 4567);
    assert(&lv == clp_lv);
    assert(clp_lv.* == 4567);
}

test "local variable and const clp_gv initialization" {
    const clp_gv: *u64 = &gv;

    assert(&gv == clp_gv);
    assert(gv == 123);
    assert(clp_gv.* == 123);
}

test "test global variable and const ptr alias initialization" {
    assert(&gv == cgp_gv);
    assert(gv == 123);
    assert(cgp_gv.* == 123);
}

test "test global variable mutation" {
    gv = 1234;
    assert(&gv == cgp_gv);
    assert(gv == 1234);
}

test "global const cgp_gv.* mutation should modify gv." {
    cgp_gv.* = 12345;
    assert(&gv == cgp_gv);
    assert(gv == 12345);
}

$ zig test const_ptr.zig 
Test 1/9 change const cgp_gv, correct compiler error...OK
Test 2/9 change const clp_lv, correct compiler error...OK
Test 3/9 Initialize clp_lv after declaration, correct compiler error...OK
Test 4/9 local variable and const clp_lv initialization...OK
Test 5/9 local variable mutation and const clp_lv.* should see mutation...OK
Test 6/9 local variable and const clp_gv initialization...OK
Test 7/9 test global variable and const ptr alias initialization...OK
Test 8/9 test global variable mutation...OK
Test 9/9 global const cgp_gv.* mutation should modify gv....OK
All tests passed.
```

# The following tests fail

Point cgp_gv at gv and mutate gv directly:
```
$ cat failing_direct_gv_mutation_not_seen_by_cgp_gv_deref.zig 
const assert = @import("std").debug.assert;

const cgp_gv: *u64 = &gv;
var gv: u64 = 123;

test "test const cgp_gv.* changed. FAILS" {
    gv = 1234;
    assert(&gv == cgp_gv);
    assert(cgp_gv.* == 123);  // Succeeds should fail
    assert(cgp_gv.* == 1234); // Fails should succeed
}
wink@wink-desktop:~/prgs/ziglang/zig-const-ptr
$ zig test failing_direct_gv_mutation_not_seen_by_cgp_gv_deref.zig
Test 1/1 test const cgp_gv.* changed. FAILS...assertion failure
/home/wink/opt/lib/zig/std/debug/index.zig:118:13: 0x205029 in ??? (test)
            @panic("assertion failure");
            ^
/home/wink/prgs/ziglang/zig-const-ptr/failing_direct_gv_mutation_not_seen_by_cgp_gv_deref.zig:10:11: 0x20506a in ??? (test)
    assert(cgp_gv.* == 1234); // Fails should succeed
          ^
/home/wink/opt/lib/zig/std/special/test_runner.zig:13:25: 0x222c8a in ??? (test)
        if (test_fn.func()) |_| {
                        ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:96:22: 0x222a3b in ??? (test)
            root.main() catch |err| {
                     ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:70:20: 0x2229b5 in ??? (test)
    return callMain();
                   ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:64:39: 0x222818 in ??? (test)
    std.os.posix.exit(callMainWithArgs(argc, argv, envp));
                                      ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:37:5: 0x2226d0 in ??? (test)
    @noInlineCall(posixCallMainAndExit);
    ^

Tests failed. Use the following command to reproduce the failure:
./zig-cache/test
```

Point cgp_gv at gv mutate gv via cgp_gv.*:
```
$ cat failing_gv_mutation_via_cgp_gv.zig
const assert = @import("std").debug.assert;

const cgp_gv: *u64 = &gv;
var gv: u64 = 123;

test "gv mutation via cgp_gv.*. FAILS" {
    cgp_gv.* = 12345;
    assert(&gv == cgp_gv);
    assert(gv == 12345);        // Success as expected
    assert(cgp_gv.* == gv);     // Fails should succeed
    assert(cgp_gv.* == 12345);  // Fails should succeed
}
wink@wink-desktop:~/prgs/ziglang/zig-const-ptr
$ zig test failing_gv_mutation_via_cgp_gv.zig
Test 1/1 gv mutation via cgp_gv.*. FAILS...assertion failure
/home/wink/opt/lib/zig/std/debug/index.zig:118:13: 0x205029 in ??? (test)
            @panic("assertion failure");
            ^
/home/wink/prgs/ziglang/zig-const-ptr/failing_gv_mutation_via_cgp_gv.zig:10:11: 0x205088 in ??? (test)
    assert(cgp_gv.* == gv);     // Fails should succeed
          ^
/home/wink/opt/lib/zig/std/special/test_runner.zig:13:25: 0x222caa in ??? (test)
        if (test_fn.func()) |_| {
                        ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:96:22: 0x222a5b in ??? (test)
            root.main() catch |err| {
                     ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:70:20: 0x2229d5 in ??? (test)
    return callMain();
                   ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:64:39: 0x222838 in ??? (test)
    std.os.posix.exit(callMainWithArgs(argc, argv, envp));
                                      ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:37:5: 0x2226f0 in ??? (test)
    @noInlineCall(posixCallMainAndExit);
    ^

Tests failed. Use the following command to reproduce the failure:
./zig-cache/test
```

Point clp_gv at gv mutate gv via clp_gv.*:
```
$ cat failing_gv_mutation_via_clp_gv.zig
const assert = @import("std").debug.assert;

const cgp_gv: *u64 = &gv;
var gv: u64 = 123;

test "gv mutation va clp_gv.*. FAILS" {
    const clp_gv: *u64 = &gv;

    clp_gv.* = 123456;
    assert(gv == 123456);        // Success as expected
    assert(clp_gv.* == gv);      // Fails should succeed
    assert(clp_gv.* == 123456);  // Fails should succeed
}
wink@wink-desktop:~/prgs/ziglang/zig-const-ptr
$ zig test failing_gv_mutation_via_clp_gv.zig
Test 1/1 gv mutation va clp_gv.*. FAILS...assertion failure
/home/wink/opt/lib/zig/std/debug/index.zig:118:13: 0x205029 in ??? (test)
            @panic("assertion failure");
            ^
/home/wink/prgs/ziglang/zig-const-ptr/failing_gv_mutation_via_clp_gv.zig:11:11: 0x20508d in ??? (test)
    assert(clp_gv.* == gv);      // Fails should succeed
          ^
/home/wink/opt/lib/zig/std/special/test_runner.zig:13:25: 0x222cba in ??? (test)
        if (test_fn.func()) |_| {
                        ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:96:22: 0x222a6b in ??? (test)
            root.main() catch |err| {
                     ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:70:20: 0x2229e5 in ??? (test)
    return callMain();
                   ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:64:39: 0x222848 in ??? (test)
    std.os.posix.exit(callMainWithArgs(argc, argv, envp));
                                      ^
/home/wink/opt/lib/zig/std/special/bootstrap.zig:37:5: 0x222700 in ??? (test)
    @noInlineCall(posixCallMainAndExit);
    ^

Tests failed. Use the following command to reproduce the failure:
./zig-cache/test
```
