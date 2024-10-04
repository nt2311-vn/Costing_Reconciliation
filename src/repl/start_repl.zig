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

    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const fs = std.fs;

    var if_file = fs.cwd().openFile("src/data/IF.csv", .{ .mode = .read_only }) catch |err| {
        debug.print("could not open file\n", .{});
        return err;
    };
    defer if_file.close();

    var buf_reader = std.io.bufferedReader(if_file.reader());
    var reader = buf_reader.reader();

    var arr = std.ArrayList(u8).init(allocator);
    defer arr.deinit();

    while (true) {
        reader.streamUntilDelimiter(arr.writer(), '\n', null) catch |err| switch (err) {
            error.StreamTooLong => break,
            error.EndOfStream => break,
            else => return err,
        };

        const line = arr.items;
        debug.print("{s}\n", .{line});
        arr.clearRetainingCapacity();
    }

    debug.print("reading complete\n", .{});
}

pub fn startRepl() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const stdin = std.io.getStdIn().reader();
    var commands = std.StringHashMap(CliCommand).init(allocator);
    defer commands.deinit();

    try commands.put("help", .{ .name = "help", .description = "List all the available commands", .execFn = helpCommand });

    try commands.put("start", .{ .name = "start", .description = "Start the reconcilation", .execFn = startCommand });

    debug.print("{s}\n", .{trademarks});

    while (true) {
        const buf = try allocator.alloc(u8, 120);
        defer allocator.free(buf);
        debug.print("Your input> ", .{});
        if (try stdin.readUntilDelimiterOrEof(buf, '\n')) |line| {
            const trim_input = mem.trimRight(u8, line, "\r\n");
            if (mem.eql(u8, trim_input, "exit")) break;

            if (trim_input.len == 0) continue;

            if (commands.get(trim_input)) |command| {
                try command.execFn();
            } else {
                debug.print("Invalid commands: {s}\n", .{trim_input});
            }
        }
    }
}
