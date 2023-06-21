const std = @import("std");
const c = @import("c.zig");

pub const Font = struct {
    var isInit: bool = false;

    internFont: [*c]c.fcft_font,
    height: i32,

    pub fn init(name: []const u8) Font {
        if (!isInit) {
            isInit = true;
            _ = c.fcft_init(c.FCFT_LOG_COLORIZE_AUTO, false, c.FCFT_LOG_CLASS_ERROR);
            _ = c.fcft_set_scaling_filter(c.FCFT_SCALING_FILTER_LANCZOS3);
        }
        var faceName = [_][*c]const u8{name.ptr};

        var font = c.fcft_from_name(1, &faceName, null);

        return .{
            .internFont = font,
            .height = font.*.height,
        };
    }

    const UTF8State = enum {
        Accept,
        Reject,
    };

    pub fn sizeText(self: Font, text: []const u8, max_width: u32, padding: u32) u32 {
        std.debug.print("size: {s}", .{text});
        var result = self.drawText(text, 0, 0, null, null, null, null, max_width + 1000000, 0, padding);
        std.debug.print("{}\n", .{result});
        return result;
    }

    pub fn drawText(
        self: Font,
        text: []const u8,
        ax: u32,
        ay: u32,
        fg: ?*c.pixman_image_t,
        bg: ?*c.pixman_image_t,
        fg_color: ?*const c.pixman_color_t,
        bg_color: ?*const c.pixman_color_t,
        max_x: u32,
        buf_height: u32,
        apadding: u32,
    ) u32 {
        var padding = @intCast(i32, apadding);
        var x = @intCast(i32, ax);
        var y = @intCast(i32, ay);
        var ix: i32 = x;
        var nx: i32 = x + padding;
        if (nx + padding >= max_x)
            return @intCast(u32, x);
        x = nx;

        var fg_fill: *c.pixman_image_t = undefined;
        var cur_bg_color: *const c.pixman_color_t = &.{
            .red = 0,
            .green = 0,
            .blue = 0,
            .alpha = 0,
        };

        var draw_fg = (fg != null and fg_color != null);
        var draw_bg = (bg != null and bg_color != null);
        if (draw_fg)
            fg_fill = c.pixman_image_create_solid_fill(fg_color).?;
        if (draw_bg)
            cur_bg_color = bg_color.?;

        var textCopy = text;
        var last_cp: u32 = 0;

        while (textCopy.len != 0) {
            var len = std.unicode.utf8ByteSequenceLength(textCopy[0]) catch 1;

            var codepoint: u32 = std.unicode.utf8Decode(textCopy[0..len]) catch 0;

            textCopy = textCopy[len..];

            const glyph = c.fcft_rasterize_char_utf32(self.internFont, codepoint, c.FCFT_SUBPIXEL_NONE);
            if (glyph == null)
                continue;

            var kern: i64 = 0;
            if (last_cp != 0)
                _ = c.fcft_kerning(self.internFont, last_cp, codepoint, &kern, null);
            nx = @intCast(i32, x + kern + glyph.*.advance.x);
            if (nx + padding > max_x)
                break;
            last_cp = codepoint;
            x += @intCast(i32, kern);

            std.debug.print("glyph: {any}\n", .{glyph.*});

            if (draw_fg) {
                if (c.pixman_image_get_format(glyph.*.pix) == c.PIXMAN_a8r8g8b8) {
                    c.pixman_image_composite32(c.PIXMAN_OP_OVER, glyph.*.pix, fg_fill, fg, 0, 0, 0, 0, x + glyph.*.x, y - glyph.*.y, glyph.*.width, glyph.*.height);
                } else {
                    c.pixman_image_composite32(c.PIXMAN_OP_OVER, fg_fill, glyph.*.pix, fg, 0, 0, 0, 0, x + glyph.*.x, y - glyph.*.y, glyph.*.width, glyph.*.height);
                }
            }

            if (draw_bg) {
                _ = c.pixman_image_fill_boxes(c.PIXMAN_OP_OVER, bg, cur_bg_color, 1, &c.pixman_box32{
                    .x1 = x,
                    .x2 = nx,
                    .y1 = 0,
                    .y2 = @intCast(i32, buf_height),
                });
            }

            x = nx;
        }

        if (draw_fg)
            _ = c.pixman_image_unref(fg_fill);
        if (last_cp == 0)
            return @intCast(u32, ix);

        nx = x + padding;

        if (draw_bg) {
            _ = c.pixman_image_fill_boxes(c.PIXMAN_OP_OVER, bg, bg_color, 1, &c.pixman_box32{
                .x1 = ix,
                .x2 = ix + padding,
                .y1 = 0,
                .y2 = @intCast(i32, buf_height),
            });
            _ = c.pixman_image_fill_boxes(c.PIXMAN_OP_OVER, bg, bg_color, 1, &c.pixman_box32{
                .x1 = x,
                .x2 = nx,
                .y1 = 0,
                .y2 = @intCast(i32, buf_height),
            });
        }

        return @intCast(u32, nx);
    }
};
