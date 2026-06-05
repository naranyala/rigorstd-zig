# RigorStd-Zig

RigorStd-Zig is a high-performance standard library implemented in Zig, specifically designed for Large Language Model (LLM) operations and Retrieval-Augmented Generation (RAG) systems. It leverages Zig's comptime generics and explicit memory management to provide zero-overhead abstractions for AI orchestration.

## Key Features

### 1. Provider Agnostic Interface
The library provides a unified interface for interacting with various LLM backends. It supports:
- Remote providers (e.g., OpenAI).
- Local backbones (e.g., Ollama).
- Custom implementations via the Provider trait.

### 2. RAG Pipeline
A complete pipeline for implementing retrieval-augmented generation:
- Recursive Chunking: Intelligent text splitting that preserves semantic boundaries.
- Embedding Interface: Standardized vectorization of text.
- Vector Store: In-memory cosine-similarity search for rapid context retrieval.

### 3. Session and State Management
Designed for playground and production environments:
- Stateful History: Tracks conversation turns per session.
- Session Routing: Manage multiple users or projects within a single orchestrator.
- Hyperparameter Control: Per-request configuration for temperature, top_p, and token limits.

### 4. Zero-Cost Abstractions
Using Zig's comptime system, the library resolves provider types at compile-time, ensuring that there is no runtime dispatch overhead when calling LLM functions.

## Project Structure

```text
src/llm/
├── provider/       # LLM API abstractions and implementations (OpenAI, Ollama)
├── embedding/      # Text embedding interfaces
├── vectorstore/    # Vector database implementations (MemoryStore)
├── rag/            # RAG orchestration and text chunking strategies
├── session/        # Chat history and session state management
├── playground/     # High-level orchestrator for managing multiple sessions
├── config.zig      # Unified request hyperparameters
└── root.zig        # Main library entry point
examples/           # Implementation guides and showcase apps
tests/              # Unit and integration test suites
```

## Getting Started

### Prerequisites
- Zig 0.16.0 or compatible version.
- A local Ollama instance (for local provider tests) or an OpenAI API key.

### Running Examples
The project includes a set of examples to demonstrate different capabilities:

```bash
# Basic Chat
zig run examples/01_basic_chat.zig

# Simple RAG implementation
zig run examples/02_simple_rag.zig

# Local Playground with session management
zig run examples/03_local_playground.zig

# Creating a custom provider
zig run examples/04_custom_provider.zig

# Advanced AI Assistant (Full integration)
zig run examples/05_advanced_assistant.zig

# Technical Kitchen Sink (Streaming and Chunking)
zig run examples/06_kitchen_sink.zig
```

## Extending the Library

### Adding a New Provider
To add a new LLM provider, implement a struct that follows the Provider interface:

```zig
pub const MyProvider = struct {
    pub fn chat(
        allocator: std.mem.Allocator,
        api_key: []const u8,
        messages: []const llm.provider.Message,
        cfg: llm.config.RequestConfig,
    ) !llm.provider.ChatResponse {
        // Implementation here
    }
};
```

## Testing
The library includes unit tests for core logic and integration tests for the full pipeline.

```bash
# Run unit tests for memory store
zig test src/llm/vectorstore/memory.zig

# Run unit tests for chunker
zig test src/llm/rag/chunker.zig

# Run integration tests
cd tests && zig test integration_test.zig
```

## License
This project is licensed under the MIT License.
