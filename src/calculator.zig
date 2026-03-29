const std = @import("std");
const mem = std.mem;
const log = std.log;

const Tokenizer = @import("tokenizer.zig");
const isOperator = Tokenizer.isOperator;

fn precedence(c: u8) u8 {
    return switch (c) {
        '+' => 1,
        '-' => 1,
        '*' => 2,
        '/' => 2,
        else => 0,
    };
}

const Calculator = @This();

// Calculator struct fields:
allocator: std.mem.Allocator,
context: std.StringHashMap(f128),

pub fn init(allocator: std.mem.Allocator) Calculator {
    const context = std.StringHashMap(f128).init(allocator);
    return Calculator{ .allocator = allocator, .context = context };
}

pub fn deinit(self: *Calculator) void {
    self.context.deinit();
}

fn evalPostfix(self: *Calculator, tokens: [][]const u8) !f128 {
    var stack: std.ArrayList(f128) = .empty;
    defer stack.deinit(self.allocator);

    for (tokens) |token| {
        if (mem.eql(u8, token, "")) continue;

        if (token.len == 1 and isOperator(token[0])) {
            if (stack.items.len < 2) {
                return error.InvalidInput;
            }
            const b = stack.pop().?;
            const a = stack.pop().?;
            _ = switch (token.ptr[0]) {
                '+' => try stack.append(self.allocator, a + b),
                '-' => try stack.append(self.allocator, a - b),
                '*' => try stack.append(self.allocator, a * b),
                '/' => try stack.append(self.allocator, a / b),
                else => return error.NotImplemented,
            };
        } else {
            const value = try std.fmt.parseFloat(f128, token);
            try stack.append(self.allocator, value);
        }
    }
    if (stack.items.len != 1) {
        return error.InvalidInput;
    }
    return stack.pop().?;
}

fn peek(stack: std.ArrayList([]const u8)) []const u8 {
    return stack.items[stack.items.len - 1];
}

pub fn eval(self: *Calculator, expr: []const u8) !f128 {
    // Here we use the shunting-yard algorithm to convert the infix expression
    // to postfix notation. We then evaluate the postfix expression.
    var stack: std.ArrayList([]const u8) = .empty;
    defer stack.deinit(self.allocator);

    var postfix: std.ArrayList([]const u8) = .empty;
    defer postfix.deinit(self.allocator);

    var it = Tokenizer.init(expr);
    while (it.next()) |token| {
        if (token.len == 1 and isOperator(token[0])) {
            // if it's an operator, we pop any operators from the stack
            // with higher precedence and append them to the postfix
            while (stack.items.len > 0) {
                const top = peek(stack);
                if (isOperator(top[0]) and precedence(token[0]) <= precedence(top[0])) {
                    try postfix.append(self.allocator, stack.pop().?);
                } else {
                    break;
                }
            }
            try stack.append(self.allocator, token);
        } else if (token[0] == '(') {
            try stack.append(self.allocator, token);
        } else if (token[0] == ')') {
            while (stack.items.len > 0) {
                const top = peek(stack);
                if (top[0] == '(') break;
                try postfix.append(self.allocator, stack.pop().?);
            }
            if (stack.items.len == 0) {
                return error.UnbalancedParentheses;
            }
            _ = stack.pop(); // pop '('
        } else {
            try postfix.append(self.allocator, token);
        }
    }

    while (stack.items.len > 0) {
        const token = stack.pop().?;
        if (token[0] == '(') return error.UnbalancedParentheses;
        try postfix.append(self.allocator, token);
    }

    // log.debug("postfix: {s}", .{postfix.items});

    return self.evalPostfix(postfix.items);
}
