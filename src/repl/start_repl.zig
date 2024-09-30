const std = @import("std");
const debug = std.debug;
const io = std.io;
const mem = std.mem;
const ascii = std.ascii;
const heap = std.heap;

pub const CliCommand = struct {
    name: []const u8,
    description: []const u8,
    callbackFn: *const fn () anyerror!void,
};

const trademarks =
    \\(c) Copyright nt2311-vn. All right reserved.
    \\Welcome to costing recoliation cli written in Zig.
    \\
;

fn callbackHelp() !void {
    const stdout = io.getStdOut().writer();
    try stdout.print("Available commands\n", .{});
    const commands = getCommands();
    var it = commands.iterator();

    while (it.next()) |entry| {
        try stdout.print("{s}- {s}\n", .{ entry.key_ptr.*, entry.value_ptr.*.description });
    }
}

fn getCommands() std.StringHashMap(CliCommand) {
    var commands = std.StringHashMap(CliCommand).init(heap.page_allocator);
    commands.put("help", .{ .name = "help", .description = "List all available commands", .callbackFn = callbackHelp }) catch unreachable;

    return commands;
}

fn cleanInput(allocator: mem.Allocator, str: []const u8) ![][]const u8 {
    var words = std.ArrayList([]const u8).init(allocator);

    var iterator = mem.splitSequence(u8, str, " ");
    while (iterator.next()) |word| {
        if (word.len > 0) {
            try words.append(try allocator.dupe(u8, word));
        }
    }

    return words.toOwnedSlice();
}

pub fn starRepl() !void {
    const stdout = io.getStdOut().writer();
    const stdin = io.getStdIn().reader();

    try stdout.print("{s}\n", .{trademarks});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var commands = getCommands();
    defer {
        var it = commands.iterator();
        while (it.next()) |key| {
            allocator.free(key.key_ptr.*);
        }

        commands.deinit();
    }

    while (true) {
        try stdout.print("costing> ", .{});
        var input_buf: [120]u8 = undefined;
        const input = try stdin.readUntilDelimiterOrEof(&input_buf, '\n');

        if (input) |line| {
            const cleaned = try cleanInput(allocator, line);
            defer {
                for (cleaned) |w_item| {
                    allocator.free(w_item);
                }

                allocator.free(cleaned);
            }

            if (cleaned.len == 0) continue;
            const command = cleaned[0];

            if (commands.get(command)) |cli| {
                cli.callbackFn() catch |err| {
                    try stdout.print("Error: {}\n", .{err});
                };
            } else {
                try stdout.print("Invalid command\n", .{});
            }
        }
    }
}
