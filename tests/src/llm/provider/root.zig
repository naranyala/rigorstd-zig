const std = @import("std");
const config = @import("../config.zig");

pub const Role = enum {
    system,
    user,
    assistant,
};

pub const Message = struct {
    role: Role,
    content: []const u8,
};

pub const ChatResponse = struct {
    content: []const u8,
    usage_tokens: u32,
    
    pub fn deinit(self: *const ChatResponse, allocator: std.mem.Allocator) void {
        allocator.free(self.content);
    }
};

/// StreamCallback is called every time a new token is received
pub const StreamCallback = *const fn (token: []const u8) void;

/// Provider interface:
/// A type that implements this interface must provide:
/// pub fn chat(allocator: std.mem.Allocator, api_key: []const u8, messages: []const Message, cfg: config.RequestConfig) !ChatResponse
/// pub fn streamChat(allocator: std.mem.Allocator, api_key: []const u8, messages: []const Message, cfg: config.RequestConfig, cb: StreamCallback) !void
pub const Provider = struct {
    pub fn chat(
        comptime T: type, 
        allocator: std.mem.Allocator, 
        api_key: []const u8, 
        messages: []const Message,
        cfg: config.RequestConfig,
    ) !ChatResponse {
        return T.chat(allocator, api_key, messages, cfg);
    }

    pub fn streamChat(
        comptime T: type,
        allocator: std.mem.Allocator,
        api_key: []const u8,
        messages: []const Message,
        cfg: config.RequestConfig,
        cb: StreamCallback,
    ) !void {
        try T.streamChat(allocator, api_key, messages, cfg, cb);
    }
};
