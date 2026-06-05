const std = @import("std");
const llm = @import("src/llm/root.zig");
const playground = @import("src/llm/playground/root.zig").Playground;
const ollama = @import("src/llm/provider/ollama.zig").Ollama;
const config = @import("src/llm/config.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    
    var pg = playground.init(allocator);
    defer pg.deinit();

    // Create two different chat sessions
    _ = try pg.createSession("coding-assistant");
    _ = try pg.createSession("creative-writing");

    // --- Session 1: Coding ---
    pg.setSession("coding-assistant");
    const code_cfg = config.RequestConfig { .temperature = 0.1 }; // Precise
    
    std.debug.print("--- Coding Session ---\n", .{});
    const res1 = try pg.chat(ollama, "", "How do I implement a linked list in Zig?", code_cfg);
    defer allocator.free(res1);
    std.debug.print("AI: {s}\n\n", .{res1});

    // --- Session 2: Creative ---
    pg.setSession("creative-writing");
    const creative_cfg = config.RequestConfig { .temperature = 0.9 }; // Imaginative
    
    std.debug.print("--- Creative Session ---\n", .{});
    const res2 = try pg.chat(ollama, "", "Write a haiku about a lonely robot.", creative_cfg);
    defer allocator.free(res2);
    std.debug.print("AI: {s}\n", .{res2});
}
