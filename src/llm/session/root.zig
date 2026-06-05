const std = @import("std");
const provider = @import("../provider/root.zig");

pub const Session = struct {
    id: []const u8,
    history: std.ArrayList(provider.Message),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, id: []const u8) Session {
        return .{
            .id = id, // We'll assume the caller manages the lifetime or it's a literal
            .history = std.ArrayList(provider.Message){ .items = &[_]provider.Message{}, .capacity = 0 },
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Session) void {
        self.history.deinit(self.allocator);
    }

    pub fn addMessage(self: *Session, role: provider.Role, content: []const u8) !void {
        try self.history.append(self.allocator, .{
            .role = role,
            .content = try self.allocator.dupe(u8, content),
        });
    }

    pub fn clearHistory(self: *Session) void {
        for (self.history.items) |msg| {
            self.allocator.free(msg.content);
        }
        self.history.clearRetainingCapacity();
    }

    pub fn getMessages(self: *Session) []const provider.Message {
        return self.history.items;
    }
};

test "Session history" {
    const allocator = std.heap.page_allocator;
    var s = Session.init(allocator, "test-session");
    defer s.deinit();

    try s.addMessage(.user, "Hello");
    try s.addMessage(.assistant, "Hi there!");

    const messages = s.getMessages();
    try std.testing.expectEqual(messages.len, 2);
    try std.testing.expectEqualStrings(messages[0].content, "Hello");
    try std.testing.expectEqualStrings(messages[1].content, "Hi there!");

    s.clearHistory();
    try std.testing.expectEqual(s.getMessages().len, 0);
}
