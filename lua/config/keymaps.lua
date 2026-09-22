-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>cy", function()
  local diagnostics = vim.diagnostic.get(0, { lnum = vim.api.nvim_win_get_cursor(0)[1] - 1 })

  if #diagnostics == 0 then
    vim.notify("No diagnostic under cursor")
    return
  end

  local messages = vim.tbl_map(function(d)
    return d.message
  end, diagnostics)

  vim.fn.setreg("+", table.concat(messages, "\n"))
  vim.notify("Diagnostic copied")
end, { desc = "Copy Diagnostic" })
