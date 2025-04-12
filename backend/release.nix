{ lib
, pkgs
, system
, ...
}:
let
	#git-third-party = pkgs.stdenvNoCC.mkDerivation {
	#	name = "git-third-party";
	#	version = "0.0.1";
#
	#	src = builtins.fetchGit {
	#		url = "https://github.com/kp2pml30/git-third-party";
	#		rev = "49cacfdb5e1a4c84b2d66055f492abccf37d11a7";
	#	};
	#	buildInputs = [pkgs.python312 pkgs.git];
#
	#	dontConfigure = true;
	#	dontBuild = true;
#
	#	installPhase = ''
	#		mkdir -p "$out/bin"
	#		cp ./git-third-party "$out/bin"
	#	'';
	#};

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

	rustPkgs = pkgs.rustBuilder.makePackageSet {
		rustVersion = "1.85.1";
		packageFun = import "${base}/Cargo.nix";
	};
in (rustPkgs.workspace.kp2pml30-moe-backend {})
