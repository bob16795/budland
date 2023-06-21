const std = @import("std");
const c = @import("c.zig");
const allocator = @import("main.zig").allocator;

pub const DataBuffer = struct {
    base: c.wlr_buffer,

    data: [*c]u8,
    cairo: ?*c.cairo_t,
    format: u32,
    stride: usize,
    free_on_destroy: bool,
    unscaled_width: u32,
    unscaled_height: u32,
};

pub fn data_buffer_from_buffer(buffer: [*c]c.wlr_buffer) *DataBuffer {
    return @ptrCast(*DataBuffer, @alignCast(@alignOf(DataBuffer), buffer));
}

pub fn data_buffer_destroy(wlr_buffer: [*c]c.wlr_buffer) callconv(.C) void {
    var buffer = data_buffer_from_buffer(wlr_buffer);
    if (!buffer.free_on_destroy) {
        allocator.destroy(buffer);
        return;
    }
    if (buffer.cairo != null) {
        var surf = c.cairo_get_target(buffer.cairo);
        c.cairo_destroy(buffer.cairo);
        c.cairo_surface_destroy(surf);
    } else if (buffer.data != null) {
        buffer.data = null;
    }
    allocator.destroy(buffer);
}

pub fn data_buffer_begin_data_ptr_access(wlr_buffer: [*c]c.wlr_buffer, _: u32, data: [*c]?*anyopaque, format: [*c]u32, stride: [*c]usize) callconv(.C) bool {
    var buffer: *DataBuffer = undefined;
    buffer = c.wl_container_of(wlr_buffer, buffer, "base");
    if (buffer.data == null) @panic("data for buffer is null");

    data.* = buffer.data;
    format.* = buffer.format;
    stride.* = buffer.stride;

    return true;
}

pub fn data_buffer_end_data_ptr_access(_: [*c]c.wlr_buffer) callconv(.C) void {
    // NO-OP
}

const DataBufferImpl: c.wlr_buffer_impl = .{
    .destroy = data_buffer_destroy,
    .begin_data_ptr_access = data_buffer_begin_data_ptr_access,
    .end_data_ptr_access = data_buffer_end_data_ptr_access,
    .get_dmabuf = null,
    .get_shm = null,
};

pub fn buffer_create_wrap(pixel_data: [*c]u8, width: u32, height: u32, stride: u32, free_on_destroy: bool) *DataBuffer {
    var buffer = allocator.create(DataBuffer) catch unreachable;
    c.wlr_buffer_init(&buffer.base, &DataBufferImpl, @intCast(i32, width), @intCast(i32, height));
    buffer.data = pixel_data;
    buffer.format = c.DRM_FORMAT_ARGB8888;
    buffer.stride = stride;
    buffer.free_on_destroy = free_on_destroy;
    return buffer;
}

pub fn buffer_create_cairo(width: u32, height: u32, scale: f32, free_on_destroy: bool) *DataBuffer {
    var buffer = allocator.create(DataBuffer) catch unreachable;
    buffer.unscaled_width = width;
    buffer.unscaled_height = height;
    var nwidth = @floatToInt(u32, scale * @intToFloat(f32, width));
    var nheight = @floatToInt(u32, scale * @intToFloat(f32, height));

    c.wlr_buffer_init(&buffer.base, &DataBufferImpl, @intCast(i32, nwidth), @intCast(i32, nheight));
    var surface = c.cairo_image_surface_create(c.CAIRO_FORMAT_ARGB32, @intCast(i32, nwidth), @intCast(i32, nheight));

    c.cairo_surface_set_device_scale(surface, scale, scale);

    buffer.cairo = c.cairo_create(surface);
    buffer.data = c.cairo_image_surface_get_data(surface);
    buffer.format = c.DRM_FORMAT_ARGB8888;
    buffer.stride = @intCast(usize, c.cairo_image_surface_get_stride(surface));
    buffer.free_on_destroy = free_on_destroy;
    if (buffer.data == null) {
        @panic("sad");
    }

    return buffer;
}
