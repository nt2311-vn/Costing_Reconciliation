const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
const heap = std.heap;
const debug = std.debug;

const trademarks: []const u8 =
    \\(c) Copyright nt2311-vn. All right reserved.
    \\Welcome to costing recoliation cli written in Zig.
    \\
;

pub const CliCommand = struct {
    name: []const u8,
    description: []const u8,
    execFn: *const fn () anyerror!void,
};

pub fn startRepl() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    _ = gpa.deinit();

    // const allocator = gpa.allocator();
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    try stdout.print("{s}\n", .{trademarks});

    while (true) {
        var buf: [120]u8 = undefined;
        try stdout.print("costing> ", .{});
        if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var input = line;
            if (builtin.os.tag == .windows) {
                input = @constCast(mem.trimRight(u8, input, "\r"));
            }

            if (input.len == 0) {
                break;
            }

            debug.print("{s}\n", .{input});
        }
    }
}
