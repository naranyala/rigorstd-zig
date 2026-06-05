const std = @import("std");

/// Embedding interface:
/// A type that implements this interface must provide:
/// pub fn embed(allocator: std.mem.Allocator, api_key: []const u8, text: []const u8) ![]f32
pub const Embedding = struct {
    pub fn embed(
        comptime T: type, 
        allocator: std.mem.Allocator, 
        api_key: []const u8, 
        text: []const u8
    ) ![]f32 {
        return T.embed(allocator, api_key, text);
    }
};
