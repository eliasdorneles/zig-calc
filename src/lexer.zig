const std = @import("std");
const mem = std.mem;
const log = std.log;

const Lexer = @This();

const TokenType = enum {
    Assign,
    Plus,
    Minus,
    Mult,
    Div,
    OpenParen,
    CloseParen,
    Identifier,
    Number,
};

fn isValidIdentifier(token: []const u8) bool {
    if (token.len == 0) return false;
    if (!std.ascii.isAlphabetic(token[0]) or token[0] != '_') return false;
    for (token) |c| {
        if (!std.ascii.isAlphanumeric(c) and c != '_') {
            return false;
        }
    }
    return true;
}

fn isValidNumber(token: []const u8) bool {
    if (token.len == 0) return false;
    for (token) |c| {
        if (!std.ascii.isDigit(c)) {
            return false;
        }
    }
    return true;
}

const Token = struct {
    type: TokenType,
    value: []const u8,

    pub fn init(value: []const u8) !Token {
        var tok_type: ?TokenType = null;
        if (value.len == 1) {
            tok_type = switch (value[0]) {
                '+' => TokenType.Plus,
                '-' => TokenType.Minus,
                '*' => TokenType.Mult,
                '/' => TokenType.Div,
                '(' => TokenType.OpenParen,
                ')' => TokenType.CloseParen,
                '=' => TokenType.Assign,
                else => null,
            };
            if (tok_type != null) {
                return Token{ .type = tok_type, .value = value };
            }
        }
        if (isValidIdentifier(value)) {
            return Token{ .value = value, .type = TokenType.Identifier };
        }
        if (std.ascii.isDigit(value[0])) {
            // TODO: add better error handling for number parsing,
            // postponing the decision as not sure if it should be in the lexer
            return Token{ .value = value, .type = TokenType.Number };
        }
        return error.InvalidToken;
    }
};

// lexer state:
buffer: []const u8,
index: usize,
nextToken: ?Token = null,

pub fn init(buffer: []const u8) Lexer {
    return Lexer{ .buffer = buffer, .index = 0 };
}

fn isSingleCharOperator(c: u8) bool {
    return (c == '+' or c == '-' or c == '*' or c == '/' or
        c == '(' or c == ')' or c == '=');
}

fn skipSpaces(self: *Lexer) void {
    while (self.index < self.buffer.len and self.buffer[self.index] == ' ') {
        self.index += 1;
    }
}

pub fn next(self: *Lexer) ?Token {
    if (self.nextToken != null) {
        defer self.nextToken = null;
        return self.nextToken;
    }

    if (self.index >= self.buffer.len) {
        return null;
    }

    self.skipSpaces();

    const startTok = self.index;

    while (self.index < self.buffer.len) : (self.index += 1) {
        if (isSingleCharOperator(self.buffer[self.index])) {
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
