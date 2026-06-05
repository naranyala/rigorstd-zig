const std = @import("std");
const root = @import("root.zig");

pub const OpenAI = struct {
    pub fn chat(
        allocator: std.mem.Allocator,
        api_key: []const u8,
        messages: []const root.Message,
    ) !root.ChatResponse {
        _ = api_key;
        _ = messages;
        
        // Mock response to ensure the RAG pipeline works
        return root.ChatResponse {
            .content = try allocator.dupe(u8, "This is a mock response from OpenAI. In a real implementation, this would make an HTTP request to the OpenAI API using std.http.Client."),
            .usage_tokens = 100,
        };
    }
};
