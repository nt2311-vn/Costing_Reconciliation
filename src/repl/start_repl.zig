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

    var buf = std.ArrayList(u8).init(alloc);
    defer buf.deinit();

    var line_count: usize = 0;
    while (true) {
        line_count += 1;
        buf.clearRetainingCapacity();
        reader.readUntilDelimiterArrayList(&buf, '\n', 1024) catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };

        var substr = std.ArrayList([]const u8).init(alloc);
        defer substr.deinit();

        var it = mem.split(u8, buf.items, ",");
        while (it.next()) |data| {
            try substr.append(data);
        }

        if (substr.items.len < 5) {
            debug.print("Skipping invalid line {d}: not enough fields\n", .{line_count});
            continue;
        }

        const key_part1 = substr.items[4];
        const key_part2 = substr.items[3];

        var key_buf = std.ArrayList(u8).init(alloc);
        defer key_buf.deinit();

        try std.fmt.format(key_buf.writer(), "{s}_{s}", .{ key_part1, key_part2 });

        var entry = try reconcile_map.getOrPut(try alloc.dupe(u8, key_buf.items));
        if (entry.found_existing) {
            entry.value_ptr.quantity += 1;
        } else {
            entry.value_ptr.* = Item{ .code = try alloc.dupe(u8, key_part2), .quantity = 1 };
        }
    }

    debug.print("Processed {d} lines, map size: {d}\n", .{ line_count, reconcile_map.count() });
    return reconcile_map;
}

fn startCommand() !void {
    var gpa = heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var if_file = try fs.cwd().openFile("src/data/IF.csv", .{ .mode = .read_only });
    defer if_file.close();

    var map = try loadIF(allocator, &if_file);
    defer {
        var it = map.iterator();
        while (it.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            allocator.free(entry.value_ptr.code);
        }
        map.deinit();
    }

    debug.print("Map loaded, size: {d}\n", .{map.count()});

    var it = map.iterator();
    var count: usize = 0;
    while (it.next()) |entry| : (count += 1) {
        if (count % 100 == 0) {
            debug.print("Processed {d} entries\n", .{count});
        }
        debug.print("{s}: {s} {d}\n", .{ entry.key_ptr.*, entry.value_ptr.code, entry.value_ptr.quantity });
    }

    debug.print("Finished processing {d} entries\n", .{count});
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
