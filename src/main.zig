const std = @import("std");
const fallback_shell = @import("build_options").fallback_shell orelse @compileError("fallback shell was not specified");

pub fn fallback(alloc: std.mem.Allocator) noreturn {
    const err = std.process.execv(alloc, &[_][]const u8{fallback_shell});
    std.process.exit(@intCast(@intFromError(err)));
}

pub fn main() noreturn {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var args = alloc.alloc([]const u8, std.os.argv.len) catch fallback(alloc);
    defer alloc.free(args);
    args.len = 0;

    var argi = std.process.args();
    while (argi.next()) |arg| {
        args[args.len] = arg;
        args.len += 1;
    }

    const shells = std.posix.getenv("SHELLS") orelse fallback(alloc);

    var it = std.mem.split(u8, shells, ":");
    while (it.next()) |shell| {
        args[0] = shell;
        var child = std.process.Child.init(args, alloc);

        switch (child.spawnAndWait() catch fallback(alloc)) {
            std.process.Child.Term.Exited => |exit_code| if (exit_code == 0) std.process.exit(0),
            else => continue,
        }
    }

    fallback(alloc);
}
