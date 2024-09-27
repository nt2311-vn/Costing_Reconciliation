const std = @import("std");
const debug = std.debug;
const io = std.io;
const mem = std.mem;
const ascii = std.ascii;

const CliCommand = struct {
    name: []const u8,
    description: []const u8,
    callbackFn: fn () anyerror!void,
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

    return words;
}

fn callBackHelp() !void {
    debug.print("Help command called\n", .{});
}

fn getCommands(allocator: mem.Allocator) !std.StringHashMap(CliCommand) {
    var commands = std.StringHashMap(CliCommand).init(allocator);
    try commands.put(try allocator.dupe(u8, "help"), .{ .name = "help", .description = "List of available comamnds in costing.", .callbackFn = callBackHelp });
}

pub fn starRepl() !void {
    debug.print("{s}", .{trademarks});
    debug.print("", .{});
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer gpa.deinit();

    while (true) {}
}
