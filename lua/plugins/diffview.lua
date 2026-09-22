-- Diffview integration
--
--   <leader>gl      git log (root dir)          LazyVim default
--     <CR>          full diff of the commit under the cursor  <-- this file
--   <leader>gd      diff of the working tree
--   <leader>gD      file history for the whole repo
--
-- The picker action opens `parent..commit`, i.e. exactly the changes that
-- commit introduced (`<sha>^!` is git rev syntax for that range).
--
-- Notes:
--   * git_log items already carry `item.commit` (abbrev sha) and `item.cwd`
--     (repo root), see snacks/picker/source/git.lua.
--   * `-C` MUST be attached to the path (`-C/path/to/repo`). Diffview parses
--     short flags with `^[-+](%a)=?(.*)`, so `-C /path` would swallow nothing
--     and treat the path as a revision.
--   * `<CR>` is rebound on purpose: in git_log it defaults to `git_checkout`,
--     which puts you in detached HEAD just for inspecting a commit.

local function open_diffview(picker, item)
  if not item or not item.commit then
    return
  end

  -- git_log_file/git_log_line resolve the repo from the file, which is not
  -- necessarily the picker cwd.
  local cwd = item.cwd or picker:cwd()
  local rev = item.commit .. "^!"

  picker:close()

  vim.schedule(function()
    vim.cmd("DiffviewOpen -C" .. vim.fn.fnameescape(cwd) .. " " .. rev)
  end)
end

-- input window accepts insert/normal, the list window is normal mode only
local input_keys = {
  ["<CR>"] = { "open_diffview", mode = { "n", "i" }, desc = "Diffview: commit diff" },
}
local list_keys = {
  ["<CR>"] = { "open_diffview", mode = "n", desc = "Diffview: commit diff" },
}

return {
  {
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diffview Working Tree" },
      { "<leader>gD", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview File History" },
    },
  },

  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        -- global action, reused by the three log sources below
        actions = { open_diffview = open_diffview },
        sources = {
          git_log = { win = { input = { keys = input_keys }, list = { keys = list_keys } } },
          git_log_file = { win = { input = { keys = input_keys }, list = { keys = list_keys } } },
          git_log_line = { win = { input = { keys = input_keys }, list = { keys = list_keys } } },
        },
      },
    },
  },
}
