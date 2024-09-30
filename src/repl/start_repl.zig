const std = @import("std");
const debug = std.debug;
const io = std.io;
const mem = std.mem;
const ascii = std.ascii;
const heap = std.heap;

pub const CliCommand = struct {
    name: []const u8,
    description: []const u8,
    callbackFn: *const fn (commands: *std.StringHashMap(CliCommand)) void,
};

const trademarks =
    \\(c) Copyright nt2311-vn. All right reserved.
    \\Welcome to costing recoliation cli written in Zig.
    \\
;

fn callbackHelp(commands: *std.StringHashMap(CliCommand)) void {
    debug.print("\n", .{});

    var keys = commands.keyIterator();
    while (keys.next()) |key| {
        debug.print("{s}- {s}\n", .{ key.*, commands.get(key.*).?.description });
    }
}

fn cleanInput(allocator: mem.Allocator, str: []const u8) ![][]const u8 {
    const lower = try ascii.allocLowerString(allocator, str);
    defer allocator.free(lower);

    var words = std.ArrayList([]const u8).init(allocator);
    defer words.deinit();

    var iterator = mem.splitSequence(u8, lower, " ");
    while (iterator.next()) |word| {
        if (word.len > 0) try words.append(try allocator.dupe(u8, word));
    }

    return try words.toOwnedSlice();
}

pub fn starRepl() !void {
    debug.print("{s}", .{trademarks});
    debug.print("", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    var commands = std.StringHashMap(CliCommand).init(allocator);
    defer commands.deinit();

    try commands.put("help", .{ .name = "help", .description = "List all available commands", .callbackFn = callbackHelp });

    while (true) {
        debug.print("costing>", .{});

        const stdin = io.getStdIn().reader();
        const bare_line = try stdin.readUntilDelimiterAlloc(allocator, '\n', 120);
        defer allocator.free(bare_line);

        const commandSlice = try cleanInput(allocator, bare_line);
        const command = commandSlice[0];

        if (commands.get(command)) |cli| {
            cli.callbackFn(&commands);
        } else {
            debug.print("Invalid command", .{});
        }
    }
}
