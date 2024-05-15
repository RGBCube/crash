const std = @import("std");
const fallback_shell = @import("build_options").fallback_shell orelse @compileError("fallback shell was not specified");

pub fn fallback(alloc: std.mem.Allocator) noreturn {
    const err = std.process.execv(alloc, &[_][]const u8{fallback_shell});
    std.process.exit(@intCast(@intFromError(err)));
}

pub fn main() noreturn {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    const shells = std.posix.getenv("SHELLS") orelse fallback(alloc);

    var it = std.mem.split(u8, shells, ":");
    while (it.next()) |shell| {
        var child = std.process.Child.init(&[_][]const u8{shell}, alloc);

        switch (child.spawnAndWait() catch fallback(alloc)) {
            std.process.Child.Term.Exited => |exit_code| if (exit_code == 0) std.process.exit(0),
            else => continue,
        }
    }

    fallback(alloc);
}
