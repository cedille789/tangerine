const std = @import("std");
const Allocator = std.mem.Allocator;

const Location = @import("Location.zig");
const Value = @import("value.zig").Value;
const printValue = @import("value.zig").printValue;
const simpleReport = @import("error/report.zig").simpleReport;

pub const OpCode = enum(u8) {
    CONSTANT,
    CONSTANT_LONG,
    ADD,
    SUBTRACT,
    MULTIPLY,
    DIVIDE,
    NEGATE,
    RETURN,
};

pub const Chunk = struct {
    allocator: Allocator,
    code: std.ArrayList(u8),
    locations: std.ArrayList(Location),
    constants: std.ArrayList(Value),
    count: usize,

    pub fn init(allocator: Allocator) Chunk {
        return .{
            .allocator = allocator,
            .code = std.ArrayList(u8).init(allocator),
            .locations = std.ArrayList(Location).init(allocator),
            .constants = std.ArrayList(Value).init(allocator),
            .count = 0,
        };
    }

    pub fn deinit(self: *Chunk) void {
        self.code.deinit();
        self.locations.deinit();
        self.constants.deinit();
        self.count = 0;
    }

    pub fn write(self: *Chunk, byte: u8, location: Location) Allocator.Error!void {
        try self.code.append(byte);
        try self.locations.append(location);
        self.count += 1;
    }

    pub fn writeConstant(self: *Chunk, value: Value, location: Location) Allocator.Error!void {
        const index = try self.addConstant(value);
        if (index < 256) {
            try self.write(@intFromEnum(OpCode.CONSTANT), location);
            try self.write(@intCast(index), location);
        } else {
            try self.write(@intFromEnum(OpCode.CONSTANT_LONG), location);
            try self.write(@intCast(index & 0xff), location);
            try self.write(@intCast((index >> 8) & 0xff), location);
            try self.write(@intCast((index >> 16) & 0xff), location);
        }
    }

    fn addConstant(self: *Chunk, value: Value) Allocator.Error!usize {
        try self.constants.append(value);
        return self.constants.items.len - 1;
    }

    pub fn disassemble(self: *const Chunk, name: []const u8) void {
        std.debug.print("== {s} ==\n", .{name});

        var offset: usize = 0;
        while (offset < self.count) {
            offset = self.disassembleInstruction(offset);
        }
    }

    fn constantInstruction(self: *const Chunk, name: []const u8, offset: usize) usize {
        const constant = self.code.items[offset + 1];
        std.debug.print("{s:<16} {d:4} '", .{ name, constant });
        printValue(self.constants.items[constant]);
        std.debug.print("'\n", .{});
        return offset + 2;
    }

    fn longConstantInstruction(self: *const Chunk, name: []const u8, offset: usize) usize {
        const constant = self.code.items[offset + 1] |
            (@as(usize, self.code.items[offset + 2]) << 8) |
            (@as(usize, self.code.items[offset + 3]) << 16);
        std.debug.print("{s:<16} {d:4} '", .{ name, constant });
        printValue(self.constants.items[constant]);
        std.debug.print("'\n", .{});
        return offset + 4;
    }

    fn simpleInstruction(self: *const Chunk, name: []const u8, offset: usize) usize {
        _ = self;
        std.debug.print("{s}\n", .{name});
        return offset + 1;
    }

    pub fn disassembleInstruction(self: *const Chunk, offset: usize) usize {
        std.debug.print("{d:0>4} ", .{offset});
        const location = self.locations.items[offset];
        if (offset > 0 and std.meta.eql(location, self.locations.items[offset - 1])) {
            std.debug.print("       | ", .{});
        } else {
            std.debug.print("{:>3}..{:<3} ", .{ location.start, location.end });
        }

        const instruction = self.code.items[offset];

        switch (std.meta.intToEnum(OpCode, instruction) catch {
            simpleReport("unknown opcode {d}", .{instruction});
            return offset + 1;
        }) {
            .CONSTANT => return self.constantInstruction("CONSTANT", offset),
            .CONSTANT_LONG => return self.longConstantInstruction("CONSTANT_LONG", offset),
            .ADD => return self.simpleInstruction("ADD", offset),
            .SUBTRACT => return self.simpleInstruction("SUBTRACT", offset),
            .MULTIPLY => return self.simpleInstruction("MULTIPLY", offset),
            .DIVIDE => return self.simpleInstruction("DIVIDE", offset),
            .NEGATE => return self.simpleInstruction("NEGATE", offset),
            .RETURN => return self.simpleInstruction("RETURN", offset),
        }
    }
};
