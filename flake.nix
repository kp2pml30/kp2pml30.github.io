{
  description = "kp2pml30's blog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    rust-overlay = {
      url = "github:oxalica/rust-overlay/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    yamd = {
      url = "git+https://git.kp2pml30.moe/ya/yamd.git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.git-hooks.follows = "git-hooks";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = pkgs.lib;

        pre-commit-check = inputs.git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            # Nix
            nixfmt.enable = true;

            # Rust (backend/). The built-in rustfmt hook shells out to
            # `cargo fmt`, which needs a manifest; run rustfmt directly instead.
            rustfmt = {
              enable = true;
              name = "rustfmt";
              description = "Format Rust code.";
              package = pkgs.rustfmt;
              entry = "${pkgs.rustfmt}/bin/rustfmt --edition 2021";
              files = "\\.rs$";
              pass_filenames = true;
            };

            # Shell (the Nix npm setup hooks)
            shfmt.enable = true;

            # TOML (Cargo.toml, rust-toolchain.toml)
            taplo.enable = true;

            # Frontend web source. prettier's default `types = [ "text" ]` is
            # far too broad, so scope to the extensions prettier parses natively.
            # `.astro` needs prettier-plugin-astro (not in nixpkgs) and is left
            # out — format those with the project's own prettier via `npx`.
            # Excluded: generated files (tree.json, lockfiles), verbatim
            # published assets under public/, and vendored/tooling trees.
            prettier = {
              enable = true;
              files = "\\.(css|scss|less|jsx?|mjs|cjs|tsx?|mts|cts|vue|json|jsonc|md|markdown|ya?ml|graphql)$";
              excludes = [
                "^frontend/src/tree\\.json$"
                "(^|/)package-lock\\.json$"
                "^frontend/public/"
                "^\\.claude/"
                "^\\.git-third-party/"
                "/third-party/"
              ];
            };

            # yamd blog documents (*.blog.yamd): rewrite in place; the commit
            # fails if any file changed.
            yamd-fmt = {
              enable = true;
              name = "yamd fmt";
              entry = "${inputs.yamd.packages.${system}.default}/bin/yamd --fmt";
              files = "\\.yamd$";
            };
          };
        };
      in
      {
        packages = {
          kp2pml30-moe-frontend = import ./frontend/release.nix { inherit lib pkgs system; };
          kp2pml30-moe-backend = import ./backend/release.nix { inherit lib pkgs system; };
        };

        checks = {
          inherit pre-commit-check;
        };

        # Run the same generated pre-commit config as `nix flake check`.
        formatter =
          let
            inherit (pre-commit-check.config) package configFile;
          in
          pkgs.writeShellScriptBin "pre-commit-run" ''
            ${lib.getExe package} run --all-files --config ${configFile}
          '';

        devShells.default = pkgs.mkShell {
          inherit (pre-commit-check) shellHook;
          packages =
            (with pkgs; [
              ruby
              rubyPackages.nokogiri
              rubyPackages.builder

              # Racket yamd CLI (generator/main.rb renders .blog.yamd with it).
              inputs.yamd.packages.${system}.default

              rustup

              python312
              pre-commit

              nodejs
              nodePackages.npm
              prefetch-npm-deps
            ])
            ++ pre-commit-check.enabledPackages;
        };
      }
    );
}
