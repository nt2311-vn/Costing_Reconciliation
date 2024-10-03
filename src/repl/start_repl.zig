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

fn startCommand() !void {
    // const Item = struct {
    //     code: []const u8,
    //     quantity: u32,
    // };

    // const Line = struct {
    //     date: []const u8,
    //     items: []Item,
    // };

    const fs = std.fs;

    var if_file = fs.cwd().openFile("../data/IF.csv", .{}) catch |err| {
        debug.print("could not open file", .{});
        return err;
    };
    defer if_file.close();

    var buf_reader = std.io.bufferedReader(if_file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        debug.print("{s}\n", .{line});
    }
}

pub fn startRepl() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const stdin = std.io.getStdIn().reader();
    var commands = std.StringHashMap(CliCommand).init(allocator);

    try commands.put("help", .{ .name = "help", .description = "List all the available commands", .execFn = helpCommand });

    try commands.put("start", .{ .name = "start", .description = "Start the reconcilation", .execFn = startCommand });

    debug.print("{s}\n", .{trademarks});

    while (true) {
        const buf = try allocator.alloc(u8, 120);
        defer allocator.free(buf);
        debug.print("Your input> ", .{});
        if (try stdin.readUntilDelimiterOrEof(buf, '\n')) |line| {
            const trim_input = mem.trimRight(u8, line, "\r\n");

            if (trim_input.len == 0) continue;

            if (commands.get(trim_input)) |command| {
                try command.execFn();
            } else {
                debug.print("Invalid commands: {s}\n", .{trim_input});
            }
        }
    }
}
