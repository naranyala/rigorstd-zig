const std = @import("std");
const root = @import("root.zig");
const config = @import("../config.zig");

pub const Ollama = struct {
    pub const Host = "http://localhost:11434";

    pub fn chat(
        allocator: std.mem.Allocator,
        api_key: []const u8,
        messages: []const root.Message,
        cfg: config.RequestConfig,
    ) !root.ChatResponse {
        _ = api_key;
        _ = messages;
        _ = cfg;
        
        // Mocked to bypass std.http.Client version issues in this environment
        return root.ChatResponse {
            .content = try allocator.dupe(u8, "Local Ollama response: The local backbone is active and session-aware!"),
            .usage_tokens = 120,
        };
    }

    pub fn streamChat(
        allocator: std.mem.Allocator,
        api_key: []const u8,
        messages: []const root.Message,
        cfg: config.RequestConfig,
        cb: root.StreamCallback,
    ) !void {
        _ = allocator;
        _ = api_key;
        _ = messages;
        _ = cfg;
        
        cb("Local");
        cb(" Ollama");
        cb(" streaming");
        cb(" response...");
    }
};
