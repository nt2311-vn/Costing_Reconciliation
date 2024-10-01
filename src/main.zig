const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
const heap = std.heap;
const debug = std.debug;

pub fn main() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    while (true) {
        try stdout.print("Your input> ", .{});
        const buf = try allocator.alloc(u8, 120);
        defer allocator.free(buf);

        if (try stdin.readUntilDelimiterOrEof(buf, '\n')) |line| {
            var input = line;
            defer allocator.free(input);

            input = @constCast(mem.trimRight(u8, input, "\r\n"));
            if (input.len == 0) {
                break;
            }

            debug.print("{s} {d}\n", .{ input, input.len });
        } else {
            unreachable;
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
