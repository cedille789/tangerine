const std = @import("std");
const Chameleon = @import("chameleon").Chameleon;

pub fn simpleReport(comptime format: []const u8, args: anytype) void {
    const stderr = std.io.getStdErr().writer();
    comptime var cham = Chameleon.init(.Auto);
    stderr.print("{s} ", .{cham.redBright().bold().fmt("error:")}) catch return;
    stderr.print(format, args) catch return;
    stderr.print("\n", .{}) catch return;
}
