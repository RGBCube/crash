# crash

A user-configurable login shell wrapper.

Crash is a super lightweight shim that executes the shells that are seperated by
`:` in your `SHELLS` environment variable in order, halting execution if one
exits sucessfully (with a 0 exit code).

If you don't have anything in your `SHELLS` environment variable or all the ones
that did exist failed to launch, Crash will use the fallback shell that is
configured at compile time (by default, this is `bashInteractive` from nixpkgs,
however you can change this by overriding the `fallbackShell` call option).

## Why?

- To allow users to configure their own shells without superuser access (You can
  set the `SHELLS` variable to something like `.config/shell` and let users
  change that file).
- To be able to hotswap between shells when using SSH. This is even more useful
  if multiple people who use the same user account on a machine use different
  shells. See the "Tips & Tricks" section.
- To have a fallback shell in case your primary one, which is your login shell,
  breaks and you don't want to get locked out (especially useful when using new
  unstable shells like Nushell).

## Installation

Simply add this repository to your inputs like so:

```nix
{
  inputs.crash.url = "github:RGBCube/crash";
}
```

And then you can set the package as your default user shell like so, in a NixOS
module:

```nix
{
  outputs = { nixpkgs, crash }: {
    nixosConfigurations.myhostname = nixpkgs.lib.nixosSystem {
      modules = [
        ({ pkgs, lib, ... }: {
          nixpkgs.overlays = [ crash.overlays.default ];

          users.defaultUserShell = pkgs.crash;

          # Here we set our default shells. Nushell will be tried first, if that
          # exits with an error, fish will be launched instead. And if fish fails, the
          # fallback shell, which is pkgs.bashInteractive will get run.
          environment.sessionVariables.SHELLS = "${lib.getExe pkgs.nushell}:${lib.getExe pkgs.fish}";

          # This would also work, as Crash searches $PATH:
          #
          # environment.sessionVariables.SHELLS = "nu:fish";
          #
          # However, just setting an absolute path is pretty easy and better.
        })

        # Uncomment to make the fallback shell of crash pkgs.dash. Will require a recompilation!
        # {
        #   nixpkgs.overlays = [(final: prev: {
        #     crash = prev.crash.override { fallbackShell = final.dash };
        #   })];
        # }
      ];
    };
  }
}
```

## Installation without Nix

First, you have to compile the program (requires Zig 0.14.0):

```shell
zig build --release=safe -Dcpu=baseline -Dfallback_shell=/bin/<yourshell>
```

After that, the binary should be in `zig-out/bin/crash`. You can copy it to
`/bin` like so:

```shell
cp zig-out/bin/crash /bin/
```

After that, you will need to edit PAM settings to set the `SHELLS` environment
variable early on in the boot process. Consult your distros documentation on how
to do this, as it may vary.

## Tips & Tricks

You can control the default shell / program that will get launched by SSH using
Crash. All you need to do it make OpenSSH accept the `SHELLS` environment
variable and set it when SSH'ing in. Here is a NixOS module that does that:

```nix
{
  services.openssh = {
    enable = true;
    settings.AcceptEnv = "SHELLS";
  };
}
```

And you can utilize it by adding this to your `.ssh/config`:

```shell
Host myvps
    # ..snip..
    SetEnv SHELLS=fish:nu:bash:dash
```

Then just SSH in like normal. This will launch you into fish, if that fails,
into nu and so on...

<!-- ## Common Mistakes -->

<!-- ### Using `~` in the `SHELLS` variable -->

<!-- So, the way `SHELLS` is handled is like so: -->
<!-- 1. Split the variable into a list of shells using `:`. -->
<!-- 2. Searches PATH for the shell, invokes it if it can find it there. -->
<!-- 3. If it can't find the shell there, assumes the shell is a file. -->
<!-- If it is an absolute path, it directly invokes the executable, if -->
<!-- it isn'it, joins the path with the current working directory before executing. -->

<!-- Did you notice something? Yup, it doesn't expand the tilde (`~`)! -->
<!-- But no worries, you don't need it anyway as the PWD of your login shell -->
<!-- (in this case, Crash) is always your home directory. So if you wanted to do -->

<!-- ```shell -->
<!-- SHELLS=~/.config/shell # Won't work! -->
<!-- ``` -->

<!-- You can do: -->

<!-- ```shell -->
<!-- SHELLS=.config/shell # WILL work! -->
<!-- ``` -->

<!-- Instead and it will work perfectly fine. -->

## Credits

- [noshell](https://github.com/viperML/noshell): This was the primary source of
  inspiration. I decided to create this project as noshell requires a file on
  disk instead of an environment variable and my
  [feature request for fallback shells got
  rejected](https://github.com/viperML/noshell/issues/6).

## License

```
Copyright (c) 2024-present RGBCube

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
