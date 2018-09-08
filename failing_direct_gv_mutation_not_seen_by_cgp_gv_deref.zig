const assert = @import("std").debug.assert;

const cgp_gv: *u64 = &gv;
var gv: u64 = 123;

test "test const cgp_gv.* changed. FAILS" {
    gv = 1234;
    assert(&gv == cgp_gv);
    assert(cgp_gv.* == 123);  // Succeeds should fail
    assert(cgp_gv.* == 1234); // Fails should succeed
}
