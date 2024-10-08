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

        const key_part1 = try allocator.dupe(u8, substr[4]);
        const key_part2 = try allocator.dupe(u8, substr[3]);
        defer allocator.free(key_part1);
        defer allocator.free(key_part2);

        const key_len = key_part1.len + key_part2.len + 1;
        const key = try allocator.alloc(u8, key_len);
        defer allocator.free(key);

        _ = std.fmt.bufPrint(key, "{s}_{s}", .{ key_part1, key_part2 }) catch |err| {
            debug.print("Error occurs: {s}\n", .{@errorName(err)});
            return err;
        };

        if (reconcile_map.getPtr(key)) |k_pointer| {
            k_pointer.quantity += 1;
        } else {
            reconcile_map.put(key, .{ .code = key_part2, .quantity = 1 }) catch |err| {
                debug.print("Error occurs: {s}\n", .{@errorName(err)});
                return err;
            };
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
            defer allocator.free(trim_input);

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
