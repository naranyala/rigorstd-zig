const std, @import("std");
const llm = @import("src/llm/root.zig");
const ollama = @import("src/llm/provider/ollama.zig").Ollama;
const openai_embed = @import("src/llm/embedding/openai.zig").OpenAI;
const mem_store = @import("src/llm/vectorstore/memory.zig").MemoryStore;
const playground = @import("src/llm/playground/root.zig").Playground;
const config = @import("src/llm/config.zig");

/// A simple callback to demonstrate streaming output
fn tokenPrinter(token: []const u8) void {
    std.debug.print("{s}", .{token});
    // In a real app, you'd flush stdout here
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const api_key = "mock-key";

    std.debug.print("=== 🛠️ LLM Stdlib Kitchen Sink Demo ===\n\n", .{});

    // --- 1. CHUNKER EXPOSURE ---
    std.debug.print("1. Testing Chunking Strategies...\n", .{});
    const raw_text = "Zig is a language. It is fast. It is safe. It is productive. It is the future of systems programming.";
    
    const fixed_chunker = llm.rag.chunker.Chunker.init(.fixed_size, 15, 5);
    const rec_chunker = llm.rag.chunker.Chunker.init(.recursive, 15, 0);

    const fixed_res = try fixed_chunker.chunk(allocator, raw_text);
    defer {
        for (fixed_res) |c| allocator.free(c);
        allocator.free(fixed_res);
    }
    const rec_res = try rec_chunker.chunk(allocator, raw_text);
    defer {
        for (rec_res) |c| allocator.free(c);
        allocator.free(rec_res);
    }

    std.debug.print("   - Fixed (size 15, overlap 5): {d} chunks\n", .{fixed_res.len});
    std.debug.print("   - Recursive (size 15): {d} chunks\n\n", .{rec_res.len});


    // --- 2. PROMPT UTILITIES EXPOSURE ---
    std.debug.print("2. Testing Prompt Utilities...\n", .{});
    const template = "Hello, {{name}}! Welcome to {{project}}.";
    const name_replaced = try llm.prompt.PromptUtils.replaceAll(allocator, template, "{{name}}", "Developer");
    defer allocator.free(name_replaced);
    const final_prompt = try llm.prompt.PromptUtils.replaceAll(allocator, name_replaced, "{{project}}", "RigorStd");
    defer allocator.free(final_prompt);
    
    std.debug.print("   - Template: {s}\n", .{template});
    std.debug.print("   - Result: {s}\n\n", .{final_prompt});


    // --- 3. STREAMING INTERFACE EXPOSURE ---
    std.debug.print("3. Testing Streaming Interface...\n", .{});
    const stream_msgs = [_]llm.provider.Message{
        .{ .role = .user, .content = "Write a short poem about Zig." },
    };
    
    std.debug.print("   - AI Streaming: ", .{});
    try llm.provider.Provider.streamChat(
        ollama,
        allocator,
        api_key,
        &stream_msgs,
        config.RequestConfig{},
        tokenPrinter,
    );
    std.debug.print("\n\n", .{});


    // --- 4. FULL RAG & PLAYGROUND INTEGRATION ---
    std.debug.print("4. Testing Full Pipeline Integration...\n", .{});
    var store = try mem_store.init(allocator);
    defer store.deinit();
    
    var pg = playground.init(allocator);
    defer pg.deinit();

    // Use a specific session
    _ = try pg.createSession("dev-session");
    pg.setSession("dev-session");

    // Ingest a specific technical fact
    const tech_fact = "The memory model of RigorStd uses explicit allocators for every call.";
    try llm.rag.ingest(allocator, ollama, openai_embed, mem_store, &store, api_key, tech_fact);

    // Hybrid Query: Retrieve context + Session History + LLM
    const query = "What does the memory model use?";
    
    // We manually build the augmented prompt to show how it's done in the backend
    const context = try llm.rag.query(allocator, ollama, openai_embed, mem_store, &store, api_key, query);
    defer allocator.free(context);

    var final_builder = try std.ArrayList(u8).initCapacity(allocator, 0);
    defer final_builder.deinit(allocator);
    try final_builder.appendSlice(allocator, "Context: ");
    try final_builder.appendSlice(allocator, context);
    try final_builder.appendSlice(allocator, "\nQuestion: ");
    try final_builder.appendSlice(allocator, query);

    const response = try pg.chat(ollama, api_key, final_builder.items, config.RequestConfig{ .temperature = 0.1 });
    defer allocator.free(response);

    std.debug.print("   - RAG-Augmented Response: {s}\n", .{response});
    std.debug.print("\n=== Demo Complete ===\n", .{});
}
