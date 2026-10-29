-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Markdown is edited as plain text, so undo LazyVim's hidden markup, spell check and soft wrap
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 0
    vim.opt_local.spell = false
    vim.opt_local.wrap = false
  end,
})

-- zellij never tells nvim when you switch panes, so LazyVim's FocusGained reload never runs
-- and files edited by an AI in another pane go stale. Poll instead.
local checktime_timer = vim.uv.new_timer()
checktime_timer:start(
  1000,
  1000,
  vim.schedule_wrap(function()
    if vim.fn.mode() ~= "c" and vim.fn.getcmdwintype() == "" then
      vim.cmd("silent! checktime")
    end
  end)
)
