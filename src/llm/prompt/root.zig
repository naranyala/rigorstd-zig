const std = @import("std");

pub const Template = struct {
    pub fn format(allocator: std.mem.Allocator, template: []const u8, vars: anyopaque) ![]u8 {
        _ = allocator;
        _ = template;
        _ = vars;
        return std.mem.dupe(std.mem.Allocator.allocator, "TODO", 4);
    }
};

pub const PromptUtils = struct {
    pub fn replaceAll(allocator: std.mem.Allocator, text: []const u8, target: []const u8, replacement: []const u8) ![]u8 {
        var result = std.ArrayList(u8).init(allocator);
        
        var cursor: usize = 0;
        while (true) {
            if (std.mem.indexOf(u8, text[cursor..], target)) |offset| {
                const absolute_offset = cursor + offset;
                try result.appendSlice(text[cursor..absolute_offset]);
                try result.appendSlice(replacement);
                cursor = absolute_offset + target.len;
            } else {
                try result.appendSlice(text[cursor..]);
                break;
            }
        }
        
        return result.toOwnedSlice();
    }
};
