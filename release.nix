{ lib
, pkgs
, ...
}:
let
	npmBuildHook = pkgs.makeSetupHook {
		name = "website-build-hook";
	} ./npm-build-hook.sh;

	npmInstallHook = pkgs.makeSetupHook {
		name = "website-setup-hook";
	} ./npm-install-hook.sh;
in pkgs.buildNpmPackage {
	pname = "kp2pml30-website";
	version = "0.0.1";

	inherit npmBuildHook npmInstallHook;

	src = ./.;

	npmDepsHash = "sha256-mIFp1nmQsHVRTuE77wLDyOONSSfOdcrXq5bH7ukxORU=";
}
