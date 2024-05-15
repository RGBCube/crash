{
  lib,
  stdenvNoCC,

  zig_0_12,

  bashInteractive,
  fallbackShell ? bashInteractive,
}: let
  fallbackShell' = if lib.isDerivation fallbackShell then
    "${fallbackShell}${fallbackShell.shellPath}"
  else
    fallbackShell;
in stdenvNoCC.mkDerivation {
  name    = "crash";
  version = lib.head (lib.strings.match ''.*\.version = "([^"]*)".*'' (lib.readFile ./build.zig.zon));

  src = ./.;

  dontCheck = true;

  nativeBuildInputs = [
    zig_0_12.hook
  ];

  zigBuildFlags = [
    "-Dfallback_shell=${fallbackShell'}"
  ];

  passthru.shellPath = "/bin/crash";

  meta = with lib; {
    description = "A user configurable login shell wrapper";
    homepage    = "https://github.com/RGBCube/crash";
    license     = licenses.mit;
    platforms   = platforms.linux;
    maintainers = with maintainers; [ RGBCube ];
  };
}
