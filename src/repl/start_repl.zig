const std = @import("std");
const mem = @import("std").mem;
const heap = @import("std").heap;

const trademarks: []const u8 =
    \\(c) Copyright nt2311-vn. All right reserved.
    \\Welcome to costing recoliation cli written in Zig.
    \\
;

const CliCommand = struct {
    name: []const u8,
    description: []const u8,
    callbackFn: *const fn (allocator: mem.Allocator) anyerror!void,
};

fn callbackHelp(allocator: mem.Allocator) !void {
    var commands = try getCommands(allocator);
    defer commands.deinit();

    var it = commands.iterator();
    while (it.next()) |pt| {
        std.debug.print("{s}- {s}", .{ pt.key_ptr.*, pt.value_ptr.description });
    }
}

fn getCommands(allocator: mem.Allocator) !std.StringHashMap(CliCommand) {
    var commands = std.StringHashMap(CliCommand).init(allocator);
    try commands.put("help", .{ .name = "help", .description = "List all the available commands", .callbackFn = callbackHelp });

    return commands;
}

pub fn startRepl() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    _ = gpa.deinit();

    const stdin = std.io.getStdIn().reader();
    const allocator = gpa.allocator();

    std.debug.print("{s}\n", .{trademarks});

    var commands = try getCommands(allocator);
    defer commands.deinit();
    var buf: [120]u8 = undefined;

    while (true) {
        std.debug.print("costing> ", .{});

        if (try stdin.readUntilDelimiterOrEof(&buf, '\n')) |word| {
            const line = mem.trimRight(u8, word[0 .. word.len - 1], "\r");
            if (commands.get(line)) |cli| {
                try cli.callbackFn(allocator);
            } else {
                std.debug.print("Invalid command\n", .{});
            }
        }
    }
}
