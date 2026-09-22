# LazyVim config

My personal [LazyVim](https://github.com/LazyVim/LazyVim) setup: TypeScript/Vue, Go, Rust, Java,
Swift/Objective-C (Xcode), JSON/Tailwind/Prisma, DAP debugging, DeepSeek AI completion, PDF reading
in the buffer, and a Diffview integration wired into the Snacks git-log picker.

## Requirements

- Neovim >= 0.11 (0.12+ is detected and switches `blink.cmp` to its `main` branch)
- `git`, `ripgrep`, `fd`, a C compiler, `make`
- optional: `lazygit` (`<leader>gg`), `pdftotext` (PDFview), Xcode (the `swift`/`objc` bits)

## Install

```sh
# keep the old one around if it exists
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null

git clone git@github.com:Irvingouj/lazyvim-config.git ~/.config/nvim
nvim
```

`lazy-lock.json` is committed, so plugin versions are pinned to a known-good state.
Lazy installs everything on first launch. To update later: `:Lazy update` + `:Lazy sync`.

Want to try it without touching your current config? Clone it under a different `NVIM_APPNAME`:

```sh
git clone git@github.com:Irvingouj/lazyvim-config.git ~/.config/lazyvim-test
NVIM_APPNAME=lazyvim-test nvim
```

## Structure

```
init.lua                  -> require("config.lazy")
lazy-lock.json            -> pinned plugin versions
lazyvim.json
stylua.toml
.neoconf.json             -> lua_ls knows about lazy.nvim/LazyVim plugins
lua/config/lazy.lua       -> lazy.nvim bootstrap + LazyVim extras list
lua/config/options.lua    -> no swapfile/backup, autoread, relativenumber off, ...
lua/config/keymaps.lua    -> <leader>cy copy diagnostic
lua/config/autocmds.lua   -> (empty, LazyVim defaults)
lua/plugins/*.lua         -> plugin specs
```

LazyVim extras are imported in `lua/config/lazy.lua` (that is why `lazyvim.json` shows none):
`lang.java`, `lang.rust`, `lang.go`, `lang.typescript`, `lang.vue`, `lang.json`, `lang.tailwind`,
`lang.prisma`, `dap.core`, `dap.nlua`.

## Git workflow

| Keys | Action |
| --- | --- |
| `<leader>gl` | git log for the repo root (Snacks picker) |
| `<CR>` | **in the log picker**: open Diffview for the changes that commit introduced |
| `<leader>gd` | Diffview: working tree |
| `<leader>gD` | Diffview: file history for the whole repo |
| `<leader>gf` / `<leader>gb` | current file history / blame line |
| `<leader>gg` | lazygit |

Inside Diffview: `<Tab>` / `<S-Tab>` next / previous file, `]c` / `[c` next / previous hunk,
`:DiffviewClose` to leave. `<CR>` is remapped in `git_log` on purpose — its default action is
`git_checkout`, which drops you into detached HEAD just for inspecting a commit. The commit diff is
opened as `<sha>^!` (`parent..commit`); if you want the old checkout behaviour back, add
`["<C-X>"] = "git_checkout"` to the key tables in `lua/plugins/diffview.lua`.

## Plugins / tweaks worth knowing

- **`lua/plugins/diffview.lua`** — `sindrets/diffview.nvim` + the Snacks action described above.
- **`lua/plugins/minuet.lua`** — inline AI completion via `minuet-ai.nvim`, provider DeepSeek.
  The API key is never in the repo: it is read from `$DEEPSEEK_API_KEY`, falling back to sourcing
  `~/rc.deepseek.rc`. Autocomplete is bound to `<A-y>`, does not run automatically.
- **`lua/plugins/pdfview.lua`** — reading `.pdf` files straight into a buffer (text via `pdftotext`),
  `<leader>fp` to pick one, `]p` / `[p` to page, and the snacks explorer confirm action opens PDFs
  in the buffer instead of an external viewer.
- **`lua/plugins/lang.lua`** — Java: jdtls with Lombok, pinned to Homebrew's `openjdk@21` (bails out
  gracefully if either is missing). Rust: rustaceanvim, `clippy` on save, inline type/param/chaining
  hints. rustaceanvim is pinned to `^8` on Neovim 0.11 because v9+ needs 0.12; the pin clears
  itself once Neovim is upgraded.
- **`lua/plugins/lsp-config.lua`** — Swift/ObjC via `xcrun sourcekit-lsp` (started directly from
  Xcode, not Mason, with `*.xcodeproj`/`Package.swift`/`buildServer.json` root detection), marksman
  disabled, tailwind/css/html/json servers, plus `xcodebuild.nvim` for
  `<leader>xb` build, `<leader>xr` build & run, `<leader>xt` test.
- **`lua/plugins/colorscheme.lua`** — solarized, following the macOS light/dark appearance
  (`auto-dark-mode.nvim`).
- `lua/plugins/example.lua` — untouched LazyVim starter example, returns `{}`; safe to delete.

## Keymap added on top of LazyVim

| Keys | Action |
| --- | --- |
| `<leader>cy` | copy the LSP diagnostic under the cursor to the system clipboard |
