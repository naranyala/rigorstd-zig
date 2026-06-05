const std = @import("std");

pub const RequestConfig = struct {
    temperature: f32 = 0.7,
    top_p: f32 = 0.9,
    max_tokens: u32 = 2048,
    stop_sequences: []const []const u8 = &.{},
    presence_penalty: f32 = 0.0,
    frequency_penalty: f32 = 0.0,
};
