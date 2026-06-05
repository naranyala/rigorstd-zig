const std = @import("std");
const llm = @import("src/llm/root.zig");
const playground = @import("src/llm/playground/root.zig").Playground;
const ollama = @import("src/llm/provider/ollama.zig").Ollama;
const mem_store = @import("src/llm/vectorstore/memory.zig").MemoryStore;
const config = @import("src/llm/config.zig");

test "Full RAG Playground Integration" {
    const allocator = std.heap.page_allocator;
    
    // Setup Vector Store
    var store = try mem_store.init(allocator);
    defer store.deinit();

    // Setup Playground
    var pg = playground.init(allocator);
    defer pg.deinit();

    _ = try pg.createSession("test-session");
    pg.setSession("test-session");

    // 1. Test RAG Ingestion
    const doc = "The secret code is 12345. Zig is fast.";
    try llm.rag.ingest(
        allocator,
        ollama,
        @import("src/llm/embedding/openai.zig").OpenAI, // Mix and match providers
        mem_store,
        &store,
        "mock-key",
        doc,
    );

    // 2. Test RAG Query via Playground
    const query_text = "What is the secret code?";
    _ = config.RequestConfig{};
    
    // We manually use the RAG query here since the playground.chat 
    // currently doesn't call RAG (it's just a chat interface)
    const answer = try llm.rag.query(
        allocator,
        ollama,
        @import("src/llm/embedding/openai.zig").OpenAI,
        mem_store,
        &store,
        "mock-key",
        query_text,
    );
    defer allocator.free(answer);

    // Since our providers are mocks, we just verify the pipeline executed
    try std.testing.expect(answer.len > 0);
}

test "Playground Session Switching" {
    const allocator = std.heap.page_allocator;
    var pg = playground.init(allocator);
    defer pg.deinit();

    _ = try pg.createSession("S1");
    _ = try pg.createSession("S2");

    pg.setSession("S1");
    _ = try pg.chat(ollama, "key", "Hello S1", config.RequestConfig{});
    
    pg.setSession("S2");
    _ = try pg.chat(ollama, "key", "Hello S2", config.RequestConfig{});
    
    const s1 = pg.sessions.get("S1").?;
    const s2 = pg.sessions.get("S2").?;
    
    try std.testing.expectEqual(s1.*.getMessages().len, 2); // User + AI
    try std.testing.expectEqual(s2.*.getMessages().len, 2); // User + AI
}
