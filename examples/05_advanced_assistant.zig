const std = @import("std");
const llm = @import("src/llm/root.zig");
const ollama = @import("src/llm/provider/ollama.zig").Ollama;
const openai_embed = @import("src/llm/embedding/openai.zig").OpenAI;
const mem_store = @import("src/llm/vectorstore/memory.zig").MemoryStore;
const playground = @import("src/llm/playground/root.zig").Playground;
const config = @import("src/llm/config.zig");

/// The 'Assistant' is a high-level orchestrator that combines 
/// Knowledge (RAG) and Memory (Sessions).
pub const Assistant = struct {
    allocator: std.mem.Allocator,
    pg: playground.Playground,
    store: *mem_store.MemoryStore,
    api_key: []const u8,

    pub fn init(allocator: std.mem.Allocator, api_key: []const u8) !Assistant {
        var store = try mem_store.init(allocator);
        const store_ptr = try allocator.create(mem_store.MemoryStore);
        store_ptr.* = store;

        return .{
            .allocator = allocator,
            .pg = playground.init(allocator),
            .store = store_ptr,
            .api_key = api_key,
        };
    }

    pub fn deinit(self: *Assistant) void {
        self.pg.deinit();
        self.store.*.deinit();
        self.allocator.destroy(self.store);
    }

    pub fn addKnowledge(self: *Assistant, text: []const u8) !void {
        std.debug.print("[System] Indexing new knowledge...\n", .{});
        try llm.rag.ingest(
            self.allocator,
            ollama,
            openai_embed,
            mem_store,
            self.store,
            self.api_key,
            text,
        );
    }

    pub fn ask(self: *Assistant, session_id: []const u8, query: []const u8) ![]const u8 {
        // 1. Ensure session exists
        if (self.pg.sessions.get(session_id) == null) {
            _ = try self.pg.createSession(session_id);
        }
        self.pg.setSession(session_id);

        // 2. Retrieve relevant context from VectorStore (The RAG part)
        const context = try llm.rag.query(
            self.allocator,
            ollama,
            openai_embed,
            mem_store,
            self.store,
            self.api_key,
            query,
        );
        defer self.allocator.free(context);

        // 3. Construct an augmented prompt using the context
        var prompt_builder = try std.ArrayList(u8).initCapacity(self.allocator, 0);
        defer prompt_builder.deinit(self.allocator);
        
        try prompt_builder.appendSlice(self.allocator, "Relevant Context: ");
        try prompt_builder.appendSlice(self.allocator, context);
        try prompt_builder.appendSlice(self.allocator, "\n\nUser Question: ");
        try prompt_builder.appendSlice(self.allocator, query);

        // 4. Use the Playground to chat with the augmented prompt
        // This ensures the la-AI sees the context AND the session history
        const final_response = try self.pg.chat(
            ollama,
            self.api_key,
            prompt_builder.items,
            config.RequestConfig { .temperature = 0.3 },
        );

        return final_response;
    }
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var assistant = try Assistant.init(allocator, "sk-mock-key");
    defer assistant.deinit();

    // --- Phase 1: Load Knowledge ---
    const docs = [_][]const u8 {
        "The company 'ZigCorp' was founded in 2026 to build the world's fastest LLM stdlib.",
        "ZigCorp's headquarters are located in the Cloud City of Neo-Tokyo.",
        "The CEO of ZigCorp is a robot named 'Ziggy'.",
    };

    for (docs) |doc| {
        try assistant.addKnowledge(doc);
    }

    // --- Phase 2: Interactive Session ---
    const session_name = "user-123";
    
    // Turn 1: RAG query
    const q1 = "Who is the CEO of ZigCorp?";
    std.debug.print("\nUser: {s}\n", .{q1});
    const a1 = try assistant.ask(session_name, q1);
    defer allocator.free(a1);
    std.debug.print("Assistant: {s}\n", .{a1});

    // Turn 2: Memory query (Context check)
    const q2 = "Where is the company located?";
    std.debug.print("\nUser: {s}\n", .{q2});
    const a2 = try assistant.ask(session_name, q2);
    defer allocator.free(a2);
    std.debug.print("Assistant: {s}\n", .{a2});

    // Turn 3: History check
    const q3 = "What was the first question I asked you?";
    std.debug.print("\nUser: {s}\n", .{q3});
    const a3 = try assistant.ask(session_name, q3);
    defer allocator.free(a3);
    std.debug.print("Assistant: {s}\n", .{a3});
}
