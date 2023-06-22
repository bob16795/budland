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

        container: ?*const Container,
        igapps: i32,
        ogapps: i32,
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

    pub const Container = struct {
        x_start: f32,
        y_start: f32,
        x_end: f32,
        y_end: f32,
        children: []*const Container,
        name: []const u8,
        ids: []const u8,
    };

    containers: std.StringHashMap(Container),
    autoexec: []AutoExec,
    monrules: []MonitorRule,
    rules: []Rule,
    layouts: []Layout,
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
            .layouts = try allocator.alloc(Layout, 0),
            .keys = try allocator.alloc(KeyBind, 1),
            .buttons = try allocator.alloc(MouseBind, 0),
            .autoexec = try allocator.alloc(AutoExec, 0),
            .containers = std.StringHashMap(Container).init(allocator),
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
                } else if (std.mem.eql(u8, cmd, "container")) {
                    var name = try allocator.dupeZ(u8, splitIter.next() orelse return error.NoCommand);
                    var conKind = splitIter.next() orelse return error.NoCommand;
                    if (std.mem.eql(u8, conKind, "client")) {
                        var id = try std.fmt.parseInt(u8, splitIter.next() orelse "0", 0);
                        var x1 = try std.fmt.parseFloat(f32, splitIter.next() orelse "0");
                        var y1 = try std.fmt.parseFloat(f32, splitIter.next() orelse "0");
                        var x2 = try std.fmt.parseFloat(f32, splitIter.next() orelse "0");
                        var y2 = try std.fmt.parseFloat(f32, splitIter.next() orelse "0");
                        try result.containers.put(name, .{
                            .name = name,
                            .x_start = x1,
                            .y_start = y1,
                            .x_end = x2,
                            .y_end = y2,
                            .ids = try allocator.dupe(u8, &.{id}),
                            .children = &.{},
                        });
                    } else if (std.mem.eql(u8, conKind, "multi")) {
                        var x1 = try std.fmt.parseFloat(f32, splitIter.next() orelse "0");
                        var y1 = try std.fmt.parseFloat(f32, splitIter.next() orelse "0");
                        var x2 = try std.fmt.parseFloat(f32, splitIter.next() orelse "0");
                        var y2 = try std.fmt.parseFloat(f32, splitIter.next() orelse "0");
                        var ids = std.ArrayList(u8).init(allocator);
                        var children = std.ArrayList(*Container).init(allocator);
                        defer ids.deinit();
                        defer children.deinit();

                        while (splitIter.next()) |conName| {
                            if (result.containers.getPtr(conName)) |child| {
                                try ids.appendSlice(child.ids);
                                try children.append(child);
                            } else {
                                return error.NoCommand;
                            }
                        }

                        try result.containers.put(name, .{
                            .name = name,
                            .x_start = x1,
                            .y_start = y1,
                            .x_end = x2,
                            .y_end = y2,
                            .ids = try allocator.dupe(u8, ids.items),
                            .children = try allocator.dupe(*Container, children.items),
                        });
                    } else {
                        return error.NoCommand;
                    }
                } else if (std.mem.eql(u8, cmd, "layout")) {
                    var conName = splitIter.next() orelse return error.NoCommand;
                    var container = result.containers.getPtr(conName) orelse return error.NoContainer;
                    var ig = try std.fmt.parseInt(u8, splitIter.next() orelse "0", 0);
                    var og = try std.fmt.parseInt(u8, splitIter.next() orelse "0", 0);
                    var name = splitIter.next() orelse return error.NoCommand;

                    result.layouts = try allocator.realloc(result.layouts, result.layouts.len + 1);
                    result.layouts[result.layouts.len - 1] = .{
                        .symbol = try allocator.dupe(u8, name),
                        .container = container,
                        .igapps = ig,
                        .ogapps = og,
                    };
                } else {
                    return error.NoCommand;
                }
            }
        }

        return result;
    }
};
