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
