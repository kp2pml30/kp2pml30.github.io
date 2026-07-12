{
  description = "kp2pml30's blog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    git-third-party = {
      url = "github:kp2pml30/git-third-party";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.systems.follows = "systems";
    };
    yamd = {
      url = "git+https://git.kp2pml30.moe/ya/yamd.git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.git-hooks.follows = "git-hooks";
      inputs.flake-utils.follows = "flake-utils";
      inputs.systems.follows = "systems";
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

        # prettier + prettier-plugin-astro, built from the vendored lockfile in
        # ./nix/prettier so `.astro` formats hermetically (the plugin is not in
        # nixpkgs). Ships its own prettier, version-matched to the plugin; use
        # it as the binary so every web file formats with one prettier.
        prettierAstro = pkgs.buildNpmPackage {
          pname = "prettier-plugin-astro-bundle";
          version = "0.14.1";
          src = ./nix/prettier;
          npmDepsHash = "sha256-U6fYzjYT0QP4KQN/Yb6hCvN20SoPfpMF7napvxElLlg=";
          dontNpmBuild = true;
        };
        prettierAstroModules = "${prettierAstro}/lib/node_modules/prettier-astro-plugin/node_modules";
        generatorPython = pkgs.python312.withPackages (pythonPackages: [
          pythonPackages.wordcloud
        ]);
        generator = pkgs.writeShellApplication {
          name = "kp2pml30-moe-generator";
          runtimeInputs = [
            generatorPython
            inputs.yamd.packages.${system}.default
          ];
          text = ''
            export KP2PML30_SITE_ROOT="''${KP2PML30_SITE_ROOT:-$PWD}"
            exec ${generatorPython}/bin/python3 ${./generator/main.py} "$@"
          '';
        };

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

            # Python
            ruff.enable = true;
            ruff-format.enable = true;

            # Frontend web source, incl. `.astro` (via the bundled plugin
            # above). prettier's default `types = [ "text" ]` is far too broad,
            # so scope to the extensions it parses. Excluded: generated files
            # (tree.json, lockfiles), verbatim published assets under public/,
            # and vendored/tooling trees.
            prettier = {
              enable = true;
              files = "\\.(astro|css|scss|less|jsx?|mjs|cjs|tsx?|mts|cts|vue|json|jsonc|md|markdown|ya?ml|graphql)$";
              excludes = [
                "^frontend/src/tree\\.json$"
                "(^|/)package-lock\\.json$"
                "^frontend/public/"
                "^\\.claude/"
                "^\\.git-third-party/"
                "/third-party/"
              ];
              settings = {
                binPath = "${prettierAstroModules}/.bin/prettier";
                plugins = [ "${prettierAstroModules}/prettier-plugin-astro/dist/index.js" ];
              };
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
          kp2pml30-moe-generator = generator;
          kp2pml30-moe-frontend = import ./frontend/release.nix {
            inherit
              generator
              lib
              pkgs
              system
              ;
          };
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
              generator

              rustup

              generatorPython
              pre-commit

              nodejs
              nodejs
              prefetch-npm-deps
            ])
            ++ pre-commit-check.enabledPackages;
        };
      }
    );
}
