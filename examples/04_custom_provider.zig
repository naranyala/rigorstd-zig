const std = @import("std");
const llm = @import("src/llm/root.zig");

/// CustomProvider is a user-defined LLM backend.
/// To integrate into the stdlib, it just needs to implement the 'chat' method.
pub const CustomProvider = struct {
    pub fn chat(
        allocator: std.mem.Allocator,
        api_key: []const u8,
        messages: []const llm.provider.Message,
        cfg: llm.config.RequestConfig,
    ) !llm.provider.ChatResponse {
        _ = api_key;
        _ = cfg;
        
        std.debug.print("CustomProvider: Processing {d} messages...\n", .{messages.len});
        
        return llm.provider.ChatResponse {
            .content = try allocator.dupe(u8, "Hello from a Custom Zig Provider!"),
            .usage_tokens = 10,
        };
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    
    const messages = [_]llm.provider.Message{
        .{ .role = .user, .content = "Hello!" },
    };

    // We can pass our CustomProvider directly into the Provider interface
    const response = try llm.provider.Provider.chat(
        CustomProvider,
        allocator,
        "my-secret-key",
        &messages,
        .{},
    );
    defer response.deinit(allocator);

    std.debug.print("Response: {s}\n", .{response.content});
}
