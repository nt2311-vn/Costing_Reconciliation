const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const repl = @import("./repl/start_repl.zig");

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};

    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try repl.startRepl(allocator);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
