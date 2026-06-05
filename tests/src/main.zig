const std = @import("std");
const llm = @import("llm/root.zig");
const playground = @import("llm/playground/root.zig").Playground;
const ollama = @import("llm/provider/ollama.zig").Ollama;
const config = @import("llm/config.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    
    var pg = playground.init(allocator);
    defer pg.deinit();

    // 1. Create a session for a specific project
    _ = try pg.createSession("project-zig-stdlib");
    pg.setSession("project-zig-stdlib");

    // 2. Define hyperparameters for this session
    const my_cfg = config.RequestConfig {
        .temperature = 0.2,
        .max_tokens = 1024,
    };

    // 3. First turn
    std.debug.print("User: Hello, I'm building a Zig stdlib!\n", .{});
    const resp1 = try pg.chat(ollama, "not-needed", "Hello, I'm building a Zig stdlib!", my_cfg);
    defer allocator.free(resp1);
    std.debug.print("AI: {s}\n\n", .{resp1});

    // 4. Second turn
    std.debug.print("User: What was I building again?\n", .{});
    const resp2 = try pg.chat(ollama, "not-needed", "What was I building again?", my_cfg);
    defer allocator.free(resp2);
    std.debug.print("AI: {s}\n", .{resp2});
}
