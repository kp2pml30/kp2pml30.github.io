# kp2pml30's blog

Source for kp2pml30's blog: an Astro static site, a Rust backend, and a Ruby generator that renders `.blog.yamd` posts.

## Background

The site is a terminal-flavoured personal blog. Content lives as `.blog.yamd`
files under `frontend/public/fs-tree/` and is rendered to `.blog` HTML by the
Ruby generator (which drives the [`yamd`](https://git.kp2pml30.moe/ya/yamd.git)
CLI). The Rust backend handles dynamic bits (e.g. altcha proof-of-work). Nix
packages every component and provides the dev shell.

## Install

Everything is built with [Nix](https://nixos.org) (flakes enabled):

```sh
nix build .#kp2pml30-moe-frontend   # static site → ./result
nix build .#kp2pml30-moe-backend    # backend binary
```

For development, enter the dev shell (installs git hooks automatically):

```sh
nix develop
```

## Usage

Inside the dev shell:

```sh
# regenerate rendered posts from *.blog.yamd sources
ruby generator/main.rb

# frontend dev server
cd frontend && npm install && npm run dev

# backend
cd backend && cargo run
```

## Contributing

Use the Nix dev shell (`nix develop`) for all tooling; it wires up the
pre-commit hooks. Format and lint before committing:

```sh
nix fmt                              # run the generated pre-commit config
nix flake check                      # run the hooks sandboxed
```

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org).

## License

Code is licensed under [GPL-3.0](LICENSE) © 2026 kp2pml30.

Blog posts and media are licensed under
[CC-BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). See the site's
[licenses page](frontend/src/pages/LICENSES.astro) for the full breakdown,
including third-party components.
