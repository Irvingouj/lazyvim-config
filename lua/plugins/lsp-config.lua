-- LSP Configuration for Swift, TypeScript, Vue, React, Node
-- (Rust is handled by rustaceanvim -- see plugins/lang.lua)
return {
  -- Consolidated LSP configuration for all languages
  {
    "neovim/nvim-lspconfig",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "swift",
        callback = function(args)
          if #vim.lsp.get_clients({ bufnr = args.buf, name = "sourcekit" }) > 0 then
            return
          end

          local util = require("lspconfig.util")
          local fname = vim.api.nvim_buf_get_name(args.buf)
          local root_dir = util.root_pattern(
            "buildServer.json",
            ".bsp",
            "*.xcodeproj",
            "*.xcworkspace",
            "compile_commands.json",
            "Package.swift",
            ".git"
          )(fname)

          if not root_dir then
            return
          end

          -- SourceKit is provided by Xcode, so start it directly instead of relying on Mason.
          vim.api.nvim_buf_call(args.buf, function()
            vim.lsp.start({
              name = "sourcekit",
              cmd = { "xcrun", "sourcekit-lsp" },
              root_dir = root_dir,
            })
          end)
        end,
      })
    end,
    opts = {
      servers = {
        -- Disable markdown LSP
        marksman = false,
        -- Rust is handled by rustaceanvim -- see plugins/lang.lua
        -- Swift LSP
        sourcekit = {
          cmd = { "xcrun", "sourcekit-lsp" },
          filetypes = { "swift", "objective-c", "objective-cpp" },
          root_dir = function(fname)
            local util = require("lspconfig.util")
            return util.root_pattern(
              "buildServer.json",
              ".bsp",
              "*.xcodeproj",
              "*.xcworkspace",
              "compile_commands.json",
              "Package.swift",
              ".git"
            )(fname)
          end,
        },
      },
    },
  },

  -- TypeScript/Vue LSP configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {
          settings = {
            typescript = {
              inlayHints = {
                parameterNames = { enabled = "all" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
            },
            javascript = {
              inlayHints = {
                parameterNames = { enabled = "all" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
              },
            },
          },
        },
        volar = {
          settings = {
            vue = {
              inlayHints = {
                missingProps = true,
                inlineHandlerLeading = true,
              },
            },
          },
        },
        eslint = {
          settings = {
            workingDirectories = { mode = "auto" },
            format = false,
          },
        },
      },
    },
  },

  -- Mason: Install additional LSP servers and tools
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        -- Rust
        "rust-analyzer",
        "codelldb",
        -- TypeScript/JavaScript/Node
        "typescript-language-server",
        "eslint-lsp",
        "prettierd",
        "js-debug-adapter",
        -- Vue
        "vue-language-server",
        -- General
        "tailwindcss-language-server",
        "css-lsp",
        "html-lsp",
        "json-lsp",
        -- "markdown-oxide", -- Disabled
      },
    },
  },

  -- Additional Swift development tools
  {
    "wojciech-kulik/xcodebuild.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "MunifTanjim/nui.nvim",
    },
    ft = "swift",
    config = function()
      require("xcodebuild").setup({
        show_build_progress = true,
        save_before_build = true,
      })
    end,
    keys = {
      { "<leader>xb", "<cmd>XcodeBuild<cr>", desc = "Xcode Build" },
      { "<leader>xr", "<cmd>XcodeBuildRun<cr>", desc = "Xcode Build & Run" },
      { "<leader>xt", "<cmd>XcodeBuildTest<cr>", desc = "Xcode Run Tests" },
    },
  },
}
