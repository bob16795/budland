const std = @import("std");
const c = @import("c.zig");
const main = @import("main.zig");

pub const IpcOutput = struct {
    resource: *c.wl_resource,
    monitor: *main.Monitor,
};

pub var ManagerImpl: c.struct_zdwl_ipc_manager_v2_interface = .{
    .release = manager_release,
    .get_output = manager_get_output,
};

pub var OutputImpl: c.struct_zdwl_ipc_output_v2_interface = .{
    .release = output_release,
    .set_tags = output_set_tags,
    .set_layout = output_set_layout,
    .set_client_tags = output_set_client_tags,
};

pub fn manager_bind(client: ?*c.wl_client, _: ?*anyopaque, version: u32, id: u32) callconv(.C) void {
    var manager_resource = c.wl_resource_create(client, &c.zdwl_ipc_manager_v2_interface, @as(i32, @intCast(version)), id);
    if (manager_resource == null) {
        c.wl_client_post_no_memory(client);
        return;
    }

    c.wl_resource_set_implementation(manager_resource, &ManagerImpl, null, manager_destroy);

    c.zdwl_ipc_manager_v2_send_tags(manager_resource, main.tagcount);
    for (main.configData.layouts) |layout| {
        var dup = main.allocator.dupeZ(u8, layout.symbol) catch unreachable;
        defer main.allocator.free(dup);

        c.zdwl_ipc_manager_v2_send_layout(manager_resource, dup.ptr);
    }
}

pub fn manager_destroy(_: [*c]c.wl_resource) callconv(.C) void {
    // No state to destroy
}

pub fn manager_get_output(client: ?*c.wl_client, resource: [*c]c.wl_resource, id: u32, output: [*c]c.wl_resource) callconv(.C) void {
    var monitor: *main.Monitor = @as(*main.Monitor, @ptrCast(@alignCast(@as(*c.wlr_output, @ptrCast(c.wlr_output_from_resource(output))).data)));
    var output_resource = c.wl_resource_create(client, &c.zdwl_ipc_output_v2_interface, c.wl_resource_get_version(resource), id);
    if (output_resource == null) return;

    var ipc_output = main.allocator.create(IpcOutput) catch unreachable;
    ipc_output.resource = output_resource;
    ipc_output.monitor = monitor;
    c.wl_resource_set_implementation(output_resource, &OutputImpl, ipc_output, output_destroy);
    monitor.ipc_outputs = main.allocator.realloc(monitor.ipc_outputs, monitor.ipc_outputs.len + 1) catch unreachable;
    monitor.ipc_outputs[monitor.ipc_outputs.len - 1] = ipc_output;
    output_printstatus_to(ipc_output);
}

pub fn manager_release(_: ?*c.wl_client, resource: [*c]c.wl_resource) callconv(.C) void {
    c.wl_resource_destroy(resource);
}

pub fn output_destroy(resource: [*c]c.wl_resource) callconv(.C) void {
    var ipc_output: *IpcOutput = @as(*IpcOutput, @ptrCast(@alignCast(c.wl_resource_get_user_data(resource) orelse return)));
    for (main.mons) |mon| {
        if (std.mem.indexOf(*IpcOutput, mon.ipc_outputs, &.{ipc_output})) |idx| {
            @memcpy(mon.ipc_outputs[idx .. mon.ipc_outputs.len - 1], mon.ipc_outputs[idx + 1 ..]);
            mon.ipc_outputs = main.allocator.realloc(mon.ipc_outputs, mon.ipc_outputs.len - 1) catch unreachable;
            main.allocator.destroy(ipc_output);
            return;
        }
    }
}

pub fn output_printstatus(monitor: *main.Monitor) callconv(.C) void {
    for (monitor.ipc_outputs) |output| {
        output_printstatus_to(output);
    }
}

pub fn output_printstatus_to(ipc_output: *IpcOutput) callconv(.C) void {
    const monitor = ipc_output.monitor;
    const focused = main.focustop(monitor);
    c.zdwl_ipc_output_v2_send_active(ipc_output.resource, if (monitor == main.selmon) 1 else 0);

    for (0..main.tagcount) |tag| {
        var state: u32 = 0;
        var focused_client: u32 = 0;
        var numclients: u32 = 0;

        var tagmask = std.math.pow(u32, 2, @as(u32, @intCast(tag)));
        if ((tagmask & monitor.tagset[monitor.seltags]) != 0) {
            state |= c.ZDWL_IPC_OUTPUT_V2_TAG_STATE_ACTIVE;
        }
        for (main.clients.items) |client| {
            if (client.mon != monitor) continue;
            if ((client.tags & tagmask) == 0) continue;
            if (client == focused) focused_client = 1;
            if (client.isurgent) state |= c.ZDWL_IPC_OUTPUT_V2_TAG_STATE_URGENT;
            numclients += 1;
        }
        c.zdwl_ipc_output_v2_send_tag(ipc_output.resource, @as(u32, @intCast(tag)), state, numclients, focused_client);
    }
    var title = if (focused) |f| main.client_get_title(f) orelse "???" else "Desktop";
    var appid = if (focused) |f| main.client_get_appid(f) orelse "???" else "Desktop";
    c.zdwl_ipc_output_v2_send_layout(ipc_output.resource, monitor.sellt);
    c.zdwl_ipc_output_v2_send_title(ipc_output.resource, title.ptr);
    c.zdwl_ipc_output_v2_send_appid(ipc_output.resource, appid.ptr);

    var symbol = main.allocator.dupeZ(u8, monitor.ltsymbol.*) catch unreachable;
    defer main.allocator.free(symbol);
    c.zdwl_ipc_output_v2_send_layout_symbol(ipc_output.resource, symbol);
    c.zdwl_ipc_output_v2_send_frame(ipc_output.resource);
}

pub fn output_set_client_tags(_: ?*c.wl_client, resource: [*c]c.wl_resource, and_tags: u32, xor_tags: u32) callconv(.C) void {
    var ipc_output: *IpcOutput = @as(*IpcOutput, @ptrCast(@alignCast(c.wl_resource_get_user_data(resource) orelse return)));
    var monitor = ipc_output.monitor;

    var newtags: u32 = 0;
    var sclient = main.focustop(monitor);
    if (sclient == null) return;
    newtags = (sclient.?.tags & and_tags) ^ xor_tags;

    if (newtags == 0)
        return;

    sclient.?.tags = newtags;
    main.focusclient(main.focustop(main.selmon), true);
    if (main.selmon) |selmon|
        main.arrange(selmon);
    main.printstatus();
}

pub fn output_set_layout(_: ?*c.wl_client, resource: [*c]c.wl_resource, layout: u32) callconv(.C) void {
    var ipc_output: *IpcOutput = @as(*IpcOutput, @ptrCast(@alignCast(c.wl_resource_get_user_data(resource) orelse return)));
    var monitor = ipc_output.monitor;

    if (layout > main.configData.layouts.len)
        return;
    if (layout != monitor.sellt)
        monitor.sellt ^= 1;

    monitor.lt[monitor.sellt] = layout;
    if (main.selmon) |selmon|
        main.arrange(selmon);
    main.printstatus();
}

pub fn output_set_tags(_: ?*c.wl_client, resource: [*c]c.wl_resource, and_tags: u32, xor_tags: u32) callconv(.C) void {
    var ipc_output: *IpcOutput = @as(*IpcOutput, @ptrCast(@alignCast(c.wl_resource_get_user_data(resource) orelse return)));
    var monitor = ipc_output.monitor;

    var newtags: u32 = 0;
    newtags = (monitor.tagset[monitor.seltags] & and_tags) ^ xor_tags;

    if (newtags == 0)
        return;

    monitor.tagset[monitor.seltags] = newtags;
    main.focusclient(main.focustop(main.selmon), true);
    if (main.selmon) |selmon|
        main.arrange(selmon);
    main.printstatus();
}

pub fn output_release(_: ?*c.wl_client, resource: [*c]c.wl_resource) callconv(.C) void {
    c.wl_resource_destroy(resource);
}
