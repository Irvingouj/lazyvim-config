-- rustaceanvim v9+ requires Neovim 0.12. On 0.11.x we pin the last v8 release;
-- after `brew upgrade neovim` (>= 0.12) this pin clears itself automatically.
local rustaceanvim_version = "^8"
if vim.fn.has("nvim-0.12") == 1 then
  rustaceanvim_version = nil
end

return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local java21 = "/opt/homebrew/opt/openjdk@21/bin/java"
      local lombok_jar = vim.fn.stdpath("data") .. "/mason/share/jdtls/lombok.jar"
      if not (vim.uv or vim.loop).fs_stat(java21) or not (vim.uv or vim.loop).fs_stat(lombok_jar) then
        return
      end

      local java_executable = "--java-executable=" .. java21
      local javaagent = "--jvm-arg=-javaagent:" .. lombok_jar
      opts.cmd = vim.tbl_filter(function(arg)
        return type(arg) ~= "string"
          or (not vim.startswith(arg, "--jvm-arg=-javaagent:") and not vim.startswith(arg, "--java-executable="))
      end, opts.cmd or { vim.fn.exepath("jdtls") })
      table.insert(opts.cmd, java_executable)
      table.insert(opts.cmd, javaagent)
    end,
  },

  -- Rust ---------------------------------------------------------------
  -- rustaceanvim: runnables, debuggables (codelldb), code actions, neotest
  {
    "mrcjkb/rustaceanvim",
    version = rustaceanvim_version,
    opts = function(_, opts)
      local ra = opts.server.default_settings["rust-analyzer"]

      -- `checkOnSave` is a deprecated alias of `check`
      ra.checkOnSave = nil
      ra.check = { command = "clippy" } -- clippy lints instead of plain `cargo check`

      ra.cargo = vim.tbl_deep_extend("force", ra.cargo or {}, {
        allFeatures = true,
        buildScripts = { enable = true },
      })

      -- Inline type/param hints (toggle with <leader>uh)
      ra.inlayHints = vim.tbl_deep_extend("force", ra.inlayHints or {}, {
        typeHints = { enable = true },
        parameterHints = { enable = true },
        chainingHints = { enable = true },
        closureReturnTypeHints = { enable = "with_block" },
        lifetimeElisionHints = { enable = "skip_trivial" },
      })

      -- LazyVim only ships <leader>cR (code action) and <leader>dr
      -- (debuggables); add the runnables / macro maps rustaceanvim offers.
      local lazyvim_on_attach = opts.server.on_attach
      opts.server.on_attach = function(client, bufnr)
        if lazyvim_on_attach then
          lazyvim_on_attach(client, bufnr)
        end
        vim.keymap.set("n", "<leader>rr", function()
          vim.cmd.RustLsp("runnables")
        end, { desc = "Rust Runnables", buffer = bufnr })
        vim.keymap.set("n", "<leader>rm", function()
          vim.cmd.RustLsp("expandMacro")
        end, { desc = "Rust Expand Macro", buffer = bufnr })
      end
    end,
  },

  -- Format Rust with rustfmt on <leader>cf, honouring rustfmt.toml
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        rust = { "rustfmt" },
      },
    },
  },

  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- JavaScript/TypeScript/React/Node
        "eslint-lsp",
        "prettierd",
        "typescript-language-server",
        "js-debug-adapter",
        -- Go
        "gofumpt",
        "goimports",
        -- JSON/CSS/HTML
        "json-lsp",
        "css-lsp",
        "html-lsp",
        "tailwindcss-language-server",

        -- Prisma
        "prisma-language-server",
      },
    },
  },
}
