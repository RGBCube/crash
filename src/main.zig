const std = @import("std");
const fallback_shell = @import("build_options").fallback_shell orelse @compileError("fallback shell was not specified");

pub fn fallback(alloc: std.mem.Allocator, args: []const []const u8) noreturn {
    const err = std.process.execv(alloc, args);
    std.process.exit(@intCast(@intFromError(err)));
}

pub fn main() noreturn {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();

    var args = alloc.alloc([]const u8, std.os.argv.len) catch fallback(alloc, &[_][]const u8{fallback_shell});
    defer alloc.free(args);
    args.len = 0;

    var argi = std.process.args();
    while (argi.next()) |arg| {
        defer args.len += 1;
        args[args.len] = arg;
    }

    const shells = std.posix.getenv("SHELLS") orelse fallback(alloc, args: {
        args[0] = fallback_shell;
        break :args args;
    });

    var it = std.mem.splitScalar(u8, shells, ':');
    while (it.next()) |shell| {
        args[0] = shell;
        var child = std.process.Child.init(args, alloc);

        switch (child.spawnAndWait() catch fallback(alloc, args: {
            args[0] = fallback_shell;
            break :args args;
        })) {
            std.process.Child.Term.Exited => |exit_code| if (exit_code == 0) std.process.exit(0),
            else => continue,
        }
    }

    fallback(alloc, args: {
        args[0] = fallback_shell;
        break :args args;
    });
}
