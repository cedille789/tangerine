const std = @import("std");
const Allocator = std.mem.Allocator;

const Chunk = @import("chunk.zig").Chunk;
const OpCode = @import("chunk.zig").OpCode;
const Value = @import("value.zig").Value;
const printValue = @import("value.zig").printValue;
const Config = @import("Config.zig");

const STACK_MAX = 1024 * 1024 * 2 / @sizeOf(Value); // 2MiB

pub const InterpretError = error{
    CompileError,
    RuntimeError,
};

pub const VM = struct {
    allocator: Allocator,
    config: Config,
    chunk: *Chunk,
    ip: [*]u8,
    stack: []Value,
    stack_top: [*]Value,

    pub fn init(allocator: Allocator, config: Config) Allocator.Error!VM {
        var self = VM{
            .allocator = allocator,
            .config = config,
            .chunk = undefined,
            .ip = undefined,
            .stack = try allocator.alloc(Value, STACK_MAX),
            .stack_top = undefined,
        };

        self.resetStack();
        return self;
    }

    pub fn resetStack(self: *VM) void {
        self.stack_top = @ptrCast(self.stack.ptr);
    }

    pub fn deinit(self: *VM) void {
        self.allocator.free(self.stack);
    }

    inline fn readByte(self: *VM) u8 {
        const ip = self.ip[0];
        self.ip += 1;
        return ip;
    }

    inline fn readConstant(self: *VM) Value {
        return self.chunk.constants.items[self.readByte()];
    }

    inline fn readConstantLong(self: *VM) Value {
        return self.chunk.constants.items[
            self.readByte() |
                (@as(usize, self.readByte()) << 8) |
                (@as(usize, self.readByte()) << 16)
        ];
    }

    inline fn binaryOp(self: *VM, instruction: OpCode) void {
        const b = self.pop();
        const a = self.pop();
        self.push(switch (instruction) {
            .ADD => a + b,
            .SUBTRACT => a - b,
            .MULTIPLY => a * b,
            .DIVIDE => a / b,
            else => unreachable,
        });
    }

    fn run(self: *VM) InterpretError!void {
        while (true) {
            if (self.config.trace_execution) {
                std.debug.print("              ", .{});
                var slot = self.stack.ptr;
                while (@intFromPtr(slot) < @intFromPtr(self.stack_top)) : (slot += 1) {
                    std.debug.print("[ ", .{});
                    printValue(slot[0]);
                    std.debug.print(" ]", .{});
                }
                std.debug.print("\n", .{});
                _ = self.chunk.disassembleInstruction(@intFromPtr(self.ip) - @intFromPtr(self.chunk.code.items.ptr));
            }

            const instruction: OpCode = @enumFromInt(self.readByte());
            switch (instruction) {
                .CONSTANT => {
                    const constant = self.readConstant();
                    self.push(constant);
                    std.debug.print("\n", .{});
                },
                .CONSTANT_LONG => {
                    const constant = self.readConstantLong();
                    self.push(constant);
                    std.debug.print("\n", .{});
                },
                .ADD, .SUBTRACT, .MULTIPLY, .DIVIDE => self.binaryOp(instruction),
                .NEGATE => self.push(-self.pop()),
                .RETURN => {
                    printValue(self.pop());
                    // TODO: Change to use stdout (maybe)
                    std.debug.print("\n", .{});
                    return;
                },
            }
        }
    }

    pub fn interpret(self: *VM, chunk: *Chunk) InterpretError!void {
        self.chunk = chunk;
        self.ip = @ptrCast(chunk.code.items.ptr);
        return self.run();
    }

    pub fn push(self: *VM, value: Value) void {
        self.stack_top[0] = value;
        self.stack_top += 1;
    }

    pub fn pop(self: *VM) Value {
        self.stack_top -= 1;
        return self.stack_top[0];
    }
};
