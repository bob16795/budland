const std = @import("std");
const main = @import("main.zig");
const c = @import("c.zig");

const gappso = 40;
const gappsi = 15;

pub const Config = struct {
    const Self = @This();

    pub const Arg = union {
        i: i32,
        ui: u32,
        f: f32,
        v: []const []const u8,
    };

    const Command = struct {
        arg: Arg = .{ .i = 0 },
        func: ?*const fn (*const Arg) void = null,

        pub fn run(self: Command) void {
            if (self.func) |runner|
                runner(&self.arg);
        }
    };

    pub const Layout = struct {
        symbol: []const u8,

        arrange: ?*const fn (*main.Monitor) void,
    };

    const AutoExec = struct {
        cmd: Command,
    };

    const KeyBind = struct {
        mod: u32 = 0,
        keysym: c.xkb_keysym_t,
        cmd: Command,
    };

    const MouseBind = struct {
        mod: u32 = 0,
        button: u32,
        cmd: Command,
    };

    const Rule = struct {
        id: ?[]const u8 = null,
        title: ?[]const u8 = null,
        tags: u32 = 0,
        container: u8 = 0,
        center: bool = false,
        isfloating: bool = false,
        monitor: i32 = -1,
    };

    const MonitorRule = struct {
        name: ?[:0]const u8,
        scale: f32,
        rr: c.wl_output_transform,
        x: i32,
        y: i32,
    };

    flags: packed struct {
        sloppyFocus: bool = false,
    } = .{},

    autoexec: []AutoExec,
    monrules: []MonitorRule,
    rules: []Rule,
    layouts: []const Layout,
    keys: []KeyBind,
    buttons: []MouseBind,

    pub fn toCommand(iter: *std.mem.SplitIterator(u8, .sequence), allocator: std.mem.Allocator) !Command {
        var cmd = iter.next() orelse "???";

        if (std.mem.eql(u8, cmd, "spawn")) {
            var args = try allocator.alloc([]const u8, 0);
            while (iter.next()) |arg| {
                args = try allocator.realloc(args, args.len + 1);
                args[args.len - 1] = try allocator.dupe(u8, arg);
            }

            return .{
                .func = main.spawn,
                .arg = .{
                    .v = args,
                },
            };
        } else if (std.mem.eql(u8, cmd, "killclient")) {
            return .{
                .func = main.killclient,
            };
        } else if (std.mem.eql(u8, cmd, "focusstack")) {
            return .{
                .func = main.focusstack,
                .arg = .{ .i = try std.fmt.parseInt(i32, iter.next() orelse "0", 0) },
            };
        }

        return error.NoCommand;
    }

    const KeyData = struct {
        keysym: c.xkb_keysym_t,
        mod: u32 = 0,
    };

    pub fn getKey(code: []const u8) !KeyData {
        var iter = std.mem.split(u8, code, "+");
        var result: KeyData = .{
            .keysym = 0,
            .mod = 0,
        };

        while (iter.next()) |key| {
            if (std.mem.eql(u8, key, "LOGO")) {
                result.mod |= c.WLR_MODIFIER_LOGO;
            } else if (std.mem.eql(u8, key, "SHIFT")) {
                result.mod |= c.WLR_MODIFIER_SHIFT;
            } else if (std.mem.eql(u8, key, "ALT")) {
                result.mod |= c.WLR_MODIFIER_ALT;
            } else if (std.mem.eql(u8, key, "Tab")) {
                result.keysym = c.XKB_KEY_Tab;
            } else if (std.mem.eql(u8, key, "Return")) {
                result.keysym = c.XKB_KEY_Return;
            } else if (key.len == 1) {
                result.keysym = @intCast(u32, c.XKB_KEY_a + std.ascii.toLower(key[0]) - 'a');
            } else {
                std.log.info("{s}", .{key});
                return error.InvalidKey;
            }
        }

        return result;
    }

    pub fn source(path: []const u8, allocator: std.mem.Allocator) !Self {
        var result: Self = .{
            .monrules = try allocator.alloc(MonitorRule, 0),
            .rules = try allocator.alloc(Rule, 0),
            .layouts = &.{
                .{ .symbol = "B ---", .arrange = main.bud(0, 0, &main.ContainersB) },
                .{ .symbol = "B [+]", .arrange = main.bud(gappsi, gappso, &main.ContainersB) },
            },
            .keys = try allocator.alloc(KeyBind, 1),
            .buttons = try allocator.alloc(MouseBind, 0),
            .autoexec = try allocator.alloc(AutoExec, 0),
        };

        result.keys[0] = .{ .mod = c.WLR_MODIFIER_LOGO | c.WLR_MODIFIER_SHIFT, .keysym = c.XKB_KEY_Escape, .cmd = .{ .func = main.quit, .arg = .{ .i = 0 } } };

        const home = std.os.getenv("HOME") orelse "";

        var file = (try std.fs.openDirAbsolute(home, .{})).openFile(path, .{}) catch return result;
        defer file.close();

        var buf_reader = std.io.bufferedReader(file.reader());
        var in_stream = buf_reader.reader();

        var buff: [1024]u8 = undefined;
        while (try in_stream.readUntilDelimiterOrEof(&buff, '\n')) |line| {
            var comment = std.mem.split(u8, line, "#");
            const stripped = std.mem.trim(u8, comment.first(), &std.ascii.whitespace);
            if (stripped.len != 0) {
                var splitIter = std.mem.split(u8, stripped, " ");
                const cmd = splitIter.next() orelse "???";
                if (std.mem.eql(u8, cmd, "bind")) {
                    var binds = splitIter.next() orelse return error.NoCommand;
                    var command = try toCommand(&splitIter, allocator);
                    var key = try getKey(binds);
                    result.keys = try allocator.realloc(result.keys, result.keys.len + 1);
                    result.keys[result.keys.len - 1] = .{
                        .mod = key.mod,
                        .keysym = key.keysym,
                        .cmd = command,
                    };
                } else if (std.mem.eql(u8, cmd, "autoexec")) {
                    var command = try toCommand(&splitIter, allocator);
                    result.autoexec = try allocator.realloc(result.autoexec, result.autoexec.len + 1);
                    result.autoexec[result.autoexec.len - 1] = .{
                        .cmd = command,
                    };
                } else if (std.mem.eql(u8, cmd, "monitor")) {
                    var name = try allocator.dupeZ(u8, splitIter.next() orelse return error.NoCommand);
                    var scale: f32 = 1.0;
                    var rr: c_uint = c.WL_OUTPUT_TRANSFORM_NORMAL;
                    var x = try std.fmt.parseInt(i32, splitIter.next() orelse "0", 0);
                    var y = try std.fmt.parseInt(i32, splitIter.next() orelse "0", 0);
                    result.monrules = try allocator.realloc(result.monrules, result.monrules.len + 1);
                    result.monrules[result.monrules.len - 1] = .{
                        .name = if (std.mem.eql(u8, name, "default")) null else name,
                        .scale = scale,
                        .rr = rr,
                        .x = x,
                        .y = y,
                    };
                } else {
                    return error.NoCommand;
                }
            }
        }

        return result;
    }
};
