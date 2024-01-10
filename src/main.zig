const std = @import("std");

const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;
const Location = @import("Location.zig");
const VM = @import("vm.zig").VM;
const Config = @import("Config.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const loc = Location.init("test.tgr", "asdfjkl;", 2, 5);

    var vm = try VM.init(allocator, .{ .trace_execution = true });
    defer vm.deinit();

    var chunk = Chunk.init(allocator);
    defer chunk.deinit();

    try chunk.writeConstant(1.2, loc);
    try chunk.writeConstant(3.4, loc);
    try chunk.write(@intFromEnum(OpCode.ADD), loc);

    try chunk.writeConstant(5.6, loc);
    try chunk.write(@intFromEnum(OpCode.DIVIDE), loc);
    try chunk.write(@intFromEnum(OpCode.NEGATE), loc);

    try chunk.write(@intFromEnum(OpCode.RETURN), loc);

    chunk.disassemble("test chunk");
    try vm.interpret(&chunk);
}

test "test" {}
