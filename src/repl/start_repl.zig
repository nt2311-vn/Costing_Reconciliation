const std = @import("std");
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

fn helpCommand() !void {
    const Command = struct { name: []const u8, description: []const u8 };

    const commands: [2]Command = [_]Command{ Command{ .name = "help", .description = "List all available commands" }, Command{ .name = "start", .description = "Start the programming" } };

    for (commands) |command| {
        debug.print("{s} - {s}\n", .{ command.name, command.description });
    }
}

pub fn startRepl() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const stdin = std.io.getStdIn().reader();
    var commands = std.StringHashMap(CliCommand).init(allocator);

    try commands.put("help", .{ .name = "help", .description = "List all the available commands", .execFn = helpCommand });

    debug.print("{s}\n", .{trademarks});

    while (true) {
        const buf = try allocator.alloc(u8, 120);
        defer allocator.free(buf);
        debug.print("Your input> ", .{});
        if (try stdin.readUntilDelimiterOrEof(buf, '\n')) |line| {
            var input = try allocator.dupe(u8, line);
            defer allocator.free(input);

            input = @constCast(mem.trimRight(u8, input, "\r"));

            if (input.len == 0) continue;

            if (commands.get(input)) |command| {
                try command.execFn();
            } else {
                debug.print("Invalid commands\n", .{});
            }
        }
    }
}
