const std = @import("std");
const c = @import("c.zig");
const cfg = @import("config.zig");
const ipc = @import("ipc.zig");
const buffers = @import("buffer.zig");

pub var configData: cfg.Config = undefined;

pub var barheight: i32 = 20;
pub var barpadding: i32 = 2;

const sloppyfocus: bool = true;
const bypass_surface_visibility: bool = true;
const bordercolor: [4]f32 = .{ 0.149, 0.137, 0.133, 1.0 };
const focuscolor: [4]f32 = .{ 0.659, 0.392, 0.255, 1.0 };
const inactiveframecolor: [4]f32 = .{ 0.149, 0.137, 0.133, 1.0 };
const activeframecolor: [4]f32 = .{ 0.149, 0.137, 0.133, 1.0 };
const inactivefontcolor: [4]f32 = .{ 0.149, 0.137, 0.133, 1.0 };
const activefontcolor: [4]f32 = .{ 0.149, 0.137, 0.133, 1.0 };
const fullscreen_bg: [4]f32 = .{ 0.149, 0.137, 0.133, 1.0 };
const borderpx: i32 = 2;

pub const tagcount = 4;

const TAGMASK = ((@as(u32, 1) << tagcount) - 1);
const bufferScale = 2.0;

const gappso = 40;
const gappsi = 15;

const natural_scrolling = 0;
const disable_while_typing = 0;
const left_handed = 0;
const middle_button_emulation = 0;

const scroll_method = c.LIBINPUT_CONFIG_SCROLL_2FG;
const click_method = c.LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;
const send_events_mode = c.LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;
const accel_profile = c.LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE;
const accel_speed = 10.0;
const button_map = c.LIBINPUT_CONFIG_TAP_MAP_LRM;

const repeat_rate = 25;
const repeat_delay = 600;

const builtin = @import("builtin");
pub const useclib = true;

pub var gpa = std.heap.GeneralPurposeAllocator(.{ .stack_trace_frames = 10 }){};
pub const allocator = gpa.allocator();

pub const ContainersB = Container{
    .name = "ABCD",
    .x_start = 0.00,
    .y_start = 0.00,
    .x_end = 1.00,
    .y_end = 1.00,
    .ids = &.{ 1, 2, 3, 4 },
    .children = &.{
        .{
            .name = "AC",
            .x_start = 0.00,
            .y_start = 0.00,
            .x_end = 0.70,
            .y_end = 1.00,
            .ids = &.{ 1, 3 },
            .children = &.{
                .{
                    .name = "A",
                    .x_start = 0.00,
                    .y_start = 0.00,
                    .x_end = 1.00,
                    .y_end = 0.20,
                    .ids = &.{1},
                    .children = &.{},
                },
                .{
                    .name = "C",
                    .x_start = 0.00,
                    .y_start = 0.20,
                    .x_end = 1.00,
                    .y_end = 1.00,
                    .ids = &.{3},
                    .children = &.{},
                },
            },
        },
        .{
            .name = "BD",
            .x_start = 0.70,
            .y_start = 0.00,
            .x_end = 1.00,
            .y_end = 1.00,
            .ids = &.{ 2, 4 },
            .children = &.{
                .{
                    .name = "B",
                    .x_start = 0.00,
                    .y_start = 0.00,
                    .x_end = 1.00,
                    .y_end = 0.40,
                    .ids = &.{2},
                    .children = &.{},
                },
                .{
                    .name = "D",
                    .x_start = 0.00,
                    .y_start = 0.40,
                    .x_end = 1.00,
                    .y_end = 1.00,
                    .ids = &.{4},
                    .children = &.{},
                },
            },
        },
    },
};

//    // misc
//    .{ .mod = MODKEY | c.WLR_MODIFIER_SHIFT, .keysym = c.XKB_KEY_exclam, .func = setcon, .arg = .{ .ui = 1 } },
//    .{ .mod = MODKEY | c.WLR_MODIFIER_SHIFT, .keysym = c.XKB_KEY_at, .func = setcon, .arg = .{ .ui = 2 } },
//    .{ .mod = MODKEY | c.WLR_MODIFIER_SHIFT, .keysym = c.XKB_KEY_numbersign, .func = setcon, .arg = .{ .ui = 3 } },
//    .{ .mod = MODKEY | c.WLR_MODIFIER_SHIFT, .keysym = c.XKB_KEY_dollar, .func = setcon, .arg = .{ .ui = 4 } },
//    .{ .mod = MODKEY, .keysym = c.XKB_KEY_space, .func = togglefloating, .arg = .{ .i = 0 } },
//    .{ .mod = MODKEY, .keysym = c.XKB_KEY_f, .func = togglefullscreen, .arg = .{ .i = 0 } },
//    .{ .mod = MODKEY, .keysym = c.XKB_KEY_h, .func = cyclelayout, .arg = .{ .i = 1 } },
//    .{ .mod = MODKEY | c.WLR_MODIFIER_SHIFT, .keysym = c.XKB_KEY_H, .func = cyclelayout, .arg = .{ .i = -1 } },
//
//    // tags
//    .{ .mod = MODKEY, .keysym = c.XKB_KEY_F1, .func = view, .arg = .{ .ui = 1 << 0 } },
//    .{ .mod = MODKEY | c.WLR_MODIFIER_SHIFT, .keysym = c.XKB_KEY_F1, .func = tag, .arg = .{ .ui = 1 << 0 } },
//    .{ .mod = MODKEY, .keysym = c.XKB_KEY_F2, .func = view, .arg = .{ .ui = 1 << 1 } },
//    .{ .mod = MODKEY | c.WLR_MODIFIER_SHIFT, .keysym = c.XKB_KEY_F2, .func = tag, .arg = .{ .ui = 1 << 1 } },
//    .{ .mod = MODKEY, .keysym = c.XKB_KEY_F3, .func = view, .arg = .{ .ui = 1 << 2 } },
//    .{ .mod = MODKEY | c.WLR_MODIFIER_SHIFT, .keysym = c.XKB_KEY_F3, .func = tag, .arg = .{ .ui = 1 << 2 } },
//    .{ .mod = MODKEY, .keysym = c.XKB_KEY_F4, .func = view, .arg = .{ .ui = 1 << 3 } },
//    .{ .mod = MODKEY | c.WLR_MODIFIER_SHIFT, .keysym = c.XKB_KEY_F4, .func = tag, .arg = .{ .ui = 1 << 3 } },
//};

pub const Cursors = enum {
    CurNormal,
    CurPressed,
    CurMove,
    CurResize,
};

const Layer = enum {
    LyrBg,
    LyrBottom,
    LyrTop,
    LyrOverlay,
    LyrTile,
    LyrFloat,
    LyrFS,
    LyrDragIcon,
    LyrBlock,
};

const ClientType = enum {
    Undefined,
    XDGShell,
    LayerShell,
    X11Managed,
    X11Unmanaged,
};

const Atoms = enum(usize) {
    NetWMWindowTypeDialog,
    NetWMWindowTypeSplash,
    NetWMWindowTypeToolbar,
    NetWMWindowTypeUtility,
};

const PointerConstraint = struct {
    constraint: *c.wlr_pointer_constraint_v1,
    focused: *Client,

    set_region: c.wl_listener,
    destroy: c.wl_listener,
};

const Container = struct {
    x_start: f32,
    y_start: f32,
    x_end: f32,
    y_end: f32,
    children: []const Container,
    name: []const u8,
    ids: []const u8,

    fn getBounds(self: *const Container, screen: c.wlr_box) c.wlr_box {
        var result: c.wlr_box = undefined;

        result.x = screen.x + if (self.x_start <= 1.0)
            @floatToInt(c_int, @intToFloat(f32, screen.width) * self.x_start)
        else
            @floatToInt(c_int, self.x_start);

        result.width = screen.x + if (self.x_end <= 1.0)
            @floatToInt(c_int, @intToFloat(f32, screen.width) * self.x_end)
        else
            @floatToInt(c_int, self.x_end);
        result.width -= result.x;

        result.y = screen.y + if (self.y_start <= 1.0)
            @floatToInt(c_int, @intToFloat(f32, screen.height) * self.y_start)
        else
            @floatToInt(c_int, self.y_start);

        result.height = screen.y + if (self.y_end <= 1.0)
            @floatToInt(c_int, @intToFloat(f32, screen.height) * self.y_end)
        else
            @floatToInt(c_int, self.y_end);
        result.height -= result.y;

        return result;
    }
};

const LayerSurface = struct {
    type: ClientType,
    geom: c.wlr_box,
    mon: ?*Monitor,

    scene: *c.wlr_scene_tree,
    popups: *c.wlr_scene_tree,
    scene_layer: *c.wlr_scene_layer_surface_v1,
    mapped: bool,
    layer_surface: *c.wlr_layer_surface_v1,

    destroy: c.wl_listener,
    map: c.wl_listener,
    unmap: c.wl_listener,
    surface_commit: c.wl_listener,
};

pub const Monitor = struct {
    output: *c.wlr_output,
    scene_output: *c.wlr_scene_output,
    fullscreen_bg: *c.wlr_scene_rect,

    frame: c.wl_listener,
    destroy: c.wl_listener,
    destroy_lock_surface: c.wl_listener,

    lock_surface: ?*c.wlr_session_lock_surface_v1,

    m: c.wlr_box,
    w: c.wlr_box,

    layers: [4]std.ArrayList(*LayerSurface),
    lt: [2]*const cfg.Config.Layout,

    seltags: u32,
    sellt: u32,

    tagset: [2]u32,

    ltsymbol: *const []const u8,

    ipc_outputs: []*ipc.IpcOutput,
};

const Client = struct {
    type: ClientType,
    geom: c.wlr_box,
    mon: ?*Monitor,
    scene: *c.wlr_scene_tree,
    title: ?*buffers.DataBuffer,
    titlescene: ?*c.wlr_scene_buffer,
    border: [4]*c.wlr_scene_rect,
    scene_surface: *c.wlr_scene_tree,
    surface: union {
        xdg: *c.wlr_xdg_surface,
        xwayland: *c.wlr_xwayland_surface,
    },

    icon: ?[]const u8 = null,
    title_override: ?[]const u8 = null,
    lockicon: bool = false,

    commit: c.wl_listener,
    map: c.wl_listener,
    maximize: c.wl_listener,
    unmap: c.wl_listener,
    destroy: c.wl_listener,
    set_title: c.wl_listener,
    fullscreen: c.wl_listener,
    frame: bool = false,
    framefocused: bool = false,
    hasframe: bool = false,
    frameTabs: i32 = 0,

    // xwayland
    activate: c.wl_listener,
    configure: c.wl_listener,
    set_hints: c.wl_listener,

    prev: c.wlr_box,
    bw: i32,
    tags: u32,
    isfloating: bool,
    isurgent: bool,
    isfullscreen: bool,
    iscentered: bool,
    resize: u32,

    container: u8,
};

const Keyboard = struct {
    wlr_keyboard: *c.wlr_keyboard,
    keysyms: []const c.xkb_keysym_t,
    mods: u32,
    key_repeat_source: ?*c.wl_event_source,
    modifiers: c.wl_listener,
    key: c.wl_listener,
    destroy: c.wl_listener,
};

var dpy: *c.wl_display = undefined;
var drw: *c.wlr_renderer = undefined;
var alloc: *c.wlr_allocator = undefined;
var scene: *c.wlr_scene = undefined;
var backend: *c.wlr_backend = undefined;
var compositior: *c.wlr_compositor = undefined;
var output_layout: *c.wlr_output_layout = undefined;
var idle: *c.wlr_idle = undefined;
var idle_notifier: *c.wlr_idle_notifier_v1 = undefined;
var idle_inhibit_mgr: *c.wlr_idle_inhibit_manager_v1 = undefined;
var layer_shell: *c.wlr_layer_shell_v1 = undefined;
var xdg_shell: *c.wlr_xdg_shell = undefined;
var input_inhibit_mgr: *c.wlr_input_inhibit_manager = undefined;
var session_lock_mgr: *c.wlr_session_lock_manager_v1 = undefined;
var locked_bg: *c.wlr_scene_rect = undefined;
var xdg_decoration_mgr: *c.wlr_xdg_decoration_manager_v1 = undefined;
var cursor: *c.wlr_cursor = undefined;
var cursor_mgr: *c.wlr_xcursor_manager = undefined;
var virtual_keyboard_mgr: *c.wlr_virtual_keyboard_manager_v1 = undefined;
var seat: *c.wlr_seat = undefined;
var output_mgr: *c.wlr_output_manager_v1 = undefined;
var xwayland: *c.wlr_xwayland = undefined;
var exclusive_focus: ?usize = null;
var cursor_mode: Cursors = .CurNormal;
var grabc: ?*Client = null;
var grabcx: i32 = 0;
var grabcy: i32 = 0;
var netatom: std.EnumArray(Atoms, c.Atom) = undefined;
var relative_pointer_mgr: *c.wlr_relative_pointer_manager_v1 = undefined;
var pointer_constraints: *c.wlr_pointer_constraints_v1 = undefined;
var pointer_constraint_commit: c.wl_listener = undefined;
var active_constraint: ?*PointerConstraint = null;
var active_confine: c.pixman_region32_t = undefined;
var active_confine_requires_warp: bool = false;

var cursor_image: ?[]const u8 = "left_ptr\x00";

var layers: std.EnumArray(Layer, *c.wlr_scene_tree) = undefined;

pub var mons: []*Monitor = undefined;
pub var clients: std.ArrayList(*Client) = undefined;
var fstack: std.ArrayList(*Client) = undefined;
var keyboards: std.ArrayList(*Keyboard) = undefined;
var sgeom: c.wlr_box = undefined;

pub var selmon: ?*Monitor = null;

var child_pid: i32 = -1;
var locked: bool = false;

var layout_change: c.wl_listener = .{ .link = undefined, .notify = updatemons };
var new_output: c.wl_listener = .{ .link = undefined, .notify = createmon };
var idle_inhibitor_create: c.wl_listener = .{ .link = undefined, .notify = createidleinhibitor };
var new_layer_shell_surface: c.wl_listener = .{ .link = undefined, .notify = createlayersurface };
var new_xdg_surface: c.wl_listener = .{ .link = undefined, .notify = createnotify };
var session_lock_create_lock: c.wl_listener = .{ .link = undefined, .notify = locksession };
var session_lock_mgr_destroy: c.wl_listener = .{ .link = undefined, .notify = destroysessionmgr };
var new_xdg_decoration: c.wl_listener = .{ .link = undefined, .notify = createdecoration };
var cursor_motion: c.wl_listener = .{ .link = undefined, .notify = motionrelative };
var cursor_motion_absolute: c.wl_listener = .{ .link = undefined, .notify = motionabsolute };
var cursor_button: c.wl_listener = .{ .link = undefined, .notify = buttonpress };
var cursor_axis: c.wl_listener = .{ .link = undefined, .notify = axisnotify };
var cursor_frame: c.wl_listener = .{ .link = undefined, .notify = cursorframe };
var new_input: c.wl_listener = .{ .link = undefined, .notify = inputdevice };
var new_virtual_keyboard: c.wl_listener = .{ .link = undefined, .notify = virtualkeyboard };
var xwayland_ready: c.wl_listener = .{ .link = undefined, .notify = xwaylandready };
var new_xwayland_surface: c.wl_listener = .{ .link = undefined, .notify = createnotifyx11 };
var idle_inhibitor_destroy: c.wl_listener = .{ .link = undefined, .notify = destroyidleinhibitor };
var request_cursor: c.wl_listener = .{ .link = undefined, .notify = setcursor };
var request_start_drag: c.wl_listener = .{ .link = undefined, .notify = requeststartdrag };
var start_drag: c.wl_listener = .{ .link = undefined, .notify = startdrag };
var drag_icon_destroy: c.wl_listener = .{ .link = undefined, .notify = destroydragicon };
var output_mgr_apply: c.wl_listener = .{ .link = undefined, .notify = outputmgrapply };
var new_pointer_constraint: c.wl_listener = .{ .link = undefined, .notify = createpointerconstraint };

pub fn bud(comptime igapps: i32, comptime ogapps: i32, comptime containers: *const Container) (fn (*Monitor) void) {
    return struct {
        pub fn getSizeInContainer(target: u8, currentSize: c.wlr_box, container: *const Container, usage: [containers.ids.len]bool) c.wlr_box {
            var result = currentSize;
            if (container.ids.len == 1 and container.ids[0] == target) return result;

            var childrenUsed: u8 = 0;
            var idsUsed: u8 = 0;
            for (container.ids) |id| {
                if (usage[id - 1]) idsUsed += 1;
            }

            for (container.children) |child| {
                var good: bool = false;
                for (child.ids) |id| {
                    if (usage[id - 1]) {
                        good = true;
                    }
                }
                if (good)
                    childrenUsed += 1;
            }

            if (idsUsed == 1) return result;
            for (container.children) |*child| {
                if (std.mem.containsAtLeast(u8, child.ids, 1, &.{target})) {
                    if (childrenUsed != 1)
                        result = child.getBounds(result);
                    return getSizeInContainer(target, result, child, usage);
                }
            }

            unreachable;
        }

        pub fn budImpl(mon: *Monitor) void {
            var containerUsage = [_]bool{false} ** containers.ids.len;

            for (clients.items) |client| {
                if (client.mon == mon and (client.tags & mon.tagset[mon.seltags]) != 0) {
                    if (client.container == 0) {
                        client.container = 1;
                    }

                    if (!client.isfloating and !client.isfullscreen)
                        containerUsage[client.container - 1] = true;
                }
            }

            var win = mon.w;
            const starty = win.y;
            win.x += ogapps;
            win.y += ogapps;
            win.width -= ogapps * 2;
            win.height -= ogapps * 2;

            for (clients.items) |client| {
                client.frame = true;
                if (client.mon == mon and (client.tags & mon.tagset[mon.seltags]) != 0 and (!client.isfloating and !client.isfullscreen)) {
                    var new = getSizeInContainer(client.container, win, containers, containerUsage);
                    if (new.y == starty and mon.w.y != mon.m.y) client.frame = false;
                    new.x += igapps;
                    new.y += igapps;
                    new.width -= igapps * 2;
                    new.height -= igapps * 2;
                    resize(client, new, false);
                }
            }
        }
    }.budImpl;
}

pub fn updatemons(_: [*c]c.wl_listener, _: ?*anyopaque) callconv(.C) void {
    var config = c.wlr_output_configuration_v1_create();
    var config_head: *c.wlr_output_configuration_head_v1 = undefined;

    for (mons) |m| {
        if (m.output.enabled) continue;

        config_head = c.wlr_output_configuration_head_v1_create(config, m.output);
        config_head.state.enabled = false;

        c.wlr_output_layout_remove(output_layout, m.output);
        closemon(m);
        m.w = std.mem.zeroInit(c.wlr_box, .{});
        m.m = std.mem.zeroInit(c.wlr_box, .{});
    }
    for (mons) |m| {
        if (m.output.enabled and c.wlr_output_layout_get(output_layout, m.output) == null)
            c.wlr_output_layout_add_auto(output_layout, m.output);
    }

    c.wlr_output_layout_get_box(output_layout, null, &sgeom);

    c.wlr_scene_node_set_position(&locked_bg.node, sgeom.x, sgeom.y);
    c.wlr_scene_rect_set_size(locked_bg, sgeom.width, sgeom.height);

    for (mons) |m| {
        if (!m.output.enabled) continue;

        config_head = c.wlr_output_configuration_head_v1_create(config, m.output);

        c.wlr_output_layout_get_box(output_layout, m.output, &m.m);
        c.wlr_output_layout_get_box(output_layout, m.output, &m.w);
        c.wlr_scene_output_set_position(m.scene_output, m.m.x, m.m.y);

        c.wlr_scene_node_set_position(&m.fullscreen_bg.node, m.m.x, m.m.y);
        c.wlr_scene_rect_set_size(m.fullscreen_bg, m.m.width, m.m.height);

        if (m.lock_surface) |lock_surface| {
            var scene_tree = @ptrCast(*c.wlr_scene_tree, @alignCast(@alignOf(c.wlr_scene_tree), lock_surface.surface.*.data));
            c.wlr_scene_node_set_position(&scene_tree.node, m.m.x, m.m.y);
            _ = c.wlr_session_lock_surface_v1_configure(lock_surface, @intCast(u32, m.m.width), @intCast(u32, m.m.height));
        }

        arrangelayers(m);
        arrange(m);

        config_head.state.enabled = true;
        config_head.state.mode = m.output.current_mode;
        config_head.state.x = m.m.x;
        config_head.state.y = m.m.y;
    }

    if (selmon) |selected| {
        if (selected.output.enabled) {
            for (clients.items) |client| {
                if (client.mon == null and client_is_mapped(client)) {
                    setmon(client, selected, client.tags);
                }
            }
        }
        if (selmon.?.lock_surface != null)
            client_notify_enter(selmon.?.lock_surface.?.*.surface, c.wlr_seat_get_keyboard(seat));
    }

    c.wlr_output_manager_v1_set_configuration(output_mgr, config);
}

pub fn closemon(m: *Monitor) void {
    if (mons.len == 0) {
        selmon = null;
    } else if (m == selmon.?) {
        for (mons) |mon| {
            selmon = mon;
            if (selmon.?.output.enabled) break;
        }
    }

    for (clients.items) |client| {
        if (client.isfloating and client.geom.x > m.m.width) {
            resize(client, .{
                .x = client.geom.x - m.w.width,
                .y = client.geom.y,
                .width = client.geom.width,
                .height = client.geom.height,
            }, false);
        }

        if (client.mon == m) {
            setmon(client, selmon, client.tags);
        }
    }
    focusclient(focustop(selmon), true);
    printstatus();
}

pub fn focustop(m: ?*Monitor) ?*Client {
    if (m) |mon| {
        for (fstack.items) |client| {
            if (client.mon == mon and (client.tags & mon.tagset[mon.seltags]) != 0) {
                return client;
            }
        }
        return null;
    } else {
        return null;
    }
}

pub fn resize(client: *Client, geo: c.wlr_box, interact: bool) void {
    var bbox: *c.wlr_box = if (interact) &sgeom else &client.mon.?.w;
    _ = client_set_bounds(client, geo.width, geo.height);

    const old = client.geom.width;
    client.geom = geo;

    applybounds(client, bbox);
    client_update_frame(client, old != client.geom.width);

    var titleheight: i32 = if (client.hasframe) barheight + client.bw else 0;

    c.wlr_scene_node_set_position(&client.scene.node, client.geom.x, client.geom.y);
    c.wlr_scene_node_set_position(&client.scene_surface.node, client.bw, client.bw + titleheight);
    c.wlr_scene_rect_set_size(client.border[0], client.geom.width, client.bw + titleheight);
    c.wlr_scene_rect_set_size(client.border[1], client.geom.width, client.bw);
    c.wlr_scene_rect_set_size(client.border[2], client.bw, client.geom.height - 2 * client.bw);
    c.wlr_scene_rect_set_size(client.border[3], client.bw, client.geom.height - 2 * client.bw);
    c.wlr_scene_node_set_position(&client.border[1].node, 0, client.geom.height - client.bw);
    c.wlr_scene_node_set_position(&client.border[2].node, 0, client.bw);
    c.wlr_scene_node_set_position(&client.border[3].node, client.geom.width - client.bw, client.bw);
    client.resize = client_set_size(client, client.geom.width - 2 * client.bw, client.geom.height - 2 * client.bw - titleheight);
}

pub fn client_set_bounds(client: *Client, w: i32, h: i32) u32 {
    if (client.type == .X11Managed or client.type == .X11Unmanaged) return 0;

    if (client.surface.xdg.*.client.*.shell.*.version >= 4 and w >= 0 and h >= 0)
        return c.wlr_xdg_toplevel_set_bounds(client.surface.xdg.unnamed_0.toplevel, w, h);

    return 0;
}

pub fn client_set_size(client: *Client, w: i32, h: i32) u32 {
    if (client.type == .X11Managed or client.type == .X11Unmanaged) {
        c.wlr_xwayland_surface_configure(
            client.surface.xwayland,
            @intCast(i16, client.geom.x),
            @intCast(i16, client.geom.y),
            @intCast(u16, w),
            @intCast(u16, h),
        );
        return 0;
    }
    if (w == client.surface.xdg.unnamed_0.toplevel.*.current.width and
        h == client.surface.xdg.unnamed_0.toplevel.*.current.height)
        return 0;
    return c.wlr_xdg_toplevel_set_size(client.surface.xdg.unnamed_0.toplevel, w, h);
}

pub fn applybounds(client: *Client, bbox: *c.wlr_box) void {
    if (!client.isfullscreen) {
        var min: c.wlr_box = .{ .x = 0, .y = 0, .width = 0, .height = 0 };
        var max: c.wlr_box = .{ .x = 0, .y = 0, .width = 0, .height = 0 };
        client_get_size_hints(client, &min, &max);
        client.geom.width = @max(min.width + (2 * client.bw), client.geom.width);
        client.geom.height = @max(min.height + (2 * client.bw), client.geom.height);

        if (max.width > 0 and !(2 * client.bw > 2147483647 - max.width))
            client.geom.width = @min(max.width + (2 * client.bw), client.geom.width);
        if (max.height > 0 and !(2 * client.bw > 2147483647 - max.height))
            client.geom.height = @min(max.height + (2 * client.bw), client.geom.height);
    }

    if (client.geom.x > bbox.x + bbox.width)
        client.geom.x = bbox.x + bbox.width - client.geom.width;
    if (client.geom.y > bbox.y + bbox.height)
        client.geom.y = bbox.y + bbox.height - client.geom.height;
    if (client.geom.x + client.geom.width + 2 * client.bw < bbox.x)
        client.geom.x = bbox.x;
    if (client.geom.y + client.geom.height + 2 * client.bw < bbox.y)
        client.geom.y = bbox.y;
    if (client.geom.width < 2 * client.bw + 20) client.geom.width = 2 * client.bw + 20;
    if (client.geom.height < 2 * client.bw + 20) client.geom.height = 2 * client.bw + 20;
}

pub fn client_get_size_hints(client: *Client, min: *c.wlr_box, max: *c.wlr_box) void {
    if (client.type == .X11Managed or client.type == .X11Unmanaged) {
        var size_hints = client.surface.xwayland.size_hints;
        if (size_hints != null) {
            max.width = size_hints.*.max_width;
            max.height = size_hints.*.max_height;
            min.width = size_hints.*.min_width;
            min.height = size_hints.*.min_height;
        }
        return;
    }
    var toplevel = client.surface.xdg.unnamed_0.toplevel;
    var state = &toplevel.*.current;
    max.width = state.max_width;
    max.height = state.max_height;
    min.width = state.min_width;
    min.height = state.min_height;
}

pub fn arrangelayers(m: *Monitor) void {
    var usable_area: c.wlr_box = m.m;
    var layers_above_shell = [_]u32{
        c.ZWLR_LAYER_SHELL_V1_LAYER_OVERLAY,
        c.ZWLR_LAYER_SHELL_V1_LAYER_TOP,
    };

    if (!m.output.enabled) return;

    for (0..4) |i|
        arrangelayer(m, m.layers[3 - i], &usable_area, true);

    if (!std.mem.eql(u8, std.mem.asBytes(&usable_area), std.mem.asBytes(&m.w))) {
        m.w = usable_area;
        arrange(m);
    }

    for (0..4) |i|
        arrangelayer(m, m.layers[3 - i], &usable_area, false);

    for (layers_above_shell) |layer| {
        for (m.layers[layer].items) |layersurface| {
            if (!locked and layersurface.layer_surface.current.keyboard_interactive != 0 and layersurface.mapped) {
                focusclient(null, false);
                exclusive_focus = @ptrToInt(layersurface);
                client_notify_enter(layersurface.layer_surface.surface, c.wlr_seat_get_keyboard(seat));
                return;
            }
        }
    }
}

pub fn client_notify_enter(s: *c.wlr_surface, kb: ?*c.wlr_keyboard) void {
    if (kb) |keyb| {
        c.wlr_seat_keyboard_notify_enter(seat, s, &keyb.keycodes, keyb.num_keycodes, &keyb.modifiers);
    } else {
        c.wlr_seat_keyboard_notify_enter(seat, s, null, 0, null);
    }
}

pub fn focusclient(foc: ?*Client, lift: bool) void {
    var old = seat.keyboard_state.focused_surface;

    if (locked) return;

    var client = foc;

    if (client != null and lift)
        c.wlr_scene_node_raise_to_top(&client.?.scene.node);

    if (client != null and client_surface(client.?) == old)
        return;

    if (client != null and client.?.type != .X11Unmanaged) {
        client = fstack.orderedRemove(std.mem.indexOf(*Client, fstack.items, &.{client.?}) orelse {
            return;
        });
        fstack.insert(0, client.?) catch {
            return;
        };
        selmon = client.?.mon;
        client.?.isurgent = false;
        client_restack_surface(client.?);

        if (exclusive_focus == null and seat.drag == null)
            for (client.?.border) |border|
                c.wlr_scene_rect_set_color(border, &focuscolor);
    }

    if (old != null and (client == null or client_surface(client.?) != old)) {
        var w: ?*Client = null;
        var l: ?*LayerSurface = null;
        var unused_lx: i32 = 0;
        var unused_ly: i32 = 0;
        var kind = toplevel_from_wlr_surface(old, &w, &l);
        if (kind == .LayerShell and c.wlr_scene_node_coords(&l.?.scene.*.node, &unused_lx, &unused_ly) and l.?.layer_surface.*.current.layer >= c.ZWLR_LAYER_SHELL_V1_LAYER_TOP) {
            return;
        } else if (w != null and @ptrToInt(w) == exclusive_focus and client_wants_focus(w.?)) {
            return;
        } else if (w != null and w.?.type != .X11Unmanaged and (client == null or !client_wants_focus(client.?))) {
            for (w.?.border) |border| {
                c.wlr_scene_rect_set_color(border, &bordercolor);
            }

            client_activate_surface(old, false);
        }
    }

    printstatus();

    if (client == null) {
        c.wlr_seat_keyboard_notify_clear_focus(seat);
        return;
    }

    motionnotify(0, null, 0, 0, 0, 0);

    client_notify_enter(client_surface(client.?).?, c.wlr_seat_get_keyboard(seat));
    client_activate_surface(client_surface(client.?).?, true);
}

pub fn motionnotify(time: u32, device: ?*c.wlr_input_device, adx: f64, ady: f64, dx_unaccel: f64, dy_unaccel: f64) void {
    var dx = adx;
    var dy = ady;

    var sx: f64 = 0;
    var sy: f64 = 0;
    var sx_confirmed: f64 = 0;
    var sy_confirmed: f64 = 0;
    var surface: ?*c.wlr_surface = null;
    var client: ?*Client = null;
    var w: ?*Client = null;
    var l: ?*LayerSurface = null;

    _ = xytonode(cursor.x, cursor.y, &surface, &client, null, &sx, &sy);

    if (cursor_mode == .CurPressed and seat.drag == null) {
        var kind = toplevel_from_wlr_surface(seat.pointer_state.focused_surface, &w, &l);
        if (kind != .Undefined) {
            client = w;
            surface = seat.pointer_state.focused_surface;
            sx = cursor.x - @intToFloat(f64, if (kind == .LayerShell) l.?.geom.x else w.?.geom.x);
            sy = cursor.y - @intToFloat(f64, if (kind == .LayerShell) l.?.geom.y else w.?.geom.y);
            if (kind != .LayerShell)
                sy -= @intToFloat(f64, if (w.?.hasframe) (barheight + w.?.bw) else 0);
        }
    }

    if (time > 0) {
        c.wlr_relative_pointer_manager_v1_send_relative_motion(relative_pointer_mgr, seat, @intCast(u64, time) * 1000, dx, dy, dx_unaccel, dy_unaccel);

        var constraint: *c.wlr_pointer_constraint_v1 = undefined;
        constraint = c.wl_container_of(pointer_constraints.constraints.next, constraint, "link");
        const start = constraint;

        while (constraint != start) {
            cursorconstrain(constraint);
            constraint = c.wl_container_of(constraint.link.next, constraint, "link");
        }

        if (active_constraint != null) {
            constraint = active_constraint.?.constraint;
            if (constraint.surface == surface and c.wlr_region_confine(&active_confine, sx, sy, sx + dx, sy + dy, &sx_confirmed, &sy_confirmed)) {
                dx = sx_confirmed - sx;
                dy = sy_confirmed - sy;
            } else {
                return;
            }
        }

        c.wlr_cursor_move(cursor, device, dx, dy);

        c.wlr_idle_notify_activity(idle, seat);
        c.wlr_idle_notifier_v1_notify_activity(idle_notifier, seat);

        if (sloppyfocus)
            selmon = xytomon(cursor.x, cursor.y);
    }

    var icon: ?*c.wlr_drag_icon = null;

    if (seat.drag != null and (seat.drag.*.icon != null)) {
        icon = seat.drag.*.icon;
        c.wlr_scene_node_set_position(@ptrCast(*c.wlr_scene_node, @alignCast(@alignOf(c.wlr_scene_node), icon.?.data)), @floatToInt(i32, cursor.x) + icon.?.surface.*.sx, @floatToInt(i32, cursor.y) + icon.?.surface.*.sy);
    }

    if (cursor_mode == .CurMove) {
        resize(grabc.?, .{ .x = @floatToInt(i32, cursor.x) - grabcx, .y = @floatToInt(i32, cursor.y) - grabcy, .width = grabc.?.geom.width, .height = grabc.?.geom.height }, true);
        return;
    } else if (cursor_mode == .CurResize) {
        resize(grabc.?, .{ .x = grabc.?.geom.x, .y = grabc.?.geom.y, .width = @floatToInt(i32, cursor.x) - grabc.?.geom.x, .height = @floatToInt(i32, cursor.y) - grabc.?.geom.y }, true);
        return;
    }

    if (surface == null and seat.drag == null and cursor_image != null and !std.mem.eql(u8, cursor_image.?, "left_ptr\x00")) {
        cursor_image = "left_ptr\x00";
        c.wlr_xcursor_manager_set_cursor_image(cursor_mgr, cursor_image.?.ptr, cursor);
    }

    pointerfocus(client, surface, sx, sy, time);
}

pub fn xytonode(x: f64, y: f64, psurface: ?*?*c.wlr_surface, pc: ?*?*Client, pl: ?*?*LayerSurface, nx: ?*f64, ny: ?*f64) ?*c.wlr_scene_node {
    const focus_order = [_]Layer{ .LyrBlock, .LyrOverlay, .LyrTop, .LyrFS, .LyrFloat, .LyrTile, .LyrBottom, .LyrBg };

    var client: ?*Client = null;
    var l: ?*LayerSurface = null;
    var surface: ?*c.wlr_surface = null;
    var node: ?*c.wlr_scene_node = undefined;

    for (focus_order) |layer| {
        node = c.wlr_scene_node_at(&layers.get(layer).node, x, y, nx, ny);
        if (node != null and node.?.type == c.WLR_SCENE_NODE_BUFFER) {
            if (c.wlr_scene_surface_from_buffer(c.wlr_scene_buffer_from_node(node))) |tmp| {
                surface = tmp.*.surface;
            }
        }

        var pnode = node;
        while (pnode != null and client == null) : (pnode = &pnode.?.parent.*.node) {
            client = @ptrCast(?*Client, @alignCast(@alignOf(Client), pnode.?.data));
        }

        if (client != null and client.?.type == .LayerShell) {
            client = null;
            l = @ptrCast(?*LayerSurface, @alignCast(@alignOf(LayerSurface), pnode.?.data));
        }

        if (surface != null) break;
    }

    if (psurface != null) psurface.?.* = surface;
    if (pc != null) pc.?.* = client;
    if (pl != null) pl.?.* = l;

    return node;
}

pub fn pointerfocus(client: ?*Client, surface: ?*c.wlr_surface, sx: f64, sy: f64, time: u32) void {
    var atime: i64 = time;
    var internal_call = time == 0;
    var now: c.timespec = undefined;

    if (sloppyfocus and !internal_call and client != null and client.?.type != .X11Unmanaged) {
        focusclient(client, false);
    }

    if (surface == null) {
        c.wlr_seat_pointer_notify_clear_focus(seat);
        return;
    }

    if (internal_call) {
        _ = c.clock_gettime(c.CLOCK_MONOTONIC, &now);
        atime = now.tv_sec * 1000 + @divTrunc(now.tv_nsec, 1000000);
    }

    c.wlr_seat_pointer_notify_enter(seat, surface, sx, sy);
    c.wlr_seat_pointer_notify_motion(seat, @intCast(u32, atime), sx, sy);
}

pub fn client_activate_surface(s: *c.wlr_surface, activated: bool) void {
    if (c.wlr_surface_is_xwayland_surface(s)) {
        var xsurface = c.wlr_xwayland_surface_from_wlr_surface(s);
        if (xsurface != null)
            c.wlr_xwayland_surface_activate(xsurface, activated);
        return;
    }
    if (c.wlr_surface_is_xdg_surface(s)) {
        var surface = c.wlr_xdg_surface_from_wlr_surface(s);
        if (surface != null and surface.*.role == c.WLR_XDG_SURFACE_ROLE_TOPLEVEL) {
            _ = c.wlr_xdg_toplevel_set_activated(surface.*.unnamed_0.toplevel, activated);
        }
    }
}

pub fn client_wants_focus(client: *Client) bool {
    return client.type == .X11Unmanaged and c.wlr_xwayland_or_surface_wants_focus(client.surface.xwayland) and c.wlr_xwayland_icccm_input_model(client.surface.xwayland) != c.WLR_ICCCM_INPUT_MODEL_NONE;
}

pub fn toplevel_from_wlr_surface(s: ?*c.wlr_surface, pc: ?*?*Client, pl: ?*?*LayerSurface) ClientType {
    var client: ?*Client = null;
    var l: ?*LayerSurface = null;

    var kind: ClientType = .Undefined;

    start: {
        if (s == null) {
            return kind;
        }

        var root_surface = c.wlr_surface_get_root_surface(s);

        if (c.wlr_surface_is_xwayland_surface(root_surface)) {
            var xsurface = c.wlr_xwayland_surface_from_wlr_surface(root_surface);
            if (xsurface != null) {
                client = @ptrCast(?*Client, @alignCast(@alignOf(Client), xsurface.*.data));
                kind = client.?.type;
                break :start;
            }
        }

        if (c.wlr_surface_is_layer_surface(root_surface)) {
            var layer_surface = c.wlr_layer_surface_v1_from_wlr_surface(root_surface);
            if (layer_surface != null) {
                l = @ptrCast(?*LayerSurface, @alignCast(@alignOf(LayerSurface), layer_surface.*.data));
                kind = .LayerShell;
                break :start;
            }
        }

        if (c.wlr_surface_is_xdg_surface(root_surface)) {
            var xdg_surface = c.wlr_xdg_surface_from_wlr_surface(root_surface);
            if (xdg_surface != null) {
                while (true) {
                    switch (xdg_surface.*.role) {
                        c.WLR_XDG_SURFACE_ROLE_POPUP => {
                            if (xdg_surface.*.unnamed_0.popup.*.parent == null) {
                                return .Undefined;
                            } else if (!c.wlr_surface_is_xdg_surface(xdg_surface.*.unnamed_0.popup.*.parent)) {
                                return toplevel_from_wlr_surface(xdg_surface.*.unnamed_0.popup.*.parent, pc, pl);
                            }

                            xdg_surface = c.wlr_xdg_surface_from_wlr_surface(xdg_surface.*.unnamed_0.popup.*.parent);
                            continue;
                        },
                        c.WLR_XDG_SURFACE_ROLE_TOPLEVEL => {
                            client = @ptrCast(?*Client, @alignCast(@alignOf(Client), xdg_surface.*.data));
                            kind = client.?.type;
                            break :start;
                        },
                        else => {
                            return .Undefined;
                        },
                    }
                }
            }
        }
    }
    if (pl != null) pl.?.* = l;
    if (pc != null) pc.?.* = client;

    return kind;
}

pub fn client_restack_surface(client: *Client) void {
    if (client.type == .X11Managed or client.type == .X11Unmanaged) c.wlr_xwayland_surface_restack(client.surface.xwayland, null, c.XCB_STACK_MODE_ABOVE);
    return;
}

pub fn client_surface(client: *Client) ?*c.wlr_surface {
    if (client.type == .X11Managed or client.type == .X11Unmanaged) return client.surface.xwayland.surface;
    return client.surface.xdg.surface;
}

pub inline fn visible_on(client: *Client, mon: *Monitor) bool {
    return client.mon == mon and (client.tags & mon.tagset[mon.seltags]) != 0;
}

pub fn arrangelayer(mon: *Monitor, list: std.ArrayList(*LayerSurface), usable_area: *c.wlr_box, exclusive: bool) void {
    var full_area = mon.m;

    for (list.items) |layersurface| {
        var wlr_layer_surface = layersurface.layer_surface;
        var state = &wlr_layer_surface.current;

        if (exclusive != (state.exclusive_zone > 0))
            continue;

        c.wlr_scene_layer_surface_v1_configure(layersurface.scene_layer, &full_area, usable_area);
        c.wlr_scene_node_set_position(&layersurface.popups.node, layersurface.scene.node.x, layersurface.scene.node.y);
        layersurface.geom.x = layersurface.scene.node.x;
        layersurface.geom.y = layersurface.scene.node.y;
    }
}

pub fn arrange(mon: *Monitor) void {
    for (clients.items) |client| {
        if (client.mon == mon) {
            c.wlr_scene_node_set_enabled(&client.scene.node, visible_on(client, mon));
        }
    }

    var client: ?*Client = focustop(mon);

    c.wlr_scene_node_set_enabled(&mon.fullscreen_bg.node, client != null and client.?.isfullscreen);

    mon.ltsymbol = &mon.lt[mon.sellt].symbol;

    if (mon.lt[mon.sellt].arrange != null)
        mon.lt[mon.sellt].arrange.?(mon);

    motionnotify(0, null, 0, 0, 0, 0);
}

pub fn checkidleinhibitor(exclude: ?*c.wlr_surface) void {
    var inhibited = false;
    var unused_lx: i32 = 0;
    var unused_ly: i32 = 0;

    var inhibitor: *c.wlr_idle_inhibitor_v1 = undefined;
    inhibitor = c.wl_container_of(&idle_inhibit_mgr.inhibitors, inhibitor, "link");

    while (&inhibitor.link != &idle_inhibit_mgr.inhibitors) {
        inhibitor = c.wl_container_of(inhibitor.link.next, inhibitor, "link");

        var surface = c.wlr_surface_get_root_surface(inhibitor.*.surface);
        var tree = @ptrCast(?*c.wlr_scene_tree, @alignCast(@alignOf(c.wlr_scene_tree), surface.*.data));
        if (exclude != surface and (bypass_surface_visibility or (tree == null or c.wlr_scene_node_coords(&tree.?.node, &unused_lx, &unused_ly)))) {
            inhibited = true;
            break;
        }
    }

    c.wlr_idle_set_enabled(idle, null, !inhibited);
    c.wlr_idle_notifier_v1_set_inhibited(idle_notifier, inhibited);
}

pub fn client_is_mapped(client: *Client) bool {
    if (client.type == .X11Managed or client.type == .X11Unmanaged)
        return client.surface.xwayland.mapped;
    return client.surface.xdg.mapped;
}

pub fn setmon(client: *Client, mon: ?*Monitor, newtags: u32) void {
    var oldmon = client.mon;

    if (oldmon == mon)
        return;

    client.mon = mon;
    client.prev = client.geom;

    if (oldmon != null) {
        c.wlr_surface_send_leave(client_surface(client), oldmon.?.output);
        arrange(oldmon.?);
    }
    if (mon != null) {
        resize(client, client.geom, false);
        c.wlr_surface_send_enter(client_surface(client), mon.?.output);
        client.tags = if (newtags != 0) newtags else mon.?.tagset[mon.?.seltags];
        setfullscreen(client, client.isfullscreen);
    }

    focusclient(focustop(mon), true);
}

pub fn setfloating(client: *Client, floating: bool) void {
    client.isfloating = floating;

    c.wlr_scene_node_reparent(&client.scene.node, layers.get(if (client.isfloating) .LyrFloat else .LyrTile));
    arrange(client.mon.?);
    printstatus();
}

pub fn setfullscreen(client: *Client, fullscreen: bool) void {
    client.isfullscreen = fullscreen;

    if (client.mon == null)
        return;

    client.bw = if (fullscreen) 0 else borderpx;
    client_set_fullscreen(client, fullscreen);
    c.wlr_scene_node_reparent(&client.scene.node, layers.get(if (fullscreen) .LyrFS else if (client.isfloating) .LyrFloat else .LyrTile));

    if (fullscreen) {
        client.prev = client.geom;
        resize(client, client.mon.?.m, false);
    } else {
        resize(client, client.prev, false);
    }

    arrange(client.mon.?);
    printstatus();
}

pub fn client_set_fullscreen(client: *Client, fullscreen: bool) void {
    if (client.type == .X11Managed or client.type == .X11Unmanaged) {
        c.wlr_xwayland_surface_set_fullscreen(client.surface.xwayland, fullscreen);
        return;
    }
    _ = c.wlr_xdg_toplevel_set_fullscreen(client.surface.xdg.unnamed_0.toplevel, fullscreen);
}

var bad: []const u8 = "???";

pub fn createmon(_: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    var wlr_output = @ptrCast(*c.wlr_output, @alignCast(@alignOf(c.wlr_output), data));
    var m = allocator.create(Monitor) catch {
        return;
    };
    m.* = std.mem.zeroInit(Monitor, .{
        .output = wlr_output,
        .scene_output = undefined,
        .fullscreen_bg = undefined,
        .ltsymbol = &bad,
        .layers = undefined,
        .lt = .{ &configData.layouts[0], &configData.layouts[0] },
    });
    wlr_output.data = m;

    m.ipc_outputs = allocator.alloc(*ipc.IpcOutput, 0) catch unreachable;

    _ = c.wlr_output_init_render(wlr_output, alloc, drw);

    for (&m.layers) |*layer| {
        layer.* = std.ArrayList(*LayerSurface).init(allocator);
    }
    m.tagset[0] = 1;
    m.tagset[1] = 1;
    for (configData.monrules) |r| {
        if (r.name == null or c.strcmp(wlr_output.name, r.name.?) != 0) {
            c.wlr_output_set_scale(wlr_output, r.scale);
            _ = c.wlr_xcursor_manager_load(cursor_mgr, r.scale);
            c.wlr_output_set_transform(wlr_output, r.rr);
            m.m.x = r.x;
            m.m.y = r.y;
        }
    }

    c.wlr_output_set_mode(wlr_output, c.wlr_output_preferred_mode(wlr_output));

    m.frame.notify = rendermon;
    c.wl_signal_add(&wlr_output.events.frame, &m.frame);

    m.destroy.notify = cleanupmon;
    c.wl_signal_add(&wlr_output.events.destroy, &m.destroy);

    c.wlr_output_enable(wlr_output, true);
    if (!c.wlr_output_commit(wlr_output)) return;

    c.wlr_output_enable_adaptive_sync(wlr_output, true);
    _ = c.wlr_output_commit(wlr_output);

    mons = allocator.realloc(mons, mons.len + 1) catch mons;
    mons[mons.len - 1] = m;
    printstatus();

    m.fullscreen_bg = c.wlr_scene_rect_create(layers.get(.LyrFS), 0, 0, &fullscreen_bg);
    c.wlr_scene_node_set_enabled(&m.fullscreen_bg.node, false);

    m.scene_output = c.wlr_scene_output_create(scene, wlr_output);
    if (m.m.x < 0 or m.m.y < 0) {
        c.wlr_output_layout_add_auto(output_layout, wlr_output);
    } else {
        c.wlr_output_layout_add(output_layout, wlr_output, m.m.x, m.m.y);
    }

    m.ltsymbol = &m.lt[m.sellt].symbol;
}

pub fn rendermon(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;
    var m: *Monitor = undefined;
    m = c.wl_container_of(listener, m, "frame");

    skip: {
        for (clients.items) |client| {
            if (client.resize != 0 and !client.isfloating and client_is_rendered_on_mon(client, m) and !client_is_stopped(client)) break :skip;
        }
        if (!c.wlr_scene_output_commit(m.scene_output))
            return;
    }

    var now: c.timespec = undefined;
    _ = c.clock_gettime(c.CLOCK_MONOTONIC, &now);
    c.wlr_scene_output_send_frame_done(m.scene_output, &now);
}

pub fn client_is_rendered_on_mon(client: *Client, m: *Monitor) bool {
    if (!client.scene.node.enabled)
        return false;

    var s: *c.wlr_surface_output = undefined;
    s = c.wl_container_of(&idle_inhibit_mgr.inhibitors, s, "link");

    while (&s.link != &idle_inhibit_mgr.inhibitors) {
        s = c.wl_container_of(s.link.next, s, "link");
        if (s.output == m.output) return true;
    }

    return false;
}

pub fn client_is_stopped(client: *Client) bool {
    if (client.type == .X11Managed or client.type == .X11Unmanaged)
        return false;

    var pid: i32 = undefined;
    var in: c.siginfo_t = std.mem.zeroInit(c.siginfo_t, .{});

    c.wl_client_get_credentials(client.surface.xdg.client.*.client, &pid, null, null);
    var r = c.waitid(c.P_PID, @intCast(u32, pid), &in, c.WNOHANG | c.WCONTINUED | c.WSTOPPED | c.WNOWAIT);
    if (r < 0) {
        if (r == c.ECHILD)
            return true;
    } else if (in._sifields._kill.si_pid != 0) {
        if (in.si_code == c.CLD_STOPPED or in.si_code == c.CLD_TRAPPED)
            return true;
        if (in.si_code == c.CLD_CONTINUED)
            return false;
    }

    return false;
}

pub fn cleanupmon(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;

    var mon: *Monitor = undefined;
    mon = c.wl_container_of(listener, mon, "destroy");

    for (mon.layers) |layer|
        for (layer.items) |subLayer|
            c.wlr_layer_surface_v1_destroy(subLayer.layer_surface);

    for (mon.ipc_outputs) |ipc_output| {
        c.wl_resource_destroy(ipc_output.resource);
    }

    c.wl_list_remove(&mon.destroy.link);
    c.wl_list_remove(&mon.frame.link);

    const idx = std.mem.indexOf(*Monitor, mons, &.{mon}) orelse unreachable;
    @memcpy(mons[idx .. mons.len - 1], mons[idx + 1 ..]);
    mons = allocator.realloc(mons, mons.len - 1) catch unreachable;
    mon.output.data = null;
    c.wlr_output_layout_remove(output_layout, mon.output);
    c.wlr_scene_output_destroy(mon.scene_output);
    c.wlr_scene_node_destroy(&mon.fullscreen_bg.node);

    closemon(mon);

    allocator.destroy(mon);
}

pub fn createidleinhibitor(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;

    var idle_inhibitor = @ptrCast(*c.wlr_idle_inhibitor_v1, @alignCast(@alignOf(c.wlr_idle_inhibitor_v1), data));
    c.wl_signal_add(&idle_inhibitor.events.destroy, &idle_inhibitor_destroy);

    checkidleinhibitor(null);
}

pub fn destroyidleinhibitor(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;

    var surface = @ptrCast(*c.wlr_surface, @alignCast(@alignOf(c.wlr_surface), data));
    var root_surface = c.wlr_surface_get_root_surface(surface);

    checkidleinhibitor(root_surface);
}

pub fn createpointerconstraint(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;

    var wlr_constraint = @ptrCast(*c.wlr_pointer_constraint_v1, @alignCast(@alignOf(c.wlr_pointer_constraint_v1), data));
    var constraint = allocator.create(PointerConstraint) catch unreachable;
    var sel = focustop(selmon);

    var client: ?*Client = null;
    _ = toplevel_from_wlr_surface(wlr_constraint.surface, &client, null);
    constraint.constraint = wlr_constraint;
    wlr_constraint.data = constraint;

    constraint.set_region.notify = pointerconstraintsetregion;
    c.wl_signal_add(&wlr_constraint.*.events.set_region, &constraint.set_region);
    constraint.destroy.notify = destroypointerconstraint;
    c.wl_signal_add(&wlr_constraint.*.events.destroy, &constraint.destroy);

    if (client == sel)
        cursorconstrain(wlr_constraint);
}

pub fn cursorconstrain(wlr_constraint: *c.wlr_pointer_constraint_v1) void {
    var constraint = @ptrCast(*PointerConstraint, @alignCast(@alignOf(PointerConstraint), wlr_constraint.data));

    if (active_constraint == constraint)
        return;

    c.wl_list_remove(&pointer_constraint_commit.link);
    if (active_constraint != null) {
        //if (wlr_constraint == null)
        //    cursorwarptoconstrainthint();

        c.wlr_pointer_constraint_v1_send_deactivated(active_constraint.?.constraint);
    }

    active_constraint = constraint;

    if (true) {
        c.wl_list_init(&pointer_constraint_commit.link);
        return;
    }

    active_confine_requires_warp = true;

    if (c.pixman_region32_not_empty(&wlr_constraint.current.region) != 0) {
        _ = c.pixman_region32_intersect(&wlr_constraint.region, &wlr_constraint.surface.*.input_region, &wlr_constraint.current.region);
    } else {
        _ = c.pixman_region32_copy(&wlr_constraint.region, &wlr_constraint.surface.*.input_region);
    }

    checkconstraintregion();

    c.wlr_pointer_constraint_v1_send_activated(active_constraint.?.constraint);

    pointer_constraint_commit.notify = commitpointerconstraint;
    c.wl_signal_add(&wlr_constraint.surface.*.events.commit, &pointer_constraint_commit);
}

pub fn cursorwarptoconstrainthint() void {
    const constraint = active_constraint.?.constraint;

    if (constraint.current.committed & c.WLR_POINTER_CONSTRAINT_V1_STATE_CURSOR_HINT != 0) {
        var sx = constraint.current.cursor_hint.x;
        var sy = constraint.current.cursor_hint.y;
        var lx = sx;
        var ly = sy;

        var client: ?*Client = null;
        _ = toplevel_from_wlr_surface(constraint.surface, &client, null);
        if (client) |cli| {
            lx -= @intToFloat(f64, cli.geom.x);
            ly -= @intToFloat(f64, cli.geom.y);
        }

        _ = c.wlr_cursor_warp(cursor, null, lx, ly);

        c.wlr_seat_pointer_warp(seat, sx, sy);
    }
}

pub fn pointerconstraintsetregion(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;

    var constraint: *PointerConstraint = undefined;
    constraint = c.wl_container_of(listener, constraint, "set_region");
    active_confine_requires_warp = true;
    constraint.constraint.surface.*.data = null;
}

pub fn destroypointerconstraint(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;

    var constraint: *PointerConstraint = undefined;
    constraint = c.wl_container_of(listener, constraint, "destroy");

    c.wl_list_remove(&constraint.set_region.link);
    c.wl_list_remove(&constraint.destroy.link);

    if (active_constraint == constraint) {
        cursorwarptoconstrainthint();

        if (pointer_constraint_commit.link.next != null)
            c.wl_list_remove(&pointer_constraint_commit.link);

        c.wl_list_init(&pointer_constraint_commit.link);
        active_constraint = null;
    }

    allocator.destroy(constraint);
}

pub fn commitpointerconstraint(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;
    _ = data;

    checkconstraintregion();
}

pub fn createlayersurface(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;

    var wlr_layer_surface = @ptrCast(*c.wlr_layer_surface_v1, @alignCast(@alignOf(c.wlr_layer_surface_v1), data));
    if (wlr_layer_surface.output == null)
        wlr_layer_surface.output = if (selmon != null) selmon.?.output else null;

    if (wlr_layer_surface.output == null)
        c.wlr_layer_surface_v1_destroy(wlr_layer_surface);

    var layersurface = allocator.create(LayerSurface) catch return;
    layersurface.type = .LayerShell;

    layersurface.surface_commit.notify = commitlayersurfacenotify;
    c.wl_signal_add(&wlr_layer_surface.surface.*.events.commit, &layersurface.surface_commit);
    layersurface.destroy.notify = destroylayersurfacenotify;
    c.wl_signal_add(&wlr_layer_surface.events.destroy, &layersurface.destroy);
    layersurface.map.notify = maplayersurfacenotify;
    c.wl_signal_add(&wlr_layer_surface.events.map, &layersurface.map);
    layersurface.unmap.notify = unmaplayersurfacenotify;
    c.wl_signal_add(&wlr_layer_surface.events.unmap, &layersurface.unmap);

    layersurface.layer_surface = wlr_layer_surface;
    layersurface.mon = @ptrCast(*Monitor, @alignCast(@alignOf(Monitor), wlr_layer_surface.output.*.data));
    wlr_layer_surface.data = layersurface;

    layersurface.scene_layer = c.wlr_scene_layer_surface_v1_create(layers.get(@intToEnum(Layer, wlr_layer_surface.pending.layer)), wlr_layer_surface);
    layersurface.scene = layersurface.scene_layer.tree;
    layersurface.popups = c.wlr_scene_tree_create(layers.get(@intToEnum(Layer, wlr_layer_surface.pending.layer)));

    layersurface.scene.node.data = layersurface;

    layersurface.mon.?.layers[wlr_layer_surface.pending.layer].append(layersurface) catch return;

    var old_state = wlr_layer_surface.current;
    wlr_layer_surface.current = wlr_layer_surface.pending;
    layersurface.mapped = true;
    arrangelayers(layersurface.mon.?);
    wlr_layer_surface.current = old_state;
}

pub fn commitlayersurfacenotify(listener: [*c]c.wl_listener, _: ?*anyopaque) callconv(.C) void {
    var layersurface: *LayerSurface = undefined;
    layersurface = c.wl_container_of(listener, layersurface, "surface_commit");

    var wlr_layer_surface = layersurface.layer_surface;
    var wlr_output = wlr_layer_surface.output;

    layersurface.mon = @ptrCast(*Monitor, @alignCast(@alignOf(Monitor), wlr_output.*.data));

    if (wlr_output == null)
        return;

    var lyr = layers.get(@intToEnum(Layer, wlr_layer_surface.current.layer));
    if (lyr != layersurface.scene.node.parent) {
        c.wlr_scene_node_reparent(&layersurface.scene.node, lyr);
        c.wlr_scene_node_reparent(&layersurface.popups.node, lyr);
    }

    if (wlr_layer_surface.current.layer < c.ZWLR_LAYER_SHELL_V1_LAYER_TOP)
        c.wlr_scene_node_reparent(&layersurface.popups.node, layers.get(.LyrTop));

    if (wlr_layer_surface.current.committed == 0 and layersurface.mapped == wlr_layer_surface.mapped)
        return;
    layersurface.mapped = wlr_layer_surface.mapped;

    arrangelayers(layersurface.mon.?);
}

pub fn destroylayersurfacenotify(listener: [*c]c.wl_listener, _: ?*anyopaque) callconv(.C) void {
    var layersurface: *LayerSurface = undefined;
    layersurface = c.wl_container_of(listener, layersurface, "destroy");

    var list = &(layersurface.mon.?.layers[layersurface.layer_surface.pending.layer]);

    var idx = std.mem.indexOf(*LayerSurface, list.*.items, &.{layersurface}) orelse 0;
    _ = list.*.orderedRemove(idx);

    c.wl_list_remove(&layersurface.destroy.link);
    c.wl_list_remove(&layersurface.map.link);
    c.wl_list_remove(&layersurface.unmap.link);
    c.wl_list_remove(&layersurface.surface_commit.link);
    c.wlr_scene_node_destroy(&layersurface.scene.node);
    allocator.destroy(layersurface);
}

pub fn maplayersurfacenotify(listener: [*c]c.wl_listener, _: ?*anyopaque) callconv(.C) void {
    var layersurface: *LayerSurface = undefined;
    layersurface = c.wl_container_of(listener, layersurface, "map");

    c.wlr_surface_send_enter(layersurface.layer_surface.surface, layersurface.mon.?.output);
    motionnotify(0, null, 0, 0, 0, 0);
}

pub fn unmaplayersurfacenotify(listener: [*c]c.wl_listener, _: ?*anyopaque) callconv(.C) void {
    var layersurface: *LayerSurface = undefined;
    layersurface = c.wl_container_of(listener, layersurface, "unmap");

    layersurface.mapped = false;
    c.wlr_scene_node_set_enabled(&layersurface.scene.node, false);
    if (@ptrToInt(layersurface) == exclusive_focus)
        exclusive_focus = null;
    layersurface.mon = @ptrCast(*Monitor, @alignCast(@alignOf(Monitor), layersurface.layer_surface.output.*.data));
    if (layersurface.layer_surface.*.output != null and layersurface.mon != null)
        arrangelayers(layersurface.mon.?);
    motionnotify(0, null, 0, 0, 0, 0);
}

pub fn createnotify(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;
    var xdg_surface = @ptrCast(*c.wlr_xdg_surface, @alignCast(@alignOf(c.wlr_xdg_surface), data));
    var l: ?*LayerSurface = null;

    if (xdg_surface.role == c.WLR_XDG_SURFACE_ROLE_POPUP) {
        var box: c.wlr_box = undefined;
        var client: ?*Client = undefined;

        var kind = toplevel_from_wlr_surface(xdg_surface.surface, &client, &l);

        if (xdg_surface.unnamed_0.popup.*.parent == null or kind == .Undefined)
            return;
        var scene_tree: *c.wlr_scene_tree = @ptrCast(*c.wlr_scene_tree, @alignCast(@alignOf(c.wlr_scene_tree), xdg_surface.unnamed_0.popup.*.parent.*.data));

        xdg_surface.surface.*.data = c.wlr_scene_xdg_surface_create(scene_tree, xdg_surface);

        if ((l != null and l.?.mon == null) or (client.?.mon == null))
            return;
        box = if (kind == .LayerShell) l.?.mon.?.m else client.?.mon.?.w;
        box.x -= if (kind == .LayerShell) l.?.geom.x else client.?.geom.x;
        box.y -= if (kind == .LayerShell) l.?.geom.y else client.?.geom.y;
        c.wlr_xdg_popup_unconstrain_from_box(xdg_surface.unnamed_0.popup, &box);
        return;
    } else if (xdg_surface.role == c.WLR_XDG_SURFACE_ROLE_NONE)
        return;

    var client = allocator.create(Client) catch return;
    client.* = std.mem.zeroInit(Client, .{
        .scene = undefined,
        .scene_surface = undefined,
        .border = undefined,
        .surface = undefined,
        .type = .XDGShell,
    });

    xdg_surface.data = client;

    client.surface = .{ .xdg = xdg_surface };
    client.bw = borderpx;

    client.map.notify = mapnotify;
    c.wl_signal_add(&xdg_surface.events.map, &client.map);
    client.unmap.notify = unmapnotify;
    c.wl_signal_add(&xdg_surface.events.unmap, &client.unmap);
    client.destroy.notify = destroynotify;
    c.wl_signal_add(&xdg_surface.events.destroy, &client.destroy);
    client.set_title.notify = updatetitle;
    c.wl_signal_add(&xdg_surface.unnamed_0.toplevel.*.events.set_title, &client.set_title);
    client.fullscreen.notify = fullscreennotify;
    c.wl_signal_add(&xdg_surface.unnamed_0.toplevel.*.events.request_fullscreen, &client.fullscreen);
    client.maximize.notify = maximizenotify;
    c.wl_signal_add(&xdg_surface.unnamed_0.toplevel.*.events.request_maximize, &client.maximize);
}

pub fn client_update_frame(client: *Client, force: bool) void {
    if (client.geom.width == 0 or client.geom.height == 0) return;

    if (client.titlescene == null) {
        client.titlescene = c.wlr_scene_buffer_create(client.scene, null);
    }

    var targframe = client.frame and !client.isfullscreen;

    var totalTabs: i32 = 0;
    if (targframe and !client.isfloating) {
        for (clients.items) |tabClient| {
            if (!visible_on(tabClient, client.mon.?) or tabClient.isfloating) continue;
            if (client.container != tabClient.container) continue;
            totalTabs += 1;
        }
    } else {
        totalTabs = 1;
    }

    var focused = if (fstack.items.len != 0) client == fstack.items[0] else false;

    if (!force and client.hasframe == targframe and client.frameTabs == totalTabs and client.title != null and focused == client.framefocused) return;
    client.hasframe = targframe;
    client.frameTabs = totalTabs;
    client.framefocused = focused;

    if (client.title != null) {
        c.wlr_scene_buffer_set_buffer(client.titlescene, null);
        client.title.?.base.impl.*.destroy.?(&client.title.?.base);
        client.title = null;
    }

    client.title = buffers.buffer_create_cairo(@intCast(u32, client.geom.width), @intCast(u32, barheight + client.bw), bufferScale, true);

    var cairo = client.title.?.cairo;

    var surf = c.cairo_get_target(cairo);

    var tabWidth: f64 = @intToFloat(f64, client.geom.width - client.bw) / @intToFloat(f64, client.frameTabs);

    var currentTab: i32 = 0;
    for (clients.items) |tabClient| {
        if (tabClient != client) {
            if (!visible_on(tabClient, client.mon.?) or tabClient.isfloating) continue;
            if (client.container != tabClient.container) continue;
        }
        c.cairo_select_font_face(cairo, "CaskaydiaCovePL Nerd Font", c.CAIRO_FONT_SLANT_NORMAL, c.CAIRO_FONT_WEIGHT_NORMAL);
        c.cairo_set_font_size(cairo, @intToFloat(f64, barheight - 2 * barpadding));
        c.cairo_rectangle(cairo, @intToFloat(f64, tabClient.bw) + tabWidth * @intToFloat(f64, currentTab), @intToFloat(f64, tabClient.bw), tabWidth - @intToFloat(f64, tabClient.bw), @intToFloat(f64, barheight));
        c.cairo_set_source_rgba(cairo, 0, 0, 0, 0.2);
        if (client == tabClient)
            c.cairo_set_source_rgba(cairo, 1, 1, 1, 0.2);
        c.cairo_fill(cairo);

        c.cairo_move_to(cairo, @intToFloat(f64, tabClient.bw + barpadding) + tabWidth * @intToFloat(f64, currentTab), @intToFloat(f64, barheight - barpadding - tabClient.bw));
        const title = client_get_title(tabClient) orelse "???";
        c.cairo_text_path(cairo, title.ptr);
        c.cairo_set_source_rgba(cairo, 1, 1, 1, 1);
        c.cairo_fill(cairo);
        const default: []const u8 = "X";

        var tmpIcon = tabClient.icon orelse (client_get_title(tabClient) orelse default)[0..1];

        var icon = allocator.dupeZ(u8, tmpIcon) catch unreachable;
        defer allocator.free(icon);

        var exts: c.cairo_text_extents_t = undefined;
        c.cairo_text_extents(cairo, icon.ptr, &exts);

        c.cairo_move_to(cairo, @intToFloat(f64, currentTab + 1) * tabWidth - exts.width - @intToFloat(f64, tabClient.bw), @intToFloat(f64, barheight - barpadding - tabClient.bw));
        c.cairo_text_path(cairo, icon.ptr);
        c.cairo_set_source_rgba(cairo, 1, 1, 1, 1);
        c.cairo_fill(cairo);

        currentTab += 1;
    }

    c.cairo_surface_flush(surf);

    c.wlr_scene_buffer_set_buffer(client.titlescene, &client.title.?.base);

    if (client.hasframe) {
        c.wlr_scene_buffer_set_dest_size(client.titlescene.?, @intCast(i32, client.geom.width), @intCast(i32, client.title.?.unscaled_height));
    } else {
        c.wlr_scene_buffer_set_dest_size(client.titlescene.?, 1, 1);
    }
}

pub fn mapnotify(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;

    var client: *Client = undefined;
    client = c.wl_container_of(listener, client, "map");
    client.scene = c.wlr_scene_tree_create(layers.get(.LyrTile));
    c.wlr_scene_node_set_enabled(&client.scene.node, client.type != .XDGShell);
    client.scene_surface = if (client.type == .XDGShell)
        c.wlr_scene_xdg_surface_create(client.scene, client.surface.xdg)
    else
        c.wlr_scene_subsurface_tree_create(client.scene, client_surface(client));

    if (client_surface(client)) |client_surf| {
        client_surf.data = client.scene;

        client.commit.notify = commitnotify;
        c.wl_signal_add(&client_surf.events.commit, &client.commit);
    }

    client.scene.node.data = client;
    client.scene_surface.node.data = client;

    before: {
        if (client.type == .X11Unmanaged) {
            client_get_geometry(client, &client.geom);
            c.wlr_scene_node_reparent(&client.scene.node, layers.get(.LyrFloat));
            c.wlr_scene_node_set_position(&client.scene.node, client.geom.x + borderpx, client.geom.y + borderpx);

            if (client_wants_focus(client)) {
                focusclient(client, true);
                exclusive_focus = @ptrToInt(client);
            }
            break :before;
        }

        for (&client.border) |*border| {
            border.* = c.wlr_scene_rect_create(client.scene, 0, 0, &bordercolor);
            border.*.node.data = client;
        }

        client_set_tiled(client, c.WLR_EDGE_TOP | c.WLR_EDGE_BOTTOM | c.WLR_EDGE_LEFT | c.WLR_EDGE_RIGHT);
        client_get_geometry(client, &client.geom);
        client.geom.width += 2 * client.bw;
        client.geom.height += 2 * client.bw;

        clients.append(client) catch return;
        fstack.insert(0, client) catch return;

        if (client.type == .XDGShell) {
            if (client_get_parent(client)) |p| {
                client.isfloating = true;
                c.wlr_scene_node_reparent(&client.scene.node, layers.get(.LyrFloat));
                setmon(client, p.mon, p.tags);
            } else {
                applyrules(client);
            }
        } else {
            applyrules(client);
        }

        printstatus();
    }

    var mon = client.mon orelse xytomon(@intToFloat(f64, client.geom.x), @intToFloat(f64, client.geom.y));
    for (clients.items) |w|
        if (w != client and w.isfullscreen and mon == w.mon and (w.tags & client.tags != 0))
            setfullscreen(w, false);

    if (client.isfloating) {
        client.frame = true;
        resize(client, client.geom, false);
    }

    client_update_frame(client, false);
}

pub fn client_set_tiled(client: *Client, edges: u32) void {
    if (client.type == .X11Managed or client.type == .X11Unmanaged)
        return;
    _ = c.wlr_xdg_toplevel_set_tiled(client.surface.xdg.unnamed_0.toplevel, edges);
}

pub fn client_get_parent(client: *Client) ?*Client {
    var p: ?*Client = null;
    if ((client.type == .X11Managed or client.type == .X11Unmanaged) and client.surface.xwayland.parent != null) {
        _ = toplevel_from_wlr_surface(client.surface.xwayland.parent.*.surface, &p, null);
        return p;
    }
    if (client.surface.xdg.unnamed_0.toplevel.*.parent != null)
        _ = toplevel_from_wlr_surface(client.surface.xdg.unnamed_0.toplevel.*.parent.*.base.*.surface, &p, null);
    return p;
}

pub fn client_get_geometry(client: *Client, geom: *c.wlr_box) void {
    if (client.type == .X11Managed or client.type == .X11Unmanaged) {
        geom.x = client.surface.xwayland.x;
        geom.y = client.surface.xwayland.y;
        geom.width = client.surface.xwayland.width;
        geom.height = client.surface.xwayland.height;
        return;
    }
    c.wlr_xdg_surface_get_geometry(client.surface.xdg, geom);
}

pub fn applyrules(client: *Client) void {
    client.isfloating = client_is_float_type(client);
    var mon = selmon;
    var newtags: u32 = 0;
    var appid = client_get_appid(client) orelse "broken";
    var title = client_get_title(client) orelse "broken";

    for (configData.rules) |r| {
        std.log.info("{any}", .{r});
        if ((r.id == null or std.mem.eql(u8, appid, r.id.?)) and (r.title == null or std.mem.eql(u8, title, r.title.?))) {
            client.isfloating = r.isfloating;
            client.iscentered = r.center;
            client.container = r.container;
            client.title_override = r.name;
            client.icon = r.icon;

            newtags |= r.tags;
            for (mons, 0..) |m, idx| {
                if (r.monitor == idx) {
                    mon = m;
                }
            }
            std.log.info("{?s}, {?s}", .{ r.id, r.title });
        }
    }

    if (client.iscentered) {
        client.geom.x = @divFloor(mon.?.w.width - client.geom.width, 2) + mon.?.m.x;
        client.geom.y = @divFloor(mon.?.w.height - client.geom.height, 2) + mon.?.m.y;
    }

    c.wlr_scene_node_reparent(&client.scene.node, layers.get(if (client.isfloating) .LyrFloat else .LyrTile));
    setmon(client, mon, newtags);
}

pub fn client_get_appid(client: *Client) ?[]const u8 {
    var result: []const u8 = undefined;

    if (client.type == .X11Managed or client.type == .X11Unmanaged) {
        result.ptr = client.surface.xwayland.class orelse return null;
    } else {
        result.ptr = client.surface.xdg.unnamed_0.toplevel.*.app_id orelse return null;
    }
    result.len = c.strlen(result.ptr);
    return result;
}

pub fn client_get_title(client: *Client) ?[]const u8 {
    var result: []const u8 = undefined;

    if (client.title_override) |override| return override;

    if (client.type == .X11Managed or client.type == .X11Unmanaged) {
        result.ptr = client.surface.xwayland.title orelse return null;
    } else {
        result.ptr = client.surface.xdg.unnamed_0.toplevel.*.title orelse return null;
    }
    result.len = c.strlen(result.ptr);
    return result;
}

pub fn client_is_float_type(client: *Client) bool {
    var min = std.mem.zeroes(c.wlr_box);
    var max = std.mem.zeroes(c.wlr_box);

    client_get_size_hints(client, &min, &max);

    if (client.type == .X11Managed or client.type == .X11Unmanaged) {
        var surface = client.surface.xwayland;
        if (surface.modal)
            return true;

        for (0..surface.window_type_len, surface.window_type) |_, window_type| {
            if (window_type == netatom.get(.NetWMWindowTypeDialog) or window_type == netatom.get(.NetWMWindowTypeSplash) or window_type == netatom.get(.NetWMWindowTypeToolbar) or window_type == netatom.get(.NetWMWindowTypeUtility))
                return true;
        }
    }

    return ((min.width > 0 or min.height > 0 or max.width > 0 or max.height > 0) and (min.width == max.width or min.height == max.height));
}

pub fn commitnotify(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;

    var client: *Client = undefined;
    client = c.wl_container_of(listener, client, "commit");

    var box = std.mem.zeroes(c.wlr_box);
    client_get_geometry(client, &box);

    if (client.mon != null and !c.wlr_box_empty(&box) and (box.width != client.geom.width - 2 * client.bw or box.height != client.geom.height - 2 * client.bw))
        if (client.isfloating)
            resize(client, client.geom, true)
        else
            arrange(client.mon.?);

    if (client.resize != 0 and client.resize <= client.surface.xdg.current.configure_serial)
        client.resize = 0;
}

pub fn unmapnotify(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;

    var client: *Client = undefined;
    client = c.wl_container_of(listener, client, "unmap");

    if (client == grabc) {
        cursor_mode = .CurNormal;
        grabc = null;
    }

    if (client.type == .X11Unmanaged) {
        if (@ptrToInt(client) == exclusive_focus)
            exclusive_focus = null;
        if (client_surface(client) == seat.keyboard_state.focused_surface)
            focusclient(client, true);
    } else {
        var cidx = std.mem.indexOf(*Client, clients.items, &.{client}) orelse return;
        var fidx = std.mem.indexOf(*Client, fstack.items, &.{client}) orelse return;
        _ = clients.orderedRemove(cidx);
        setmon(client, null, 0);
        _ = fstack.orderedRemove(fidx);
    }

    c.wl_list_remove(&client.commit.link);
    c.wlr_scene_node_destroy(&client.scene.node);
    printstatus();
    motionnotify(0, null, 0, 0, 0, 0);
}

pub fn outputmgrapply(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;

    var config = @ptrCast(*c.wlr_output_configuration_v1, @alignCast(@alignOf(c.wlr_output_configuration_v1), data));

    outputmgrapplyortest(config, false);
}

pub fn outputmgrapplyortest(config: *c.wlr_output_configuration_v1, tst: bool) void {
    var ok = true;

    var config_head: *c.wlr_output_configuration_head_v1 = undefined;
    config_head = c.wl_container_of(&config.heads, config_head, "link");

    while (&config_head.link != &config.heads) {
        config_head = c.wl_container_of(config_head.link.next, config_head, "link");

        var wlr_output = config_head.state.output;
        prefix: {
            var m = @ptrCast(*Monitor, @alignCast(@alignOf(Monitor), wlr_output.*.data));
            c.wlr_output_enable(wlr_output, config_head.state.enabled);
            if (!config_head.state.enabled) break :prefix;
            if (config_head.state.mode != 0) {
                c.wlr_output_set_mode(wlr_output, config_head.state.mode);
            } else {
                c.wlr_output_set_custom_mode(wlr_output, config_head.state.custom_mode.width, config_head.state.custom_mode.height, config_head.state.custom_mode.refresh);
            }
            if (m.m.x != config_head.state.x or m.m.y != config_head.state.y)
                c.wlr_output_layout_move(output_layout, wlr_output, config_head.state.x, config_head.state.y);
            c.wlr_output_set_transform(wlr_output, config_head.state.transform);
            c.wlr_output_set_scale(wlr_output, config_head.state.scale);
            c.wlr_output_enable_adaptive_sync(wlr_output, config_head.state.adaptive_sync_enabled);
        }

        if (tst) {
            ok = ok and c.wlr_output_test(wlr_output);
            c.wlr_output_rollback(wlr_output);
        } else {
            ok = ok and c.wlr_output_commit(wlr_output);
        }
    }

    if (ok)
        c.wlr_output_configuration_v1_send_succeeded(config)
    else
        c.wlr_output_configuration_v1_send_failed(config);
    c.wlr_output_configuration_v1_destroy(config);
    updatemons(null, null);
}

pub fn updatetitle(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;
    var client: *Client = undefined;
    client = c.wl_container_of(listener, client, "set_title");
    if (client == focustop(client.mon))
        printstatus();

    client_update_frame(client, true);
}

pub fn setcursor(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;

    var event = @ptrCast(*c.wlr_seat_pointer_request_set_cursor_event, @alignCast(@alignOf(c.wlr_seat_pointer_request_set_cursor_event), data));

    if (cursor_mode != .CurNormal and cursor_mode != .CurPressed)
        return;

    cursor_image = null;
    if (event.seat_client == seat.pointer_state.focused_client)
        c.wlr_cursor_set_surface(cursor, event.surface, event.hotspot_x, event.hotspot_y);
}

pub fn fullscreennotify(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;

    var client: *Client = undefined;
    client = c.wl_container_of(listener, client, "fullscreen");
    setfullscreen(client, client_wants_fullscreen(client));
}

pub fn client_wants_fullscreen(client: *Client) bool {
    if (client.type == .X11Managed or client.type == .X11Unmanaged) {
        return client.surface.xwayland.fullscreen;
    }

    return client.surface.xdg.unnamed_0.toplevel.*.requested.fullscreen;
}

pub fn maximizenotify(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;
    var client: *Client = undefined;
    client = c.wl_container_of(listener, client, "maximize");
    _ = c.wlr_xdg_surface_schedule_configure(client.surface.xdg);
}

pub fn destroynotify(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;

    var client: *Client = undefined;
    client = c.wl_container_of(listener, client, "destroy");

    c.wl_list_remove(&client.map.link);
    c.wl_list_remove(&client.unmap.link);
    c.wl_list_remove(&client.destroy.link);
    c.wl_list_remove(&client.set_title.link);
    c.wl_list_remove(&client.fullscreen.link);

    if (client.type != .XDGShell) {
        c.wl_list_remove(&client.configure.link);
        c.wl_list_remove(&client.set_hints.link);
        c.wl_list_remove(&client.activate.link);
    }

    if (client.titlescene != null)
        client.title.?.base.impl.*.destroy.?(&client.title.?.base);

    allocator.destroy(client);
}

pub fn createnotifyx11(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;
    var xsurface = @ptrCast(*c.wlr_xwayland_surface, @alignCast(@alignOf(c.wlr_xwayland_surface), data));

    var client = allocator.create(Client) catch return;
    client.* = std.mem.zeroInit(Client, .{
        .scene = undefined,
        .scene_surface = undefined,
        .border = undefined,
        .surface = undefined,
    });

    xsurface.data = client;

    client.surface = .{ .xwayland = xsurface };
    client.type = if (xsurface.override_redirect) .X11Unmanaged else .X11Managed;
    client.bw = borderpx;

    client.map.notify = mapnotify;
    c.wl_signal_add(&xsurface.events.map, &client.map);
    client.unmap.notify = unmapnotify;
    c.wl_signal_add(&xsurface.events.unmap, &client.unmap);
    client.activate.notify = activatex11;
    c.wl_signal_add(&xsurface.events.request_activate, &client.activate);
    client.configure.notify = configurex11;
    c.wl_signal_add(&xsurface.events.request_configure, &client.configure);
    client.set_hints.notify = sethints;
    c.wl_signal_add(&xsurface.events.set_hints, &client.set_hints);
    client.set_title.notify = updatetitle;
    c.wl_signal_add(&xsurface.events.set_title, &client.set_title);
    client.destroy.notify = destroynotify;
    c.wl_signal_add(&xsurface.events.destroy, &client.destroy);
    client.fullscreen.notify = fullscreennotify;
    c.wl_signal_add(&xsurface.events.request_fullscreen, &client.fullscreen);
}

pub fn activatex11(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;

    var client: *Client = undefined;
    client = c.wl_container_of(listener, client, "activate");

    if (client.type == .X11Managed)
        c.wlr_xwayland_surface_activate(client.surface.xwayland, true);
}

pub fn configurex11(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    var client: *Client = undefined;
    client = c.wl_container_of(listener, client, "configure");

    var event = @ptrCast(*c.wlr_xwayland_surface_configure_event, @alignCast(@alignOf(c.wlr_xwayland_surface_configure_event), data));
    if (client.mon == null)
        return;
    if (client.isfloating or client.type == .X11Unmanaged)
        resize(client, .{
            .x = event.x,
            .y = event.y,
            .width = event.width,
            .height = event.height,
        }, false)
    else
        arrange(client.mon.?);
}

pub fn sethints(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;
    var client: *Client = undefined;
    client = c.wl_container_of(listener, client, "set_hints");
    if (client != focustop(selmon)) {
        printstatus();
    }
}

pub fn locksession(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;
    _ = listener;
}

pub fn destroysessionmgr(_: [*c]c.wl_listener, _: ?*anyopaque) callconv(.C) void {
    c.wl_list_remove(&session_lock_create_lock.link);
    c.wl_list_remove(&session_lock_mgr_destroy.link);
}

pub fn createdecoration(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;
    var dec = @ptrCast(*c.wlr_xdg_toplevel_decoration_v1, @alignCast(@alignOf(c.wlr_xdg_toplevel_decoration_v1), data));
    _ = c.wlr_xdg_toplevel_decoration_v1_set_mode(dec, c.WLR_XDG_TOPLEVEL_DECORATION_V1_MODE_SERVER_SIDE);
}

pub fn requeststartdrag(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;
    var event = @ptrCast(*c.wlr_seat_request_start_drag_event, @alignCast(@alignOf(c.wlr_seat_request_start_drag_event), data));
    if (c.wlr_seat_validate_pointer_grab_serial(seat, event.origin, event.serial))
        c.wlr_seat_start_pointer_drag(seat, event.drag, event.serial)
    else
        c.wlr_data_source_destroy(event.drag.*.source);
}

pub fn startdrag(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;
    var drag = @ptrCast(*c.wlr_drag, @alignCast(@alignOf(c.wlr_drag), data));

    if (drag.icon == null) return;

    drag.icon.*.data = c.wlr_scene_subsurface_tree_create(layers.get(.LyrDragIcon), drag.icon.*.surface);
    motionnotify(0, null, 0, 0, 0, 0);
    c.wl_signal_add(&drag.icon.*.events.destroy, &drag_icon_destroy);
}

pub fn destroydragicon(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;
    var icon = @ptrCast(*c.wlr_drag_icon, @alignCast(@alignOf(c.wlr_drag_icon), data));

    c.wlr_scene_node_destroy(@ptrCast(*c.wlr_scene_node, @alignCast(@alignOf(c.wlr_scene_node), icon.data)));

    focusclient(focustop(selmon), true);
    motionnotify(0, null, 0, 0, 0, 0);
}

pub fn motionrelative(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;

    var event = @ptrCast(*c.wlr_pointer_motion_event, @alignCast(@alignOf(c.wlr_pointer_motion_event), data));

    motionnotify(event.time_msec, &event.pointer.*.base, event.delta_x, event.delta_y, event.unaccel_dx, event.unaccel_dy);
}

pub fn motionabsolute(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;

    var event = @ptrCast(*c.wlr_pointer_motion_absolute_event, @alignCast(@alignOf(c.wlr_pointer_motion_absolute_event), data));

    var lx: f64 = undefined;
    var ly: f64 = undefined;
    var dx: f64 = undefined;
    var dy: f64 = undefined;
    c.wlr_cursor_absolute_to_layout_coords(cursor, &event.pointer.*.base, event.x, event.y, &lx, &ly);
    dx = lx - cursor.x;
    dy = ly - cursor.y;

    motionnotify(event.time_msec, &event.pointer.*.base, dx, dy, dx, dy);
}

pub fn buttonpress(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;
    var event = @ptrCast(*c.wlr_pointer_button_event, @alignCast(@alignOf(c.wlr_pointer_button_event), data));

    c.wlr_idle_notify_activity(idle, seat);
    c.wlr_idle_notifier_v1_notify_activity(idle_notifier, seat);

    switch (event.state) {
        c.WLR_BUTTON_PRESSED => sw: {
            cursor_mode = .CurPressed;
            if (locked)
                break :sw;

            var client: ?*Client = undefined;

            _ = xytonode(cursor.x, cursor.y, null, &client, null, null, null);

            if (client != null and (client.?.type != .X11Unmanaged or client_wants_focus(client.?)))
                focusclient(client.?, true);

            var keyboard = c.wlr_seat_get_keyboard(seat);
            var mods = if (keyboard != null) c.wlr_keyboard_get_modifiers(keyboard) else 0;

            for (configData.buttons) |b| {
                if (cleanmask(mods) == cleanmask(b.mod) and event.button == b.button) {
                    b.cmd.run();
                    return;
                }
            }
        },
        c.WLR_BUTTON_RELEASED => {
            if (!locked and cursor_mode != .CurNormal and cursor_mode != .CurPressed) {
                cursor_mode = .CurNormal;

                c.wlr_seat_pointer_clear_focus(seat);
                motionnotify(0, null, 0, 0, 0, 0);
                selmon = xytomon(cursor.x, cursor.y);
                setmon(grabc.?, selmon, 0);
            } else cursor_mode = .CurNormal;
        },
        else => {},
    }

    _ = c.wlr_seat_pointer_notify_button(seat, event.time_msec, event.button, event.state);
}

pub fn axisnotify(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;

    c.wlr_idle_notify_activity(idle, seat);
    c.wlr_idle_notifier_v1_notify_activity(idle_notifier, seat);

    var event = @ptrCast(*c.wlr_pointer_axis_event, @alignCast(@alignOf(c.wlr_pointer_axis_event), data));
    c.wlr_seat_pointer_notify_axis(seat, event.time_msec, event.orientation, event.delta, event.delta_discrete, event.source);
}

pub fn cursorframe(_: [*c]c.wl_listener, _: ?*anyopaque) callconv(.C) void {
    c.wlr_seat_pointer_notify_frame(seat);
}

pub fn virtualkeyboard(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;
    _ = listener;
}

pub fn keypressmod(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;

    var kb: *Keyboard = undefined;
    kb = c.wl_container_of(listener, kb, "modifiers");

    c.wlr_seat_set_keyboard(seat, kb.wlr_keyboard);
    c.wlr_seat_keyboard_notify_modifiers(seat, &kb.wlr_keyboard.modifiers);
}

pub fn keypress(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    var kb: *Keyboard = undefined;
    kb = c.wl_container_of(listener, kb, "key");
    var event = @ptrCast(*c.wlr_keyboard_key_event, @alignCast(@alignOf(c.wlr_keyboard_key_event), data));
    var keycode: u32 = event.keycode + 8;
    var syms: [*c]const u32 = undefined;
    var nsyms = c.xkb_state_key_get_syms(kb.wlr_keyboard.xkb_state, keycode, &syms);

    var handled = false;
    var mods = c.wlr_keyboard_get_modifiers(kb.wlr_keyboard);

    c.wlr_idle_notify_activity(idle, seat);
    c.wlr_idle_notifier_v1_notify_activity(idle_notifier, seat);

    if (!locked and input_inhibit_mgr.active_inhibitor == null and event.state == c.WL_KEYBOARD_KEY_STATE_PRESSED) {
        for (0..@intCast(usize, nsyms), syms) |_, sym| {
            handled = keybinding(mods, sym) or handled;
        }
    }

    if (handled and kb.wlr_keyboard.repeat_info.delay > 0) {
        kb.mods = mods;
        kb.keysyms.ptr = syms;
        kb.keysyms.len = @intCast(usize, nsyms);
        _ = c.wl_event_source_timer_update(kb.key_repeat_source, kb.wlr_keyboard.repeat_info.delay);
    } else {
        kb.keysyms.len = 0;
        _ = c.wl_event_source_timer_update(kb.key_repeat_source, 0);
    }

    if (!handled) {
        c.wlr_seat_set_keyboard(seat, kb.wlr_keyboard);
        c.wlr_seat_keyboard_notify_key(seat, event.time_msec, event.keycode, event.state);
    }
}

pub fn inputdevice(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = listener;
    var device = @ptrCast(*c.wlr_input_device, @alignCast(@alignOf(c.wlr_input_device), data));

    switch (device.type) {
        c.WLR_INPUT_DEVICE_KEYBOARD => createkeyboard(c.wlr_keyboard_from_input_device(device)),
        c.WLR_INPUT_DEVICE_POINTER => createpointer(c.wlr_pointer_from_input_device(device)),
        else => {},
    }

    var caps: u32 = c.WL_SEAT_CAPABILITY_POINTER;
    if (keyboards.items.len != 0)
        caps |= c.WL_SEAT_CAPABILITY_KEYBOARD;
    c.wlr_seat_set_capabilities(seat, caps);
}

pub inline fn cleanmask(mask: u32) u32 {
    return mask & ~@as(u32, c.WLR_MODIFIER_CAPS);
}

pub fn keybinding(mods: u32, sym: c.xkb_keysym_t) bool {
    var handled = false;
    for (configData.keys) |k| {
        if (cleanmask(mods) == cleanmask(k.mod) and
            sym == k.keysym)
        {
            k.cmd.run();
            handled = true;
        }
    }
    return handled;
}

pub fn keyrepeat(data: ?*anyopaque) callconv(.C) c_int {
    var kb = @ptrCast(*Keyboard, @alignCast(@alignOf(Keyboard), data));

    if (kb.keysyms.len != 0 and kb.wlr_keyboard.repeat_info.rate > 0) {
        _ = c.wl_event_source_timer_update(kb.key_repeat_source, @divTrunc(1000, kb.wlr_keyboard.repeat_info.rate));

        for (kb.keysyms) |keysym|
            _ = keybinding(kb.mods, keysym);
    }

    return 0;
}

pub fn client_send_close(client: *Client) void {
    if (client.type == .X11Managed or client.type == .X11Unmanaged) {
        c.wlr_xwayland_surface_close(client.surface.xwayland);
        return;
    }
    c.wlr_xdg_toplevel_send_close(client.surface.xdg.unnamed_0.toplevel);
}

pub fn spawn(arg: *const cfg.Config.Arg) void {
    var proc = std.ChildProcess.init(arg.v, allocator);

    proc.spawn() catch return;
}

pub fn setlayout(arg: *const cfg.Config.Arg) void {
    if (selmon == null) return;
    var lt = &configData.layouts[@intCast(usize, arg.i)];

    if (lt != selmon.?.lt[selmon.?.sellt])
        selmon.?.sellt ^= 1;
    selmon.?.lt[selmon.?.sellt] = lt;
    selmon.?.ltsymbol = &selmon.?.lt[selmon.?.sellt].symbol;
    arrange(selmon.?);
    printstatus();
}

pub fn cyclelayout(arg: *const cfg.Config.Arg) void {
    for (configData.layouts, 0..) |_, idx| {
        if (&configData.layouts[idx] == selmon.?.lt[selmon.?.sellt]) {
            var i = @intCast(i32, idx);
            i += arg.i;
            i = @mod(i, @intCast(i32, configData.layouts.len));
            setlayout(&.{ .i = i });
            return;
        }
    }
}

pub fn view(arg: *const cfg.Config.Arg) void {
    if (selmon == null or (arg.ui & TAGMASK) == selmon.?.tagset[selmon.?.seltags])
        return;
    selmon.?.seltags ^= 1;
    if ((arg.ui & TAGMASK) != 0)
        selmon.?.tagset[selmon.?.seltags] = arg.ui & TAGMASK;
    focusclient(focustop(selmon.?), true);
    arrange(selmon.?);
    printstatus();
}

pub fn tag(arg: *const cfg.Config.Arg) void {
    if (focustop(selmon)) |sel| {
        if ((arg.ui & TAGMASK) != 0) {
            sel.tags = arg.ui & TAGMASK;
            focusclient(focustop(selmon), true);
            arrange(selmon.?);
        }
    }
    printstatus();
}

pub fn togglefloating(arg: *const cfg.Config.Arg) void {
    _ = arg;
    var sel = focustop(selmon);
    if (sel != null)
        setfloating(sel.?, !sel.?.isfloating);
}

pub fn togglefullscreen(arg: *const cfg.Config.Arg) void {
    _ = arg;
    var sel = focustop(selmon);
    if (sel != null)
        setfullscreen(sel.?, !sel.?.isfullscreen);
}

pub fn reload(arg: *const cfg.Config.Arg) void {
    _ = arg;
    configData = cfg.Config.source(".config/budland/budland.conf", allocator) catch return;
}

pub fn killclient(arg: *const cfg.Config.Arg) void {
    _ = arg;
    var sel = focustop(selmon);
    if (sel != null)
        client_send_close(sel.?);
}

pub fn focusstack(arg: *const cfg.Config.Arg) void {
    var sel = focustop(selmon);
    if (sel) |selmonsel| {
        if (selmonsel.isfloating) return;

        var targ = selmonsel.container;
        var start_mon = selmonsel.mon;

        var idx = std.mem.indexOf(*Client, clients.items, &.{selmonsel}) orelse return;
        var start = idx;
        idx += @intCast(usize, arg.i);
        if (idx >= (clients.items.len)) idx = 0;

        while ((clients.items[idx].container != targ or clients.items[idx].mon != start_mon or clients.items[idx].isfloating) and idx != start) {
            idx += @intCast(usize, arg.i);
            if (idx >= (clients.items.len)) idx = 0;
        }
        focusclient(clients.items[idx], true);
        arrange(selmon.?);
    }
}

pub fn moveresize(arg: *const cfg.Config.Arg) void {
    if (cursor_mode != .CurNormal and cursor_mode != .CurPressed)
        return;
    _ = xytonode(cursor.x, cursor.y, null, &grabc, null, null, null);

    if (grabc == null or grabc.?.type == .X11Unmanaged or grabc.?.isfullscreen)
        return;

    setfloating(grabc.?, true);

    cursor_mode = @intToEnum(Cursors, arg.ui);
    switch (cursor_mode) {
        .CurMove => {
            grabcx = @floatToInt(i32, cursor.x) - grabc.?.geom.x;
            grabcy = @floatToInt(i32, cursor.y) - grabc.?.geom.y;

            cursor_image = "fleur\x00";
            c.wlr_xcursor_manager_set_cursor_image(cursor_mgr, cursor_image.?.ptr, cursor);
        },
        .CurResize => {
            c.wlr_cursor_warp_closest(cursor, null, @intToFloat(f64, grabc.?.geom.x + grabc.?.geom.width), @intToFloat(f64, grabc.?.geom.y + grabc.?.geom.height));

            cursor_image = "bottom_right_corner\x00";
            c.wlr_xcursor_manager_set_cursor_image(cursor_mgr, cursor_image.?.ptr, cursor);
        },
        else => {},
    }
}

pub fn setcon(arg: *const cfg.Config.Arg) void {
    var sel = focustop(selmon);
    if (sel != null) {
        sel.?.container = @intCast(u8, arg.ui);
        setfloating(sel.?, false);

        arrange(selmon.?);
    }
}

pub fn quit(_: *const cfg.Config.Arg) void {
    std.log.info("poopie", .{});
    c.wl_display_terminate(dpy);
}

const xkb_rules: c.xkb_rule_names = .{
    .options = null,
    .rules = null,
    .model = null,
    .layout = null,
    .variant = null,
};

pub fn createkeyboard(keyboard: *c.wlr_keyboard) void {
    var kb = allocator.create(Keyboard) catch return;
    keyboard.data = kb;
    kb.wlr_keyboard = keyboard;

    var context = c.xkb_context_new(c.XKB_CONTEXT_NO_FLAGS);
    var keymap = c.xkb_keymap_new_from_names(context, &xkb_rules, c.XKB_KEYMAP_COMPILE_NO_FLAGS);

    _ = c.wlr_keyboard_set_keymap(keyboard, keymap);
    c.xkb_keymap_unref(keymap);
    c.xkb_context_unref(context);
    c.wlr_keyboard_set_repeat_info(keyboard, repeat_rate, repeat_delay);

    kb.modifiers.notify = keypressmod;
    c.wl_signal_add(&keyboard.events.modifiers, &kb.modifiers);
    kb.key.notify = keypress;
    c.wl_signal_add(&keyboard.events.key, &kb.key);

    // setup keypress stuff
    c.wlr_seat_set_keyboard(seat, keyboard);

    kb.key_repeat_source = c.wl_event_loop_add_timer(c.wl_display_get_event_loop(dpy), keyrepeat, kb);

    keyboards.append(kb) catch return;
}

pub fn createpointer(pointer: *c.wlr_pointer) void {
    if (c.wlr_input_device_is_libinput(&pointer.base)) {
        var libinput_device = c.wlr_libinput_get_device_handle(&pointer.base);
        if (c.libinput_device_config_scroll_has_natural_scroll(libinput_device) != 0)
            _ = c.libinput_device_config_scroll_set_natural_scroll_enabled(libinput_device, natural_scrolling);

        if (c.libinput_device_config_dwt_is_available(libinput_device) != 0)
            _ = c.libinput_device_config_dwt_set_enabled(libinput_device, disable_while_typing);

        if (c.libinput_device_config_left_handed_is_available(libinput_device) != 0)
            _ = c.libinput_device_config_left_handed_set(libinput_device, left_handed);

        if (c.libinput_device_config_middle_emulation_is_available(libinput_device) != 0)
            _ = c.libinput_device_config_middle_emulation_set_enabled(libinput_device, middle_button_emulation);

        if (c.libinput_device_config_scroll_get_methods(libinput_device) != c.LIBINPUT_CONFIG_SCROLL_NO_SCROLL)
            _ = c.libinput_device_config_scroll_set_method(libinput_device, scroll_method);

        if (c.libinput_device_config_click_get_methods(libinput_device) != c.LIBINPUT_CONFIG_CLICK_METHOD_NONE)
            _ = c.libinput_device_config_click_set_method(libinput_device, click_method);

        if (c.libinput_device_config_send_events_get_modes(libinput_device) != 0)
            _ = c.libinput_device_config_send_events_set_mode(libinput_device, send_events_mode);

        if (c.libinput_device_config_accel_is_available(libinput_device) != 0) {
            _ = c.libinput_device_config_accel_set_profile(libinput_device, accel_profile);
            _ = c.libinput_device_config_accel_set_speed(libinput_device, accel_speed);
        }
    }

    c.wlr_cursor_attach_input_device(cursor, &pointer.base);
}

pub fn getatom(xc: ?*c.xcb_connection_t, name: [*c]const u8) c.Atom {
    var atom: c.Atom = 0;
    var cookie = c.xcb_intern_atom(xc, 0, @intCast(u16, c.strlen(name)), name);
    var reply = c.xcb_intern_atom_reply(xc, cookie, null) orelse return atom;
    atom = reply.*.atom;
    c.free(reply);

    return atom;
}

pub fn xwaylandready(listener: [*c]c.wl_listener, data: ?*anyopaque) callconv(.C) void {
    _ = data;
    _ = listener;
    var xc = c.xcb_connect(xwayland.display_name, null);

    var err = c.xcb_connection_has_error(xc);
    if (err != 0) {
        std.log.info("xcb_connect to X server failed with code {}\n. Continuing with degraded functionality.\n", .{err});
        return;
    }

    netatom.set(.NetWMWindowTypeDialog, getatom(xc, "_NET_WM_WINDOW_TYPE_DIALOG"));
    netatom.set(.NetWMWindowTypeSplash, getatom(xc, "_NET_WM_WINDOW_TYPE_SPLASH"));
    netatom.set(.NetWMWindowTypeToolbar, getatom(xc, "_NET_WM_WINDOW_TYPE_TOOLBAR"));
    netatom.set(.NetWMWindowTypeUtility, getatom(xc, "_NET_WM_WINDOW_TYPE_UTILITY"));

    c.wlr_xwayland_set_seat(xwayland, seat);

    if (c.wlr_xcursor_manager_get_xcursor(cursor_mgr, "left_ptr", 1)) |xcursor| {
        c.wlr_xwayland_set_cursor(
            xwayland,
            xcursor.*.images[0].*.buffer,
            xcursor.*.images[0].*.width * 4,
            xcursor.*.images[0].*.width,
            xcursor.*.images[0].*.height,
            @intCast(i32, xcursor.*.images[0].*.hotspot_x),
            @intCast(i32, xcursor.*.images[0].*.hotspot_y),
        );
    }

    c.xcb_disconnect(xc);
}

pub fn setup() !void {
    configData = try cfg.Config.source(".config/budland/budland.conf", allocator);

    dpy = c.wl_display_create() orelse {
        return error.WaylandFailed;
    };

    backend = c.wlr_backend_autocreate(dpy) orelse {
        return error.WaylandFailed;
    };

    scene = c.wlr_scene_create();

    layers.set(.LyrBg, c.wlr_scene_tree_create(&scene.*.tree));
    layers.set(.LyrBottom, c.wlr_scene_tree_create(&scene.*.tree));
    layers.set(.LyrTile, c.wlr_scene_tree_create(&scene.*.tree));
    layers.set(.LyrFloat, c.wlr_scene_tree_create(&scene.*.tree));
    layers.set(.LyrFS, c.wlr_scene_tree_create(&scene.*.tree));
    layers.set(.LyrOverlay, c.wlr_scene_tree_create(&scene.*.tree));
    layers.set(.LyrTop, c.wlr_scene_tree_create(&scene.*.tree));
    layers.set(.LyrDragIcon, c.wlr_scene_tree_create(&scene.*.tree));
    layers.set(.LyrBlock, c.wlr_scene_tree_create(&scene.*.tree));

    drw = c.wlr_renderer_autocreate(backend) orelse {
        return error.WaylandFailed;
    };

    _ = c.wlr_renderer_init_wl_display(drw, dpy);

    alloc = c.wlr_allocator_autocreate(backend, drw) orelse {
        return error.WaylandFailed;
    };

    compositior = c.wlr_compositor_create(dpy, drw);
    _ = c.wlr_export_dmabuf_manager_v1_create(dpy);
    _ = c.wlr_screencopy_manager_v1_create(dpy);
    _ = c.wlr_data_control_manager_v1_create(dpy);
    _ = c.wlr_data_device_manager_create(dpy);
    _ = c.wlr_gamma_control_manager_v1_create(dpy);
    _ = c.wlr_primary_selection_v1_device_manager_create(dpy);
    _ = c.wlr_viewporter_create(dpy);
    _ = c.wlr_single_pixel_buffer_manager_v1_create(dpy);
    _ = c.wlr_subcompositor_create(dpy);

    output_layout = c.wlr_output_layout_create();
    c.wl_signal_add(&output_layout.events.change, &layout_change);
    _ = c.wlr_xdg_output_manager_v1_create(dpy, output_layout);

    mons = try allocator.alloc(*Monitor, 0);
    c.wl_signal_add(&backend.events.new_output, &new_output);

    clients = std.ArrayList(*Client).init(allocator);
    fstack = std.ArrayList(*Client).init(allocator);

    idle = c.wlr_idle_create(dpy);
    idle_notifier = c.wlr_idle_notifier_v1_create(dpy) orelse {
        return error.WaylandFailed;
    };

    idle_inhibit_mgr = c.wlr_idle_inhibit_v1_create(dpy);
    c.wl_signal_add(&idle_inhibit_mgr.events.new_inhibitor, &idle_inhibitor_create);

    layer_shell = c.wlr_layer_shell_v1_create(dpy);
    c.wl_signal_add(&layer_shell.events.new_surface, &new_layer_shell_surface);

    xdg_shell = c.wlr_xdg_shell_create(dpy, 4);
    c.wl_signal_add(&xdg_shell.events.new_surface, &new_xdg_surface);

    input_inhibit_mgr = c.wlr_input_inhibit_manager_create(dpy);
    session_lock_mgr = c.wlr_session_lock_manager_v1_create(dpy);
    c.wl_signal_add(&session_lock_mgr.events.new_lock, &session_lock_create_lock);
    c.wl_signal_add(&session_lock_mgr.events.destroy, &session_lock_mgr_destroy);

    locked_bg = c.wlr_scene_rect_create(layers.get(.LyrBlock), sgeom.width, sgeom.height, &[4]f32{ 0.1, 0.1, 0.1, 1.0 });
    c.wlr_scene_node_set_enabled(&locked_bg.node, false);

    c.wlr_server_decoration_manager_set_default_mode(
        c.wlr_server_decoration_manager_create(dpy),
        c.WLR_SERVER_DECORATION_MANAGER_MODE_SERVER,
    );

    xdg_decoration_mgr = c.wlr_xdg_decoration_manager_v1_create(dpy);
    c.wl_signal_add(&xdg_decoration_mgr.events.new_toplevel_decoration, &new_xdg_decoration);

    cursor = c.wlr_cursor_create();
    c.wlr_cursor_attach_output_layout(cursor, output_layout);

    cursor_mgr = c.wlr_xcursor_manager_create(null, 24);

    c.wl_signal_add(&cursor.events.motion, &cursor_motion);
    c.wl_signal_add(&cursor.events.motion_absolute, &cursor_motion_absolute);
    c.wl_signal_add(&cursor.events.button, &cursor_button);
    c.wl_signal_add(&cursor.events.axis, &cursor_axis);
    c.wl_signal_add(&cursor.events.frame, &cursor_frame);

    keyboards = std.ArrayList(*Keyboard).init(allocator);
    c.wl_signal_add(&backend.events.new_input, &new_input);
    virtual_keyboard_mgr = c.wlr_virtual_keyboard_manager_v1_create(dpy);
    c.wl_signal_add(&virtual_keyboard_mgr.events.new_virtual_keyboard, &new_virtual_keyboard);
    seat = c.wlr_seat_create(dpy, "seat0");
    c.wl_signal_add(&seat.events.request_set_cursor, &request_cursor);
    // c.wl_signal_add(&seat.events.request_set_selection, &request_set_sel);
    // c.wl_signal_add(&seat.events.request_set_primary_selection, &request_set_psel);
    c.wl_signal_add(&seat.events.request_start_drag, &request_start_drag);
    c.wl_signal_add(&seat.events.start_drag, &start_drag);

    output_mgr = c.wlr_output_manager_v1_create(dpy);
    c.wl_signal_add(&output_mgr.events.apply, &output_mgr_apply);
    // c.wl_signal_add(&output_mgr.events.test, &output_mgr_test);

    relative_pointer_mgr = c.wlr_relative_pointer_manager_v1_create(dpy);
    pointer_constraints = c.wlr_pointer_constraints_v1_create(dpy);
    c.wl_signal_add(&pointer_constraints.events.new_constraint, &new_pointer_constraint);
    c.wl_list_init(&pointer_constraint_commit.link);

    c.wlr_scene_set_presentation(scene, c.wlr_presentation_create(dpy, backend));

    _ = c.wl_global_create(dpy, &c.zdwl_ipc_manager_v2_interface, 1, null, ipc.manager_bind);

    xwayland = c.wlr_xwayland_create(dpy, compositior, true) orelse {
        return error.XWaylandInit;
    };

    c.wl_signal_add(&xwayland.events.ready, &xwayland_ready);
    c.wl_signal_add(&xwayland.events.new_surface, &new_xwayland_surface);

    _ = c.setenv("DISPLAY", xwayland.display_name, 1);
}

pub fn xytomon(x: f64, y: f64) ?*Monitor {
    var o: *c.wlr_output = c.wlr_output_layout_output_at(output_layout, x, y) orelse {
        return null;
    };
    return @ptrCast(?*Monitor, @alignCast(@alignOf(Monitor), o.data));
}

pub fn printstatus() void {
    for (mons) |mon| {
        var occ: u32 = 0;
        var urg: u32 = 0;
        var sel: u32 = 0;

        for (clients.items) |client| {
            if (client.mon != mon) {
                continue;
            }
            occ |= client.tags;
            if (client.isurgent) urg |= client.tags;
        }

        if (focustop(mon)) |client| {
            var title = client_get_title(client) orelse "broken";
            var appid = client_get_appid(client) orelse "broken";

            _ = c.printf("%s title %s\n", mon.output.name, title.ptr);
            _ = c.printf("%s appid %s\n", mon.output.name, appid.ptr);
            _ = c.printf("%s fullscreen %u\n", mon.output.name, client.isfullscreen);
            _ = c.printf("%s floating %u\n", mon.output.name, client.isfloating);

            sel = client.tags;
        } else {
            _ = c.printf("%s title \n", mon.output.name);
            _ = c.printf("%s appid \n", mon.output.name);
            _ = c.printf("%s fullscreen \n", mon.output.name);
            _ = c.printf("%s floating \n", mon.output.name);
            sel = 0;
        }
        _ = c.printf("%s selmon %u\n", mon.output.name, mon == selmon);
        _ = c.printf("%s tags %u %u %u %u\n", mon.output.name, occ, mon.tagset[mon.seltags], sel, urg);
        _ = c.printf("%s layout %s\n", mon.output.name, mon.ltsymbol.*.ptr);
        ipc.output_printstatus(mon);
    }

    _ = c.fflush(c.stdout);
}

pub fn run(startup_cmd: ?[]const u8) !void {
    const socket = c.wl_display_add_socket_auto(dpy) orelse {
        return error.SocketFailed;
    };
    _ = c.setenv("WAYLAND_DISPLAY", socket, 1);
    std.log.info("{s}", .{socket});

    if (!c.wlr_backend_start(backend)) return error.BackendStart;

    if (startup_cmd) |startup| {
        var tmp = [_]i32{ 0, 0 };
        var piperw: []i32 = &tmp;
        if (c.pipe(piperw.ptr) < 0)
            return error.StartupPipe;
        if (c.fork() != 0) {
            _ = c.dup2(piperw[0], c.STDIN_FILENO);
            _ = c.close(piperw[0]);
            _ = c.close(piperw[1]);
            _ = c.execl("/bin/sh", "/bin/sh", "-c", startup.ptr);
            std.c.exit(0);
        }
        _ = c.dup2(piperw[1], c.STDOUT_FILENO);
        _ = c.close(piperw[1]);
        _ = c.close(piperw[0]);
    }

    printstatus();

    for (configData.autoexec) |exec| {
        exec.cmd.run();
    }

    selmon = xytomon(cursor.x, cursor.y);

    c.wlr_cursor_warp_closest(cursor, null, cursor.x, cursor.y);
    c.wlr_xcursor_manager_set_cursor_image(cursor_mgr, cursor_image.?.ptr, cursor);

    c.wl_display_run(dpy);
}

pub fn checkconstraintregion() void {
    const constraint = active_constraint.?.constraint;
    const region = &constraint.region;

    var client: ?*Client = undefined;
    var sx: f64 = 0;
    var sy: f64 = 0;

    _ = toplevel_from_wlr_surface(constraint.surface, &client, null);
    if (active_confine_requires_warp and client != null) {
        active_confine_requires_warp = false;

        sx = cursor.x + @intToFloat(f64, client.?.geom.x);
        sy = cursor.y + @intToFloat(f64, client.?.geom.y);

        if (c.pixman_region32_contains_point(region, @floatToInt(i32, sx), @floatToInt(i32, sy), null) != 0) {
            var nboxes: i32 = 0;
            var boxes = c.pixman_region32_rectangles(region, &nboxes);
            if (nboxes > 0) {
                sx = @intToFloat(f64, @divFloor(boxes[0].x1 + boxes[0].x2, 2));
                sy = @intToFloat(f64, @divFloor(boxes[0].y1 + boxes[0].y2, 2));

                c.wlr_cursor_warp_closest(cursor, null, sx - @intToFloat(f64, client.?.geom.x), sy - @intToFloat(f64, client.?.geom.y));
            }
        }
    }

    if (constraint.type == c.WLR_POINTER_CONSTRAINT_V1_CONFINED) {
        _ = c.pixman_region32_copy(&active_confine, region);
    } else {
        _ = c.pixman_region32_clear(&active_confine);
    }
}

pub fn cleanup() !void {
    if (true) {
        std.debug.assert(gpa.deinit() == .ok);
        std.log.debug("no leaks! :)", .{});
    }

    c.wlr_xwayland_destroy(xwayland);
    c.wl_display_destroy_clients(dpy);
    if (child_pid > 0) {
        _ = std.c.kill(child_pid, 15);
        _ = std.c.waitpid(child_pid, null, 0);
    }
    c.wlr_backend_destroy(backend);
    c.wlr_renderer_destroy(drw);
    c.wlr_allocator_destroy(alloc);
    c.wlr_xcursor_manager_destroy(cursor_mgr);
    c.wlr_cursor_destroy(cursor);
    c.wlr_output_layout_destroy(output_layout);
    c.wlr_seat_destroy(seat);
    c.wl_display_destroy(dpy);
}

pub fn main() !void {
    try setup();
    try run(null);
    try cleanup();
}
