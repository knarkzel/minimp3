const std = @import("std");
const c = @cImport(@cInclude("minimp3.h"));

const Info = extern struct {
    frame_bytes: i32,
    frame_offset: i32,
    channels: i32,
    hz: i32,
    layer: i32,
    bitrate_kbps: i32,
};

const Layer = enum { layer1, mpeg2layer3, otherwise };

const Frame = struct {
    info: Info,
    layer: Layer,
    pcm: *[c.MINIMP3_MAX_SAMPLES_PER_FRAME]i16,
};

const Decoder = @This();
buffer: [*c]const u8,
len: i32,
mp3d: c.mp3dec_t,
info: c.mp3dec_frame_info_t = undefined,
pcm: [c.MINIMP3_MAX_SAMPLES_PER_FRAME]i16 = undefined,

pub fn init(buffer: []const u8) Decoder {
    var mp3d: c.mp3dec_t = undefined;
    c.mp3dec_init(&mp3d);
    return .{ .buffer = @ptrCast([*c]const u8, buffer.ptr), .len = @intCast(c_int, buffer.len), .mp3d = mp3d };
}

pub fn next(self: *Decoder) ?Frame {
    const samples = c.mp3dec_decode_frame(&self.mp3d, self.buffer, self.len, &self.pcm, &self.info);
    if (samples == 0) return null else {
        const layer: Layer = switch (samples) {
            384 => .layer1,
            576 => .mpeg2layer3,
            1152 => .otherwise,
            else => return null,
        };
        return Frame{ .info = @bitCast(Info, self.info), .layer = layer, .pcm = &self.pcm };
    }
}

test "manual" {
    const buffer = @embedFile("drums.mp3");
    var mp3d: c.mp3dec_t = undefined;
    c.mp3dec_init(&mp3d);
    var info: c.mp3dec_frame_info_t = undefined;
    var pcm: [c.MINIMP3_MAX_SAMPLES_PER_FRAME]i16 = undefined;
    _ = c.mp3dec_decode_frame(&mp3d, buffer, buffer.len, &pcm, &info);
}

test "drums.mp3" {
    const buffer = @embedFile("drums.mp3");
    var decoder = Decoder.init(buffer);
    if (decoder.next()) |frame| {
        for (frame.pcm[0..1000]) |pcm| std.log.warn("{d}", .{pcm});
    }
}
