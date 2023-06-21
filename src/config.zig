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
        name: ?[]const u8 = null,
        icon: ?[]const u8 = null,
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
        } else if (std.mem.eql(u8, cmd, "view")) {
            return .{
                .func = main.view,
                .arg = .{ .ui = std.math.pow(u32, 2, try std.fmt.parseInt(u32, iter.next() orelse "0", 0)) },
            };
        } else if (std.mem.eql(u8, cmd, "reload")) {
            return .{
                .func = main.reload,
            };
        } else if (std.mem.eql(u8, cmd, "resize")) {
            return .{
                .func = main.moveresize,
                .arg = .{ .ui = @enumToInt(main.Cursors.CurResize) },
            };
        } else if (std.mem.eql(u8, cmd, "move")) {
            return .{
                .func = main.moveresize,
                .arg = .{ .ui = @enumToInt(main.Cursors.CurMove) },
            };
        } else if (std.mem.eql(u8, cmd, "fullscreen")) {
            return .{
                .func = main.togglefullscreen,
            };
        } else if (std.mem.eql(u8, cmd, "togglefloating")) {
            return .{
                .func = main.togglefloating,
            };
        } else if (std.mem.eql(u8, cmd, "cyclelayout")) {
            return .{
                .func = main.cyclelayout,
                .arg = .{ .i = try std.fmt.parseInt(i32, iter.next() orelse "0", 0) },
            };
        } else if (std.mem.eql(u8, cmd, "sendcon")) {
            return .{
                .func = main.setcon,
                .arg = .{ .ui = try std.fmt.parseInt(u32, iter.next() orelse "0", 0) },
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

    pub fn getMouse(code: []const u8) !KeyData {
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
            } else if (std.mem.eql(u8, key, "Left")) {
                result.keysym = c.BTN_LEFT;
            } else if (std.mem.eql(u8, key, "Right")) {
                result.keysym = c.BTN_RIGHT;
            } else {
                std.log.info("{s}", .{key});
                return error.InvalidKey;
            }
        }

        return result;
    }

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
            } else if (std.mem.eql(u8, key, "Space")) {
                result.keysym = c.XKB_KEY_space;
            } else if (std.mem.eql(u8, key, "Return")) {
                result.keysym = c.XKB_KEY_Return;
            } else if (std.mem.eql(u8, key, "F1")) {
                result.keysym = c.XKB_KEY_F1;
            } else if (std.mem.eql(u8, key, "F2")) {
                result.keysym = c.XKB_KEY_F2;
            } else if (std.mem.eql(u8, key, "F3")) {
                result.keysym = c.XKB_KEY_F3;
            } else if (std.mem.eql(u8, key, "F4")) {
                result.keysym = c.XKB_KEY_F4;
            } else if (key.len == 1) {
                if (std.ascii.isAlphabetic(key[0])) {
                    if (result.mod & c.WLR_MODIFIER_SHIFT != 0) {
                        result.keysym = @intCast(u32, c.XKB_KEY_A + std.ascii.toLower(key[0]) - 'a');
                    } else {
                        result.keysym = @intCast(u32, c.XKB_KEY_a + std.ascii.toLower(key[0]) - 'a');
                    }
                } else if (std.ascii.isDigit(key[0])) {
                    if (result.mod & c.WLR_MODIFIER_SHIFT != 0) {
                        const shift = [_]u32{ c.XKB_KEY_topleftparens, c.XKB_KEY_exclam, c.XKB_KEY_at, c.XKB_KEY_numbersign, c.XKB_KEY_dollar };
                        result.keysym = shift[std.ascii.toLower(key[0]) - '0'];
                    } else {
                        result.keysym = @intCast(u32, c.XKB_KEY_0 + std.ascii.toLower(key[0]) - '0');
                    }
                } else {
                    std.log.info("{s}", .{key});
                    return error.InvalidKey;
                }
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
                .{ .symbol = "---", .arrange = main.bud(0, 0, &main.ContainersB) },
                .{ .symbol = "[+]", .arrange = main.bud(gappsi, gappso, &main.ContainersB) },
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
                } else if (std.mem.eql(u8, cmd, "mouse")) {
                    var binds = splitIter.next() orelse return error.NoCommand;
                    var command = try toCommand(&splitIter, allocator);
                    var key = try getMouse(binds);
                    result.buttons = try allocator.realloc(result.buttons, result.buttons.len + 1);
                    result.buttons[result.buttons.len - 1] = .{
                        .mod = key.mod,
                        .button = key.keysym,
                        .cmd = command,
                    };
                } else if (std.mem.eql(u8, cmd, "autoexec")) {
                    var command = try toCommand(&splitIter, allocator);
                    result.autoexec = try allocator.realloc(result.autoexec, result.autoexec.len + 1);
                    result.autoexec[result.autoexec.len - 1] = .{
                        .cmd = command,
                    };
                } else if (std.mem.eql(u8, cmd, "rule")) {
                    var id: ?[]const u8 = splitIter.next() orelse return error.NoCommand;
                    if (std.mem.eql(u8, id.?, "_")) id = null;
                    var title: ?[]const u8 = splitIter.next() orelse return error.NoCommand;
                    if (std.mem.eql(u8, title.?, "_")) title = null;
                    var name: ?[]const u8 = splitIter.next() orelse return error.NoCommand;
                    if (std.mem.eql(u8, name.?, "_")) name = null;
                    var icon: ?[]const u8 = splitIter.next() orelse return error.NoCommand;
                    if (std.mem.eql(u8, icon.?, "_")) icon = null;
                    var tags = try std.fmt.parseInt(u32, splitIter.next() orelse "0", 0);
                    var container = try std.fmt.parseInt(u8, splitIter.next() orelse "0", 0);
                    var center = std.ascii.eqlIgnoreCase("true", splitIter.next() orelse return error.NoCommand);
                    var floating = std.ascii.eqlIgnoreCase("true", splitIter.next() orelse return error.NoCommand);
                    var monitor = try std.fmt.parseInt(i32, splitIter.next() orelse "0", 0);
                    result.rules = try allocator.realloc(result.rules, result.rules.len + 1);
                    result.rules[result.rules.len - 1] = .{
                        .id = if (id) |i| try allocator.dupe(u8, i) else null,
                        .title = if (title) |i| try allocator.dupe(u8, i) else null,
                        .name = if (name) |i| try allocator.dupeZ(u8, i) else null,
                        .icon = if (icon) |i| try allocator.dupeZ(u8, i) else null,
                        .tags = tags,
                        .container = container,
                        .center = center,
                        .isfloating = floating,
                        .monitor = monitor,
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
