const std = @import("std");

buffer: []const u8,
index: usize,
nextToken: ?[]const u8 = null,

const Tokenizer = @This();

pub fn init(buffer: []const u8) Tokenizer {
    return Tokenizer{ .buffer = buffer, .index = 0 };
}

pub fn isOperator(c: u8) bool {
    return c == '+' or c == '-' or c == '*' or c == '/';
}

pub fn isName(token: []const u8) bool {
    if (token.len == 0) return false;
    return std.ascii.isAlpha(token[0]);
}

fn skipSpaces(self: *Tokenizer) void {
    while (self.index < self.buffer.len and self.buffer[self.index] == ' ') {
        self.index += 1;
    }
}

pub fn next(self: *Tokenizer) ?[]const u8 {
    if (self.nextToken != null) {
        const nextVal = self.nextToken;
        self.nextToken = null;
        return nextVal;
    }

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

pub fn peek(self: *Tokenizer) ?[]const u8 {
    if (self.nextToken != null) {
        return self.nextToken;
    }
    self.nextToken = self.next();
    return self.nextToken;
}

test "Tokenizer simple" {
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
}

test "Tokenizer parentheses" {
    var it = Tokenizer.init("((1+2))");

    var tokens = std.ArrayList([]const u8).init(std.testing.allocator);
    defer tokens.deinit();

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

test "Tokenizer peek and next" {
    var it = Tokenizer.init("1 + 22 * 3");
    try std.testing.expectEqualStrings(it.peek() orelse "", "1");
    try std.testing.expectEqualStrings(it.peek() orelse "", "1");
    try std.testing.expectEqualStrings(it.peek() orelse "", "1");
    try std.testing.expectEqualStrings(it.next() orelse "", "1");
    try std.testing.expectEqualStrings(it.peek() orelse "", "+");
    try std.testing.expectEqualStrings(it.peek() orelse "", "+");
    try std.testing.expectEqualStrings(it.next() orelse "", "+");
    try std.testing.expectEqualStrings(it.peek() orelse "", "22");
    try std.testing.expectEqualStrings(it.next() orelse "", "22");
    try std.testing.expectEqualStrings(it.peek() orelse "", "*");
    try std.testing.expectEqualStrings(it.next() orelse "", "*");
    try std.testing.expectEqualStrings(it.peek() orelse "", "3");
    try std.testing.expectEqualStrings(it.next() orelse "", "3");
    try std.testing.expect(it.peek() == null);
    try std.testing.expect(it.peek() == null);
    try std.testing.expect(it.peek() == null);
    try std.testing.expect(it.next() == null);
    try std.testing.expect(it.next() == null);
}
