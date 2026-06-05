const std = @import("std");
const provider = @import("../provider/root.zig");
const embedding = @import("../embedding/root.zig");
const vectorstore = @import("../vectorstore/root.zig");
const chunker = @import("chunker.zig");

pub fn ingest(
    allocator: std.mem.Allocator,
    comptime ProviderType: type,
    comptime EmbeddingType: type,
    comptime StoreType: type,
    store: *StoreType,
    api_key: []const u8,
    text: []const u8,
) !void {
    _ = ProviderType;
    const c = chunker.Chunker.init(.recursive, 500, 50);
    const chunks = try c.chunk(allocator, text);
    defer {
        for (chunks) |chunk| allocator.free(chunk);
        allocator.free(chunks);
    }

    for (chunks) |chunk| {
        const vec = try embedding.Embedding.embed(EmbeddingType, allocator, api_key, chunk);
        defer allocator.free(vec);
        
        const id = try std.fmt.allocPrint(allocator, "chunk_{d}", .{std.hash.Wyhash.hash(0, chunk)});
        defer allocator.free(id);

        try vectorstore.VectorStore.insert(StoreType, store, allocator, id, vec, chunk);
    }
}

pub fn query(
    allocator: std.mem.Allocator,
    comptime ProviderType: type,
    comptime EmbeddingType: type,
    comptime StoreType: type,
    store: *StoreType,
    api_key: []const u8,
    query_text: []const u8,
) ![]const u8 {
    const query_vec = try embedding.Embedding.embed(EmbeddingType, allocator, api_key, query_text);
    defer allocator.free(query_vec);

    const results = try vectorstore.VectorStore.query(StoreType, store, allocator, query_vec, 3);
    defer allocator.free(results);

    var prompt_builder = try std.ArrayList(u8).initCapacity(allocator, 0);
    defer prompt_builder.deinit(allocator);
    
    try prompt_builder.appendSlice(allocator, "Use the following context to answer the question.\n\nContext:\n");
    for (results) |res| {
        if (res.metadata) |meta| {
            try prompt_builder.appendSlice(allocator, meta);
            try prompt_builder.appendSlice(allocator, "\n---\n");
        }
    }
    try prompt_builder.appendSlice(allocator, "\nQuestion: ");
    try prompt_builder.appendSlice(allocator, query_text);

    const messages = [_]provider.Message{
        .{ .role = .user, .content = prompt_builder.items },
    };
    const response = try provider.Provider.chat(ProviderType, allocator, api_key, &messages);
    
    const final_res = try allocator.dupe(u8, response.content);
    response.deinit(allocator);
    
    return final_res;
}
