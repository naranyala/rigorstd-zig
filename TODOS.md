# Development Roadmap: RigorStd-Zig

This document tracks the missing features and planned enhancements required to move RigorStd-Zig from a prototype to a production-ready LLM standard library.

## 🟥 High Priority (Core Infrastructure)

### 1. Robust Connectivity
- [ ] Integrate a professional JSON library for request/response serialization.
- [ ] Implement a `HttpClient` wrapper with support for:
    - Automatic retries with exponential backoff.
    - Request timeouts and cancellation.
    - Proper HTTP header management.
- [ ] Replace mock implementations in `provider/openai.zig` and `provider/ollama.zig` with real API calls.

### 2. Vector Store Persistence
- [ ] Implement `DiskStore`: A simple binary format to save and load `MemoryStore` indices.
- [ ] Implement `QdrantProvider`: Integration with an external vector database for production scaling.
- [ ] Replace linear scan search with an efficient indexing algorithm (e.g., HNSW).

## 🟧 Medium Priority (RAG & LLM Logic)

### 1. Advanced RAG Features
- [ ] Implement Hybrid Search: Combine BM25 (keyword) and Cosine Similarity (semantic).
- [ ] Implement a Re-ranking stage: Integrate a Cross-Encoder to refine Top-K results.
- [ ] Expand `Chunker`:
    - Support for Markdown-aware splitting.
    - Implementation of Semantic Chunking (splitting based on embedding distance).

### 2. LLM Capability Expansion
- [ ] Tool Use / Function Calling: Add support for the `tools` API in providers to allow LLMs to execute Zig functions.
- [ ] Streaming Support: Fully implement the `StreamCallback` in real providers.
- [ ] Support for additional providers: Anthropic (Claude), Mistral, and Azure OpenAI.

### 3. Context Management
- [ ] Context Windowing: Implement a sliding window for `Session` history.
- [ ] Conversation Summarization: Automatically summarize old history when the token limit is reached.

## 🟩 Low Priority (DX & Ecosystem)

### 1. Developer Experience
- [ ] Implement `.env` support for secure API key management.
- [ ] Add a CLI tool for testing embeddings and queries from the terminal.
- [ ] Improve error types: Replace `!void` with a custom `LlmError` enum for better debugging.

### 2. Expanded Examples
- [ ] `examples/07_cli_assistant`: A real-world CLI application using the library.
- [ ] `examples/08_web_api`: A basic HTTP server (using a Zig web framework) that exposes the LLM.
- [ ] `examples/09_document_qa`: An example focusing on processing large PDF/Text files.

## 🛠 Technical Debt
- [ ] Replace `std.heap.page_allocator` in examples with `GeneralPurposeAllocator` for better leak detection.
- [ ] Refactor `Sesssion` to support asynchronous message processing.
- [ ] Standardize error handling across all modules.
