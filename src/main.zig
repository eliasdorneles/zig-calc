const std = @import("std");

const Calculator = @import("calculator.zig");

fn prompt(text: []const u8, line: *std.ArrayList(u8)) ![]u8 {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}", .{text});

    const stdin = std.io.getStdIn().reader();
    const line_writer = line.writer();
    try stdin.streamUntilDelimiter(line_writer, '\n', null);
    return line.items;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();

    var line = std.ArrayList(u8).init(allocator);
    defer line.deinit();

    var calc = Calculator.init(allocator);
    defer calc.deinit();

    while (prompt("calc % ", &line)) |expr| {
        defer line.clearRetainingCapacity();

        const result = calc.eval(expr) catch |err| {
            try stdout.print("Error: {}\n", .{err});
            continue;
        };
        try stdout.print("{d}\n", .{result});
    } else |err| {
        try switch (err) {
            error.EndOfStream => stdout.print("Bye\n", .{}),
            else => stdout.print("Error: {}\n", .{err}),
        };
    }
}
