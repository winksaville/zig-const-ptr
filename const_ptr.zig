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

test "test const cgp_gv.* changed." {
    assert(cgp_gv.* == 12345);
    gv = 1234;
    assert(&gv == cgp_gv);
    assert(cgp_gv.* == 1234);
}

test "gv mutation via cgp_gv.*" {
    assert(cgp_gv.* == 1234);
    cgp_gv.* = 12345;
    assert(&gv == cgp_gv);
    assert(gv == 12345);
    assert(cgp_gv.* == gv);
    assert(cgp_gv.* == 12345);
}

test "gv mutation via clp_gv.*" {
    const clp_gv: *u64 = &gv;

    assert(cgp_gv.* == 12345);
    clp_gv.* = 123456;
    assert(gv == 123456);
    assert(clp_gv.* == gv);
    assert(clp_gv.* == 123456);
}
