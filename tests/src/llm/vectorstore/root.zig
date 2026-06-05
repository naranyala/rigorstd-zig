const std = @import("std");

pub const SearchResult = struct {
    id: []const u8,
    score: f32,
    metadata: ?[]const u8 = null,
};

/// VectorStore interface:
/// A type that implements this interface must provide:
/// pub fn insert(self: *T, allocator: std.mem.Allocator, id: []const u8, vector: []const f32, metadata: ?[]const u8) !void
/// pub fn query(self: *T, allocator: std.mem.Allocator, vector: []const f32, top_k: usize) ![]SearchResult
pub const VectorStore = struct {
    pub fn insert(
        comptime T: type,
        self: *T,
        allocator: std.mem.Allocator,
        id: []const u8,
        vector: []const f32,
        metadata: ?[]const u8,
    ) !void {
        try self.insert(allocator, id, vector, metadata);
    }

    pub fn query(
        comptime T: type,
        self: *T,
        allocator: std.mem.Allocator,
        vector: []const f32,
        top_k: usize,
    ) ![]SearchResult {
        return try self.query(allocator, vector, top_k);
    }
};
