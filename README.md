# kp2pml30's blog

Source for [kp2pml30.moe](https://kp2pml30.moe) — an Astro static site with a Rust
backend and a Python generator that renders posts written in
[yamd](https://git.kp2pml30.moe/ya/yamd.git).

## Hello world

A post is a `.blog.yamd` file under `frontend/public/fs-tree/`:

```yamd
#use(std/html)
#use(meta)
#meta(created: "2026 07 13" edited: "2026 07 13" tags: '("hello"))

#section{Hello, world}::

My first post.
```

Build with [Nix](https://nixos.org) (flakes): `nix build .#kp2pml30-moe-frontend`
outputs the static site to `./result`. Inside `nix develop`, run
`kp2pml30-moe-generator` to re-render posts.

## Docs

- Writing posts: the [yamd language docs](https://kp2pml30.moe/view/kp2pml30/projects/yamd/lang.html).
- Dev, backend, frontend server, formatting: `nix develop` wires up all tooling
  and the pre-commit hooks (`nix fmt`, `nix flake check`).

## License

Code: [GPL-3.0](LICENSE) © 2026 kp2pml30. Posts and media:
[CC-BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/); see the
[licenses page](frontend/src/pages/LICENSES.astro) for the full breakdown.
