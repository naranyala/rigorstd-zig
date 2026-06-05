const std = @import("std");
const root = @import("root.zig");

pub const OpenAI = struct {
    pub fn embed(
        allocator: std.mem.Allocator,
        api_key: []const u8,
        text: []const u8,
    ) ![]f32 {
        _ = api_key;
        _ = text;

        // Mock embedding: returns a dummy vector of size 1536 (standard for OpenAI)
        const dim = 1536;
        const vec = try allocator.alloc(f32, dim);
        for (vec, 0..) |*val, i| {
            val.* = @as(f32, @floatFromInt(i)) / 1536.0;
        }
        return vec;
    }
};
