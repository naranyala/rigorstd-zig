const std = @import("std");
const llm = @import("src/llm/root.zig");
const openai_prov = @import("src/llm/provider/openai.zig").OpenAI;
const openai_embed = @import("src/llm/embedding/openai.zig").OpenAI;
const mem_store = @import("src/llm/vectorstore/memory.zig").MemoryStore;

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const api_key = "your-api-key";

    // 1. Setup Vector Store
    var store = try mem_store.init(allocator);
    defer store.deinit();

    // 2. Knowledge Base
    const knowledge = 
        \\The project 'RigorStd' is a high-performance Zig library for LLMs.\\
        \\It supports local backbones like Ollama and remote ones like OpenAI.\\
        \\The core design focuses on comptime generics and zero-cost abstractions.\\
    ;

    std.debug.print("Ingesting knowledge base...\n", .{});
    try llm.rag.ingest(
        allocator,
        openai_prov,
        openai_embed,
        mem_store,
        &store,
        api_key,
        knowledge,
    );

    // 3. Perform a context-aware query
    const query = "What is RigorStd and what does it focus on?";
    std.debug.print("Query: {s}\n", .{query});

    const answer = try llm.rag.query(
        allocator,
        openai_prov,
        openai_embed,
        mem_store,
        &store,
        api_key,
        query,
    );
    defer allocator.free(answer);

    std.debug.print("AI Answer: {s}\n", .{answer});
}
