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
