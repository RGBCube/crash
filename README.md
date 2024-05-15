# crash

A user-configurable login shell wrapper.

Crash is a super lightweight shim that executes the shells that are seperated by `:`
in your `SHELLS` environment variable in order, halting execution if one exits
sucessfully (with a 0 exit code).

If you don't have anything in your `SHELLS` environment variable, Crash will
use the fallback shell that is configured at compile time (by default, this is
`bashInteractive` from nixpkgs, however you can change this by overriding the
`fallbackShell` call option).

## Why?

- To allow users to configure their own shells without superuser access.
- To have a fallback shell in case your primary one, which is your login shell,
  breaks and you don't want to get locked out (especially useful when using new
  unstable shells like Nushell).

## Installation

Simply add this repository to your inputs like so:

```nix
{
  inputs.crash = {
    url                    = "github:RGBCube/crash";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

And then you can set the package as your default user
shell like so, in a NixOS module:

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

## Credits

- [noshell](https://github.com/viperML/noshell): This was the primary source of
  inspiration. I decided to create this project as noshell requires a file on disk
  instead of an environment variable and my [feature request for fallback shells got
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
