const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const debug = std.debug;
const time = std.time;

const trademarks: []const u8 =
    \\(c) Copyright nt2311-vn. All right reserved.
    \\Welcome to costing recoliation cli written in Zig.
    \\
;

fn helpCommand() !void {
    const Command = struct { name: []const u8, description: []const u8 };

    const commands: [3]Command = [_]Command{
        Command{ .name = "help", .description = "List all available commands" },
        Command{ .name = "start", .description = "Start the programming" },
        Command{ .name = "exit", .description = "Exit the application" },
    };

    for (commands) |command| {
        debug.print("{s}- {s}\n", .{ command.name, command.description });
    }
}

fn startCommand() !void {
    const Item = struct {
        code: []const u8,
        quantity: u32,
    };

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

    var reconcile_map = std.StringHashMap(Item).init(allocator);
    defer reconcile_map.deinit();

    const buf = try allocator.alloc(u8, 100);
    defer allocator.free(buf);

    while (true) {
        const line = reader.readUntilDelimiter(buf, '\n') catch |err| switch (err) {
            error.StreamTooLong => break,
            error.EndOfStream => break,
            else => return err,
        };

        var substr: [6][]const u8 = undefined;
        var it = mem.splitSequence(u8, line, ",");

        var i: usize = 0;
        while (it.next()) |data| {
            if (i < substr.len) {
                substr[i] = data;
                i += 1;
            } else {
                break;
            }
        }

        const key_str = try std.fmt.allocPrint(allocator, "{s}_{s}", .{ substr[4], substr[3] });
        defer allocator.free(key_str);

        const key_val = reconcile_map.getOrPut(key_str) catch |err| {
            debug.print("caugh error: {s}", .{@errorName(err)});
            return err;
        };

        if (key_val.found_existing) {
            key_val.value_ptr.quantity += 1;
        } else {
            key_val.key_ptr.* = key_str;
            key_val.value_ptr.quantity = 1;
            key_val.value_ptr.code = substr[3];
        }
    }
}

fn exitCommand() !void {
    std.process.exit(0);
}

pub fn startRepl() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const CliCommand = struct {
        name: []const u8,
        description: []const u8,
        execFn: *const fn () anyerror!void,
    };

    const allocator = gpa.allocator();
    const stdin = std.io.getStdIn().reader();
    var commands = std.StringHashMap(CliCommand).init(allocator);
    defer commands.deinit();

    try commands.put("help", .{ .name = "help", .description = "List all the available commands", .execFn = helpCommand });

    try commands.put("start", .{ .name = "start", .description = "Start the reconcilation", .execFn = startCommand });

    try commands.put("exit", .{ .name = "exit", .description = "Exit the application", .execFn = exitCommand });

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
