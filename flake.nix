{
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
		rust-overlay.url = "github:oxalica/rust-overlay/stable";
		cargo2nix = {
			url = "github:cargo2nix/cargo2nix/f7b2c744b1e6ee39c7b4528ea34f06db598266a6";
			inputs.nixpkgs.follows = "nixpkgs";
			inputs.rust-overlay.follows = "rust-overlay";
		};
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

	outputs = inputs@{ self, nixpkgs, flake-utils, cargo2nix, ... }:
		flake-utils.lib.eachDefaultSystem
			(system:
				let
					pkgs = import nixpkgs { inherit system; overlays = [cargo2nix.overlays.default]; };
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
							overlays = [cargo2nix.overlays.default];
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
							cargo2nix.packages.${system}.cargo2nix
						];

						shellHook = ''
							alias_dir="$PWD/.direnv/aliases"
							mkdir -p "$alias_dir"
							PATH_add "$alias_dir"
							target="$alias_dir/code"
							CODE_ORIGINAL="$(which code)"
							echo "#!/usr/bin/env bash" > "$target"
							echo "'${toString pkgs.vscode}/bin/code' '--extensions-dir=$PWD/.direnv/vscode-exts'" >> "$target"
							chmod +x "$target"
						'';
					};
				}
			);
}
