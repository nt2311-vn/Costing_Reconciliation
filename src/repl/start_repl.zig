const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const debug = std.debug;
const fs = std.fs;

const trademarks: []const u8 =
    \\(c) Copyright nt2311-vn. All right reserved.
    \\Welcome to costing recoliation cli written in Zig.
    \\
;

const Item = struct {
    code: []const u8,
    quantity: u32,
};

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

fn loadIF(alloc: mem.Allocator, f: *fs.File) anyerror!std.StringHashMap(Item) {
    var reconcile_map = std.StringHashMap(Item).init(alloc);
    defer reconcile_map.deinit();

    var buf_reader = std.io.bufferedReader(f.reader());
    var reader = buf_reader.reader();

    const buf = try alloc.alloc(u8, 100);
    defer alloc.free(buf);

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

        const key_part1 = try alloc.dupe(u8, substr[4]);
        const key_part2 = try alloc.dupe(u8, substr[3]);
        defer alloc.free(key_part1);
        defer alloc.free(key_part2);

        const key_len = key_part1.len + key_part2.len + 1;
        const key = try alloc.alloc(u8, key_len);
        defer alloc.free(key);

        _ = std.fmt.bufPrint(key, "{s}_{s}", .{ key_part1, key_part2 }) catch |err| {
            debug.print("Error occurs: {s}\n", .{@errorName(err)});
            return err;
        };

        var rs = reconcile_map.getOrPut(key) catch |err| {
            debug.print("Get error on get or put:{s}\n", .{@errorName(err)});
            return err;
        };

        if (rs.found_existing) {
            rs.value_ptr.quantity += 1;
        } else {
            rs.value_ptr.* = .{ .code = key_part2, .quantity = 1 };
        }
    }

    return reconcile_map;
}

fn startCommand() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var if_file = fs.cwd().openFile("src/data/IF.csv", .{ .mode = .read_only }) catch |err| {
        debug.print("could not open file\n", .{});
        return err;
    };
    defer if_file.close();

    var map = try loadIF(allocator, &if_file);
    var it = map.iterator();

    while (it.next()) |p| {
        debug.print("{s}:{s} {d}\n", .{ p.key_ptr.*, p.value_ptr.*.code, p.value_ptr.*.quantity });
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
                command.execFn() catch |err| {
                    debug.print("Error on execution function: {s}\n", .{@errorName(err)});
                    return err;
                };
            } else {
                debug.print("Invalid commands: {s}\n", .{trim_input});
            }
        } else {
            debug.print("Error read stream occur\n", .{});
        }
    }
}
