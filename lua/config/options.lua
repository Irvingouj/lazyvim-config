-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.cursorline = false
vim.opt.cursorcolumn = false
vim.opt.relativenumber = false

-- Disable swapfile and backup files
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Enable autoread (reload file when changed externally)
vim.opt.autoread = true

-- Add Mason's bin directory to PATH so LSP servers can be found
vim.env.PATH = vim.env.PATH .. ":" .. vim.fn.stdpath("data") .. "/mason/bin"

-- blink.cmp v2 (its `main` branch) requires Neovim 0.12+.
-- On 0.11.x we let LazyVim use the latest release (v1.x) instead;
-- this flips back to `main` automatically once Neovim is upgraded.
if vim.fn.has("nvim-0.12") == 1 then
  vim.g.lazyvim_blink_main = true
end
