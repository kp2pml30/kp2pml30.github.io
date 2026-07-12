{
  lib,
  pkgs,
  system,
  generator,
  ...
}:
let
  npmBuildHook = pkgs.makeSetupHook {
    name = "website-build-hook";
  } ./nix/npm-build-hook.sh;

  npmInstallHook = pkgs.makeSetupHook {
    name = "website-setup-hook";
  } ./nix/npm-install-hook.sh;
in
pkgs.buildNpmPackage {
  pname = "kp2pml30-website";
  version = "0.0.1";

  inherit npmBuildHook npmInstallHook;

  nativeBuildInputs = with pkgs; [
    bundler
    generator
  ];

  src = ./.;

  npmDepsHash = "sha256-VNqZ3DuWVK1cxFnqJpPlGlCjhKLGY4cpo07Xcb3+Saw=";
}
