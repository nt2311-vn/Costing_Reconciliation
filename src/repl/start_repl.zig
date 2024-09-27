const std = @import("std");
const debug = std.debug;
const io = std.io;
const mem = std.mem;
const ascii = std.ascii;

const CliCommand = struct {
    name: []const u8,
    description: []const u8,
    callbackFn: *const fn () anyerror!void,
};

const trademarks =
    \\(c) Copyright nt2311-vn. All right reserved.
    \\Welcome to costing recoliation cli written in Zig.
    \\
;

fn cleanInput(allocator: mem.Allocator, str: []const u8) ![][]const u8 {
    const lower = try ascii.allocLowerString(allocator, str);
    defer allocator.free(lower);

    var words = std.ArrayList([]const u8).init(allocator);
    var iterator = mem.splitSequence(u8, lower, " ");
    while (iterator.next()) |word| {
        if (word.len > 0) try words.append(try allocator.dupe(u8, word));
    }

    return words.toOwnedSlice();
}

fn callBackHelp() !void {
    debug.print("Help command called\n", .{});
}

fn getCommands(allocator: mem.Allocator) !std.StringHashMap(CliCommand) {
    var commands = std.StringHashMap(CliCommand).init(allocator);
    try commands.put(try allocator.dupe(u8, "help"), .{ .name = "help", .description = "List of available comamnds in costing.", .callbackFn = callBackHelp });

    return commands;
}

pub fn starRepl() !void {
    debug.print("{s}", .{trademarks});
    debug.print("", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const stdin = io.getStdIn().reader();
    var buffer: [1024]u8 = undefined;

    while (true) {
        debug.print("costing>", .{});
        if (try stdin.readUntilDelimiterOrEof(&buffer, '\n')) |input| {
            const cleaned = try cleanInput(allocator, input);
            defer allocator.free(cleaned);

            if (cleaned.len == 0) continue;
            const commandName = cleaned[0];
            const commands = try getCommands(allocator);
            defer {
                var keys = commands.keyIterator();
                while (keys.next()) |key| {
                    allocator.free(key.*);
                }
            }

            if (commands.get(commandName)) |command| {
                command.callbackFn() catch |err| {
                    debug.print("Error: {}\n", .{err});
                };
            } else {
                debug.print("Invalid command\n", .{});
            }
        } else {
            break;
        }
    }
}