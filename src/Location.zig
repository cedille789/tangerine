const Location = @This();

filename: []const u8,
source: []const u8,
start: usize,
end: usize,

pub fn init(filename: []const u8, source: []const u8, start: usize, end: usize) Location {
    return Location{ .filename = filename, .source = source, .start = start, .end = end };
}
