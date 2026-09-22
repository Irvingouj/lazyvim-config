local function load_deepseek_env()
  if vim.env.DEEPSEEK_API_KEY and vim.env.DEEPSEEK_API_KEY ~= "" then
    return
  end

  local rc = vim.fn.expand("~/rc.deepseek.rc")
  if vim.fn.filereadable(rc) == 0 then
    return
  end

  local key = vim.fn.system({ "zsh", "-c", "source " .. vim.fn.shellescape(rc) .. " >/dev/null 2>&1; printf %s \"$DEEPSEEK_API_KEY\"" })
  if vim.v.shell_error == 0 and key ~= "" then
    vim.env.DEEPSEEK_API_KEY = key
  end
end

return {
  {
    "milanglacier/minuet-ai.nvim",
    config = function()
      load_deepseek_env()

      require("minuet").setup({
        provider = "openai_fim_compatible",
        blink = {
          enable_auto_complete = false,
        },
        provider_options = {
          openai_fim_compatible = {
            api_key = "DEEPSEEK_API_KEY",
            name = "Deepseek",
            model = "deepseek-v4-flash",
            end_point = "https://api.deepseek.com/beta/completions",
            optional = {
              max_tokens = 256,
              top_p = 0.9,
            },
          },
        },
      })
    end,
  },
  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      opts.keymap = opts.keymap or {}
      opts.keymap["<A-y>"] = {
        function(cmp)
          cmp.show({ providers = { "minuet" } })
        end,
      }

      opts.sources = opts.sources or {}
      opts.sources.providers = opts.sources.providers or {}
      opts.sources.providers.minuet = {
        name = "minuet",
        module = "minuet.blink",
        async = true,
        timeout_ms = 3000,
        score_offset = 100,
      }
    end,
  },
}
