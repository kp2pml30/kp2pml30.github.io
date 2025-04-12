{ lib
, pkgs
, system
, ...
}:
let
	altcha-lib-rs = pkgs.stdenvNoCC.mkDerivation {
		name = "altcha-lib-rs";
		version = "0.0.1";

		src = builtins.fetchGit {
			url = "https://github.com/jmic/altcha-lib-rs";
			rev = "62b458dfd653b3d193ad18c412a0a4998712eb94";
		};

		dontConfigure = true;
		dontBuild = true;

		patches = [
			../.git-third-party/patches/backend/third-party/altcha-lib-rs/1
			../.git-third-party/patches/backend/third-party/altcha-lib-rs/2
		];

		installPhase = ''
			mkdir -p "$out"
			cp -r ./* "$out"
		'';
	};

	base = pkgs.stdenvNoCC.mkDerivation {
		name = "kp2pml30-moe-backend-src";
		version = "0.0.1";
		src = ./.;

		dontConfigure = true;

		nativeBuildInputs = [
			pkgs.git
			altcha-lib-rs
		];

		buildPhase = ''
			cp -r "${altcha-lib-rs}" third-party/altcha-lib-rs
		'';

		installPhase = ''
			mkdir -p "$out"
			cp -r ./* "$out"
		'';
	};
in pkgs.rustPlatform.buildRustPackage {
	pname = "kp2pml30-moe-backend";
	version = "0.0.1";
	cargoLock.lockFile = ./Cargo.lock;
	src = base;
}
