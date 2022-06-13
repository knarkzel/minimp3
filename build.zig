const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("minimp3", "src/main.zig");
    lib.addIncludeDir("vendor");
    lib.addCSourceFile("vendor/minimp3.c", &.{});
    lib.linkLibC();
    lib.setTarget(target);
    lib.setBuildMode(mode);
    lib.install();

    const main_tests = b.addTest("src/main.zig");
    main_tests.addIncludeDir("vendor");
    main_tests.addCSourceFile("vendor/minimp3.c", &.{});
    main_tests.linkLibC();
    main_tests.setTarget(target);
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
