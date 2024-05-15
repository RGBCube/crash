{
  lib,
  stdenvNoCC,
  callPackage,

  zig_0_12,
  optimize ? "ReleaseFast",

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

  nativeBuildInputs = [ zig_0_12 ];

  dontConfigure = true;
  dontInstall   = true;

  preBuild = ''
    mkdir -p .cache
    ln -s ${callPackage ./build.zig.zon.nix {}} .cache/p
  '';

  buildPhase = ''
    runHook preBuild

    zig build install \
      --cache-dir $(pwd)/zig-cache \
      --global-cache-dir $(pwd)/.cache \
      --prefix $out \
      -Doptimize=${optimize} \
      -Dfallback_shell=${fallbackShell'}

    runHook postBuild
  '';

  passthru.shellPath = "/bin/crash";

  meta = with lib; {
    description = "A user configurable login shell wrapper";
    homepage    = "https://github.com/RGBCube/crash";
    license     = licenses.mit;
    platforms   = platforms.linux;
    maintainers = with maintainers; [ RGBCube ];
  };
}
