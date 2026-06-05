const std = @import("std");
const root = @import("root.zig");

pub const MemoryStore = struct {
    allocator: std.mem.Allocator,
    entries: std.ArrayList(Entry),

    const Entry = struct {
        id: []const u8,
        vector: []f32,
        metadata: ?[]const u8,
    };

    pub fn init(allocator: std.mem.Allocator) !MemoryStore {
        return .{
            .allocator = allocator,
            .entries = try std.ArrayList(Entry).initCapacity(allocator, 0),
        };
    }

    pub fn deinit(self: *MemoryStore) void {
        for (self.entries.items) |entry| {
            self.allocator.free(entry.id);
            self.allocator.free(entry.vector);
            if (entry.metadata) |meta| {
                self.allocator.free(meta);
            }
        }
        self.entries.deinit(self.allocator);
    }

    pub fn insert(self: *MemoryStore, allocator: std.mem.Allocator, id: []const u8, vector: []const f32, metadata: ?[]const u8) !void {
        try self.entries.append(self.allocator, .{
            .id = try allocator.dupe(u8, id),
            .vector = try allocator.dupe(f32, vector),
            .metadata = if (metadata) |m| try allocator.dupe(u8, m) else null,
        });
    }

    fn cosineSimilarity(a: []const f32, b: []const f32) f32 {
        var dot_product: f32 = 0;
        var norm_a: f32 = 0;
        var norm_b: f32 = 0;
        for (a, 0..) |val, i| {
            dot_product += val * b[i];
            norm_a += val * val;
            norm_b += b[i] * b[i];
        }
        return dot_product / (@sqrt(norm_a) * @sqrt(norm_b));
    }

    pub fn query(self: *MemoryStore, allocator: std.mem.Allocator, vector: []const f32, top_k: usize) ![]root.SearchResult {
        var results = try std.ArrayList(root.SearchResult).initCapacity(allocator, 0);
        errdefer results.deinit(allocator);

        for (self.entries.items) |entry| {
            const score = cosineSimilarity(vector, entry.vector);
            try results.append(allocator, .{
                .id = entry.id,
                .score = score,
                .metadata = entry.metadata,
            });
        }

        // Sort by score descending
        std.mem.sort(root.SearchResult, results.items, {}, struct {
            fn lessThan(context: void, a: root.SearchResult, b: root.SearchResult) bool {
                _ = context;
                return a.score > b.score;
            }
        }.lessThan);

        const final_results = try allocator.alloc(root.SearchResult, @min(results.items.len, top_k));
        @memcpy(final_results, results.items[0..@min(results.items.len, top_k)]);
        
        results.deinit(allocator);
        return final_results;
    }
};

test "MemoryStore basic operations" {
    const allocator = std.heap.page_allocator;
    var store = try MemoryStore.init(allocator);
    defer store.deinit();

    const vec1 = [_]f32{1.0, 0.0, 0.0};
    const vec2 = [_]f32{0.0, 1.0, 0.0};
    const vec3 = [_]f32{1.0, 0.0, 0.1};

    try store.insert(allocator, "id1", &vec1, "meta1");
    try store.insert(allocator, "id2", &vec2, "meta2");

    // Test similarity (identical)
    const res1 = try store.query(allocator, &vec1, 1);
    defer allocator.free(res1);
    try std.testing.expectEqualStrings(res1[0].id, "id1");
    try std.testing.expect(res1[0].score > 0.99);

    // Test similarity (orthogonal)
    const res2 = try store.query(allocator, &vec2, 1);
    defer allocator.free(res2);
    try std.testing.expectEqualStrings(res2[0].id, "id2");

    // Test Top-K
    const res3 = try store.query(allocator, &vec3, 2);
    defer allocator.free(res3);
    try std.testing.expectEqual(res3.len, 2);
    try std.testing.expectEqualStrings(res3[0].id, "id1"); // Closer to [1,0,0]
}
