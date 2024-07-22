const std = @import("std");

buffer: []const u8,
index: usize,

const Tokenizer = @This();

pub fn init(buffer: []const u8) Tokenizer {
    return Tokenizer{ .buffer = buffer, .index = 0 };
}

pub fn isOperator(c: u8) bool {
    return c == '+' or c == '-' or c == '*' or c == '/';
}

fn skipSpaces(self: *Tokenizer) void {
    while (self.index < self.buffer.len and self.buffer[self.index] == ' ') {
        self.index += 1;
    }
}

pub fn next(self: *Tokenizer) ?[]const u8 {
    if (self.index >= self.buffer.len) {
        return null;
    }

    self.skipSpaces();

    const startTok = self.index;

    while (self.index < self.buffer.len) : (self.index += 1) {
        if (self.buffer[self.index] == '(' or self.buffer[self.index] == ')' or
            isOperator(self.buffer[self.index]))
        {
            if (startTok == self.index) {
                self.index += 1;
            }
            return self.buffer[startTok..self.index];
        }
        if (self.buffer[self.index] == ' ') {
            const endTok = self.index;
            self.skipSpaces();
            return self.buffer[startTok..endTok];
        }
    }

    if (startTok == self.index) return null;

    return self.buffer[startTok..self.index];
}

test Tokenizer {
    var it = Tokenizer.init("1 + 22.2 * 3 - 4 / 5");

    var tokens = std.ArrayList([]const u8).init(std.testing.allocator);
    defer tokens.deinit();

    while (it.next()) |token| {
        try tokens.append(token);
    }

    try std.testing.expectEqualStrings(tokens.items[0], "1");
    try std.testing.expectEqualStrings(tokens.items[1], "+");
    try std.testing.expectEqualStrings(tokens.items[2], "22.2");
    try std.testing.expectEqualStrings(tokens.items[3], "*");
    try std.testing.expectEqualStrings(tokens.items[4], "3");
    try std.testing.expectEqualStrings(tokens.items[5], "-");
    try std.testing.expectEqualStrings(tokens.items[6], "4");
    try std.testing.expectEqualStrings(tokens.items[7], "/");
    try std.testing.expectEqualStrings(tokens.items[8], "5");

    tokens.clearRetainingCapacity();

    it = Tokenizer.init("((1+2))");

    while (it.next()) |token| {
        try tokens.append(token);
    }

    try std.testing.expectEqualStrings(tokens.items[0], "(");
    try std.testing.expectEqualStrings(tokens.items[1], "(");
    try std.testing.expectEqualStrings(tokens.items[2], "1");
    try std.testing.expectEqualStrings(tokens.items[3], "+");
    try std.testing.expectEqualStrings(tokens.items[4], "2");
    try std.testing.expectEqualStrings(tokens.items[5], ")");
    try std.testing.expectEqualStrings(tokens.items[6], ")");
}
