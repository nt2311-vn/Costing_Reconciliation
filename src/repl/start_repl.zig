const std = @import("std");
const debug = std.debug;
const io = std.io;
const mem = std.mem;
const ascii = std.ascii;
const heap = std.heap;

const CliCommand = struct {
    allocator: mem.Allocator,
    name: []const u8,
    description: []const u8,
    callbackFn: *const fn (allocator: mem.Allocator) anyerror!void,
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
    defer allocator.free(words);

    var iterator = mem.splitSequence(u8, lower, " ");
    while (iterator.next()) |word| {
        if (word.len > 0) try words.append(word);
    }

    return words.toOwnedSlice();
}

fn callBackHelp(allocator: mem.Allocator) !void {
    const commands = try getCommands(allocator);

    var it = commands.iterator();
    while (it.next()) |command| {
        debug.print("{s} - {s}", .{ command.value_ptr.name, command.value_ptr.description });
    }
    debug.print("", .{});
}

fn getCommands(allocator: mem.Allocator) !std.StringHashMap(CliCommand) {
    var commands = std.StringHashMap(CliCommand).init(allocator);
    defer commands.deinit();

    try commands.put("help", .{ .name = "hellp", .description = "List all the available commands", .callbackFn = callBackHelp });

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
            const command = cleaned[0];
            const commands = try getCommands(allocator);
            defer commands.deinit();

            if (commands.get(command)) |cli| {
                try cli.callbackFn(allocator);
            } else {
                debug.print("Invalid command", .{});
            }
        } else {
            break;
        }
    }
}
