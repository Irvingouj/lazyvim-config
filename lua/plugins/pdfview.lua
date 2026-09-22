local function open_pdf(path)
  if not path or path == "" then
    require("lazy").load({ plugins = { "PDFview" } })
    require("pdfview").telescope_open()
    return
  end

  local lines = vim.fn.systemlist({ "pdftotext", "-layout", path, "-" })
  if vim.v.shell_error ~= 0 then
    vim.notify("PDFview: failed to extract text from " .. path, vim.log.levels.ERROR)
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].modifiable = true
  vim.bo[buf].readonly = false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "pdfview"
  vim.bo[buf].modified = false
  vim.bo[buf].modifiable = false
end

local function open_pdf_later(path, picker)
  vim.schedule(function()
    if picker and picker.main and vim.api.nvim_win_is_valid(picker.main) then
      vim.api.nvim_set_current_win(picker.main)
    end
    open_pdf(path)
  end)
end

return {
  {
    "basola21/PDFview",
    dependencies = { "nvim-telescope/telescope.nvim" },
    lazy = true,
    keys = {
      {
        "<leader>fp",
        function()
          open_pdf()
        end,
        desc = "Find PDF",
      },
      {
        "]p",
        function()
          vim.api.nvim_feedkeys(vim.keycode("<C-f>"), "n", false)
        end,
        desc = "PDF Page Down",
      },
      {
        "[p",
        function()
          vim.api.nvim_feedkeys(vim.keycode("<C-b>"), "n", false)
        end,
        desc = "PDF Page Up",
      },
    },
    init = function()
      vim.api.nvim_create_user_command("PdfviewOpen", function(opts)
        open_pdf(opts.args ~= "" and opts.args or nil)
      end, { nargs = "?", complete = "file" })

      vim.api.nvim_create_autocmd("BufReadCmd", {
        pattern = "*.pdf",
        callback = function()
          open_pdf(vim.api.nvim_buf_get_name(0))
        end,
      })
    end,
  },
  {
    "folke/snacks.nvim",
    optional = true,
    opts = {
      picker = {
        sources = {
          explorer = {
            config = function(opts)
              opts = require("snacks.picker.source.explorer").setup(opts)
              opts.actions.confirm = function(picker, item, action)
                if item and item.file and not item.dir and item.file:lower():match("%.pdf$") then
                  open_pdf_later(item.file, picker)
                  return
                end
                require("snacks.explorer.actions").actions.confirm(picker, item, action)
              end
              return opts
            end,
          },
        },
      },
    },
  },
}
