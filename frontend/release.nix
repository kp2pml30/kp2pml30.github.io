{ lib
, pkgs
, system
, ...
}:
let
	npmBuildHook = pkgs.makeSetupHook {
		name = "website-build-hook";
	} ./nix/npm-build-hook.sh;

	npmInstallHook = pkgs.makeSetupHook {
		name = "website-setup-hook";
	} ./nix/npm-install-hook.sh;
in pkgs.buildNpmPackage {
		pname = "kp2pml30-website";
		version = "0.0.1";

		inherit npmBuildHook npmInstallHook;

		nativeBuildInputs = with pkgs; [
			bundler
		];

		src = ./.;

		npmDepsHash = "sha256-DHk6Yesb250cAjKeH4RG+wbNRGlZW6kSOTx3v8o/Vxc=";
}
