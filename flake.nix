{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
		rust-overlay.url = "github:oxalica/rust-overlay/stable";
		systems = {
			url = "github:nix-systems/default";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		flake-utils = {
			url = "github:numtide/flake-utils";
			inputs.systems.follows = "systems";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
		flake-utils.lib.eachDefaultSystem
			(system:
				let
					pkgs = import nixpkgs { inherit system; };
					lib = pkgs.lib;
				in
				{
					packages = {
						kp2pml30-moe-frontend = import ./frontend/release.nix { inherit lib pkgs system; };
						kp2pml30-moe-backend = import ./backend/release.nix { inherit lib pkgs system; };
					};

					devShells.default =
						let pkgs = import nixpkgs {
							inherit system;
							config.allowUnfree = true;
						};
					in pkgs.mkShell {
						packages = with pkgs; [
							ruby

							rustup

							python312
							pre-commit

							nodejs
							nodePackages.npm

							vscode
						];

						shellHook = ''
							alias_dir="$PWD/.direnv/aliases"
							mkdir -p "$alias_dir"
							PATH_add "$alias_dir"
							target="$alias_dir/code"
							CODE_ORIGINAL="$(which code)"
							echo "#!/usr/bin/env bash" > "$target"
							echo "'${toString pkgs.vscode}/bin/code' '--extensions-dir=$PWD/.direnv/vscode-exts'" '"$@"' >> "$target"
							chmod +x "$target"
						'';
					};
				}
			);
}
