-- Live macOS appearance via SkyLight (not the cached AppleInterfaceStyle pref);
-- elsewhere fall back to auto-dark-mode.nvim (registry on Windows).
local appearance_bin = vim.fn.expand("~/.config/alacritty/macos-appearance")
local live_appearance = vim.fn.has("mac") == 1 and vim.fn.executable(appearance_bin) == 1

local function macos_background()
  if not live_appearance then
    return "light"
  end
  local out = vim.fn.system({ appearance_bin })
  if vim.v.shell_error == 0 and tostring(out):match("dark") then
    return "dark"
  end
  return "light"
end

local function apply_solarized(bg)
  if vim.o.background == bg and vim.g.colors_name == "solarized" then
    return
  end
  vim.o.background = bg
  vim.cmd.colorscheme("solarized")
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
      vim.cmd.colorscheme("solarized")

      if not live_appearance or not vim.uv then
        return
      end

      local busy = false
      local timer = vim.uv.new_timer()
      timer:start(2000, 2000, function()
        if busy then
          return
        end
        busy = true
        vim.system({ appearance_bin }, { text = true }, function(obj)
          busy = false
          local bg = "light"
          if obj.code == 0 and (obj.stdout or ""):match("dark") then
            bg = "dark"
          end
          vim.schedule(function()
            apply_solarized(bg)
          end)
        end)
      end)
    end,
  },
  {
    "f-person/auto-dark-mode.nvim",
    cond = not live_appearance,
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
