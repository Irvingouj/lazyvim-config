local function macos_background()
  local out = vim.fn.system({ "defaults", "read", "-g", "AppleInterfaceStyle" })
  if vim.v.shell_error == 0 and out:match("Dark") then
    return "dark"
  end
  return "light"
end

return {
  {
    "maxmx03/solarized.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function(_, opts)
      vim.o.termguicolors = true
      vim.o.background = macos_background()
      require("solarized").setup(opts)
    end,
  },
  {
    "f-person/auto-dark-mode.nvim",
    lazy = false,
    dependencies = { "maxmx03/solarized.nvim" },
    opts = {
      set_dark_mode = function()
        vim.api.nvim_set_option_value("background", "dark", {})
        vim.cmd.colorscheme("solarized")
      end,
      set_light_mode = function()
        vim.api.nvim_set_option_value("background", "light", {})
        vim.cmd.colorscheme("solarized")
      end,
      fallback = "light",
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "solarized",
    },
  },
}
