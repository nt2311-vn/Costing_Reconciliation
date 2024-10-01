const std = @import("std");
const builtin = @import("builtin");
const mem = std.mem;
const heap = std.heap;
const debug = std.debug;

// const trademarks: []const u8 =
//     \\(c) Copyright nt2311-vn. All right reserved.
//     \\Welcome to costing recoliation cli written in Zig.
//     \\
// ;

pub const CliCommand = struct {
    name: []const u8,
    description: []const u8,
    execFn: *const fn () anyerror!void,
};

pub fn startRepl() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    while (true) {
        var buf: [120]u8 = undefined;
        try stdout.print("Your input> ", .{});
        if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var input = line;
            if (builtin.os.tag == .windows) {
                input = @constCast(mem.trimRight(u8, input, "\r"));
            }

            if (input.len == 0) {
                break;
            }

            const command = try allocator.dupe(u8, input);
            debug.print("{s}\n", .{command});
        }
    }
}
