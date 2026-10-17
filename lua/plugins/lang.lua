-- rustaceanvim v9+ requires Neovim 0.12. On 0.11.x we pin the last v8 release;
-- after upgrading Neovim (>= 0.12) this pin clears itself automatically.
local rustaceanvim_version = "^8"
if vim.fn.has("nvim-0.12") == 1 then
  rustaceanvim_version = nil
end

local function java21_executable()
  if vim.fn.has("mac") == 1 then
    return "/opt/homebrew/opt/openjdk@21/bin/java"
  end
  if vim.env.JAVA_HOME and vim.env.JAVA_HOME ~= "" then
    return vim.fs.joinpath(vim.env.JAVA_HOME, "bin", vim.fn.has("win32") == 1 and "java.exe" or "java")
  end
  return vim.fn.exepath("java")
end

local function liblldb_path()
  local lldb = vim.fn.stdpath("data") .. "/mason/opt/lldb"
  if vim.fn.has("win32") == 1 then
    return lldb .. "/bin/liblldb.dll"
  end
  return lldb .. "/lib/liblldb" .. (vim.fn.has("mac") == 1 and ".dylib" or ".so")
end

return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local uv = vim.uv or vim.loop

      -- Root jdtls at the outermost Maven project (peipei-backend), not the git
      -- root. LazyVim passes nvim-lspconfig's nested root_markers to vim.fs.root(),
      -- which stops at the repo's .git; jdtls then imports every pom.xml in the
      -- repo -- including Claude Code worktrees under
      -- .claude/worktrees/*/peipei-backend. Those define the same Maven module
      -- names and hijack the workspace, leaving files in the main checkout as
      -- "non-project files" (no completion/diagnostics/navigation).
      opts.root_dir = function(path)
        local pom = vim.fs.root(path, { "pom.xml" })
        if pom then
          local git = vim.fs.root(path, { ".git" })
          -- Climb to the outermost pom while staying inside this checkout.
          while true do
            local parent = vim.fs.dirname(pom)
            if parent == pom or (git and #parent < #git) or not uv.fs_stat(parent .. "/pom.xml") then
              break
            end
            pom = parent
          end
          return pom
        end
        return vim.fs.root(path, {
          "settings.gradle",
          "settings.gradle.kts",
          "build.gradle",
          "build.gradle.kts",
          "build.xml",
          ".git",
        })
      end

      -- Each checkout needs its own jdtls workspace: the main repo and worktrees
      -- both end in "peipei-backend", so a basename-only project name would make
      -- them share ~/.cache/nvim/jdtls/<name> and corrupt each other.
      opts.project_name = function(root)
        if not root then
          return nil
        end
        return vim.fs.basename(root) .. "-" .. vim.fn.sha256(root):sub(1, 8)
      end

      -- Extra guard: never import worktree copies of the Maven modules.
      opts.settings = opts.settings or {}
      opts.settings.java = opts.settings.java or {}
      opts.settings.java.import = vim.tbl_deep_extend("force", opts.settings.java.import or {}, {
        exclusions = {
          "**/node_modules/**",
          "**/.metadata/**",
          "**/archetype-resources/**",
          "**/META-INF/maven/**",
          "**/.claude/**",
        },
      })

      local java21 = java21_executable()
      local lombok_jar = vim.fn.stdpath("data") .. "/mason/share/jdtls/lombok.jar"
      if not uv.fs_stat(java21) or not uv.fs_stat(lombok_jar) then
        return opts
      end

      local java_executable = "--java-executable=" .. java21
      local javaagent = "--jvm-arg=-javaagent:" .. lombok_jar
      opts.cmd = vim.tbl_filter(function(arg)
        return type(arg) ~= "string"
          or (not vim.startswith(arg, "--jvm-arg=-javaagent:") and not vim.startswith(arg, "--java-executable="))
      end, opts.cmd or { vim.fn.exepath("jdtls") })
      table.insert(opts.cmd, java_executable)
      table.insert(opts.cmd, javaagent)
      return opts
    end,
  },

  -- Rust ---------------------------------------------------------------
  -- rustaceanvim: runnables, debuggables (codelldb), code actions, neotest
  {
    "mrcjkb/rustaceanvim",
    version = rustaceanvim_version,
    -- replaces LazyVim's config, which shells out to `uname` (missing on Windows)
    config = function(_, opts)
      opts.dap = {
        adapter = require("rustaceanvim.config").get_codelldb_adapter(vim.fn.exepath("codelldb"), liblldb_path()),
      }
      vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
    end,
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

  -- C# -----------------------------------------------------------------
  -- Roslyn (the server VS Code uses) replaces the dotnet extra's OmniSharp;
  -- the extra still brings csharpier, netcoredbg and the F# bits.
  {
    "seblyng/roslyn.nvim",
    cond = vim.fn.has("nvim-0.12") == 1,
    ft = { "cs", "razor" },
    opts = {},
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = { enabled = false },
      },
    },
  },

  {
    "mason-org/mason.nvim",
    opts = {
      -- `roslyn` comes from Crashdummyy's registry, which tracks the VS Code version
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
      -- The only Mason list in this config: lazy.nvim does not dedupe merged lists, and a
      -- duplicate makes LazyVim install a package twice and abort. Extras' own tools are left out.
      ensure_installed = {
        -- C#
        "roslyn",
        -- Rust
        "rust-analyzer",
        -- JavaScript/TypeScript/React/Node
        "eslint-lsp",
        "prettierd",
        "typescript-language-server",
        -- Vue
        "vue-language-server",
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
