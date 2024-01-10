const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Value = f64;

// TODO: Change to Value.format(...)
pub fn printValue(value: Value) void {
    std.debug.print("{d}", .{value});
}
