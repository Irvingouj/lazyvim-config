return {
  {
    "folke/snacks.nvim",
    opts = {
      terminal = {
        shell = vim.fn.executable("nu") == 1 and "nu" or nil,
      },
    },
  },
}
