const std = @import("std");

pub const ChunkingStrategy = enum {
    fixed_size,
    recursive,
};

pub const Chunker = struct {
    strategy: ChunkingStrategy,
    chunk_size: usize,
    chunk_overlap: usize,

    pub fn init(strategy: ChunkingStrategy, chunk_size: usize, chunk_overlap: usize) Chunker {
        return .{
            .strategy = strategy,
            .chunk_size = chunk_size,
            .chunk_overlap = chunk_overlap,
        };
    }

    pub fn chunk(self: Chunker, allocator: std.mem.Allocator, text: []const u8) ![][]const u8 {
        // This will return a slice of slices, but for simplicity in Zig we'll use an ArrayList of slices
        // and return the items. The caller is responsible for the memory of the result list.
        
        switch (self.strategy) {
            .fixed_size => return try self.fixedSizeChunk(allocator, text),
            .recursive => return try self.recursiveChunk(allocator, text),
        }
    }

    fn fixedSizeChunk(self: Chunker, allocator: std.mem.Allocator, text: []const u8) ![][]const u8 {
        var chunks = try std.ArrayList([]const u8).initCapacity(allocator, 0);
        errdefer chunks.deinit(allocator);

        var start: usize = 0;
        while (start < text.len) {
            const end = @min(start + self.chunk_size, text.len);
            const chunk_data = try allocator.dupe(u8, text[start..end]);
            try chunks.append(allocator, chunk_data);
            
            if (end == text.len) break;
            start += (self.chunk_size - self.chunk_overlap);
            if (start >= end and end < text.len) {
                // Avoid infinite loop if overlap >= size
                start = end;
            }
        }

        return try chunks.toOwnedSlice(allocator);
    }

    fn recursiveChunk(self: Chunker, allocator: std.mem.Allocator, text: []const u8) ![][]const u8 {
        // Simplified recursive chunker: try to split by common separators
        const separators = [_][]const u8 { "\n\n", "\n", " ", "" };
        return try self.recursiveSplit(allocator, text, &separators, 0);
    }

    fn recursiveSplit(self: Chunker, allocator: std.mem.Allocator, text: []const u8, separators: []const []const u8, sep_idx: usize) ![][]const u8 {
        if (text.len <= self.chunk_size) {
            const res = try allocator.alloc([]const u8, 1);
            res[0] = try allocator.dupe(u8, text);
            return res;
        }

        if (sep_idx >= separators.len) {
            return try self.fixedSizeChunk(allocator, text);
        }

        const sep = separators[sep_idx];
        if (sep.len == 0) {
            return try self.fixedSizeChunk(allocator, text);
        }

        var chunks = try std.ArrayList([]const u8).initCapacity(allocator, 0);
        errdefer chunks.deinit(allocator);

        var current_start: usize = 0;
        while (true) {
            if (std.mem.indexOf(u8, text[current_start..], sep)) |offset| {
                const absolute_offset = current_start + offset;
                const segment = text[current_start..absolute_offset];
                
                // Process segment recursively
                const sub_chunks = try self.recursiveSplit(allocator, segment, separators, sep_idx + 1);
                defer allocator.free(sub_chunks);
                try chunks.appendSlice(allocator, sub_chunks);
                
                current_start = absolute_offset + sep.len;
            } else {
                const segment = text[current_start..];
                const sub_chunks = try self.recursiveSplit(allocator, segment, separators, sep_idx + 1);
                defer allocator.free(sub_chunks);
                try chunks.appendSlice(allocator, sub_chunks);
                break;
            }
        }

        return try chunks.toOwnedSlice(allocator);
    }
};

test "Chunker fixed size" {
    const allocator = std.heap.page_allocator;
    const c = Chunker.init(.fixed_size, 10, 2);
    const text = "0123456789abcdefghij"; // 20 chars
    const chunks = try c.chunk(allocator, text);
    defer {
        for (chunks) |chunk| allocator.free(chunk);
        allocator.free(chunks);
    }
    // Chunk 1: 0-10, Chunk 2: 8-18, Chunk 3: 16-20
    try std.testing.expectEqual(chunks.len, 3);
    try std.testing.expectEqualStrings(chunks[0], "0123456789");
    try std.testing.expectEqualStrings(chunks[1], "89abcdefgh");
}

test "Chunker recursive" {
    const allocator = std.heap.page_allocator;
    const c = Chunker.init(.recursive, 15, 0);
    const text = "Paragraph one.\n\nParagraph two. a bit longer.";
    const chunks = try c.chunk(allocator, text);
    defer {
        for (chunks) |chunk| allocator.free(chunk);
        allocator.free(chunks);
    }
    try std.testing.expect(chunks.len >= 2);
}
