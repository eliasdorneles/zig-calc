const std = @import("std");

const Calculator = @import("calculator.zig");

fn prompt(
    stdin: *std.Io.Reader,
    stdout: *std.Io.Writer,
    text: []const u8,
) ![]u8 {
    try stdout.print("{s}", .{text});
    try stdout.flush();
    return stdin.takeDelimiterExclusive('\n');
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var stdin_buffer: [1024]u8 = undefined;
    var stdin_reader_wrapper = std.fs.File.stdin().reader(&stdin_buffer);
    const stdin: *std.Io.Reader = &stdin_reader_wrapper.interface;

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var calc = Calculator.init(allocator);
    defer calc.deinit();

    while (prompt(stdin, stdout, "calc % ")) |expr| {
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
    try stdout.flush();
}
