const std = @import("std");
const llm = @import("src/llm/root.zig");
const openai = @import("src/llm/provider/openai.zig").OpenAI;
const config = @import("src/llm/config.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const api_key = "your-openai-api-key";

    // 1. Define the conversation
    const messages = [_]llm.provider.Message{
        .{ .role = .system, .content = "You are a helpful assistant that speaks like a pirate." },
        .{ .role = .user, .content = "Tell me about Zig programming language." },
    };

    // 2. Configure hyperparameters
    const cfg = config.RequestConfig {
        .temperature = 0.9,
        .max_tokens = 150,
    };

    std.debug.print("Requesting response...\n", .{});

    // 3. Use the Provider interface to call OpenAI
    const response = try llm.provider.Provider.chat(
        openai,
        allocator,
        api_key,
        &messages,
        cfg,
    );
    defer response.deinit(allocator);

    std.debug.print("AI: {s}\n", .{response.content});
}
