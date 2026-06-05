const std = @import("std");
const provider = @import("../provider/root.zig");
const session = @import("../session/root.zig");
const config = @import("../config.zig");

pub const Playground = struct {
    allocator: std.mem.Allocator,
    sessions: std.StringHashMap(*session.Session),
    current_session_id: ?[]const u8 = null,

    pub fn init(allocator: std.mem.Allocator) Playground {
        return .{
            .allocator = allocator,
            .sessions = std.StringHashMap(*session.Session).init(allocator),
        };
    }

    pub fn deinit(self: *Playground) void {
        var it = self.sessions.iterator();
        while (it.next()) |entry| {
            const s = entry.value_ptr;
            s.*.deinit();
            self.allocator.free(s.*.id);
            self.allocator.destroy(s);
        }
        self.sessions.deinit();
    }

    pub fn createSession(self: *Playground, id: []const u8) !*session.Session {
        const s = try self.allocator.create(session.Session);
        const dupped_id = try self.allocator.dupe(u8, id);
        s.* = session.Session.init(self.allocator, dupped_id);
        try self.sessions.put(dupped_id, s);
        return s;
    }

    pub fn setSession(self: *Playground, id: []const u8) void {
        self.current_session_id = id;
    }

    pub fn chat(
        self: *Playground,
        comptime ProviderType: type,
        api_key: []const u8,
        user_input: []const u8,
        cfg: config.RequestConfig,
    ) ![]const u8 {
        const sid = self.current_session_id orelse return error.NoSessionSelected;
        const s = self.sessions.get(sid) orelse return error.SessionNotFound;

        // Add user message to history
        try s.*.addMessage(.user, user_input);

        // Generate response using the provider
        const response = try provider.Provider.chat(
            ProviderType,
            self.allocator,
            api_key,
            s.*.getMessages(),
            cfg,
        );
        defer response.deinit(self.allocator);

        // Add assistant response to history
        try s.*.addMessage(.assistant, response.content);

        return try self.allocator.dupe(u8, response.content);
    }
};
