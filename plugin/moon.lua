-- Moon language support for Neovim (installed by editors/nvim/setup.ps1).
-- Plugin-free: uses Neovim's built-in LSP (0.11+) and tree-sitter runtimes.
-- Re-run editors/nvim/setup.ps1 from the moon repo to refresh.

-- 1. Filetype ---------------------------------------------------------------
vim.filetype.add({ extension = { moon = "moon" } })

-- Resolve the language server command: prefer a 'moon' on PATH, else the
-- absolute path to the binary this machine built.
local moon_cmd = (vim.fn.executable("moon") == 1) and "moon"
  or [[C:\Users\adil\dev\moon-zig\zig-out\bin\moon.exe]]

-- 2. LSP --------------------------------------------------------------------
-- Native client (Neovim 0.11+). Falls back to nvim-lspconfig on older versions.
if vim.lsp and vim.lsp.config and vim.lsp.enable then
  vim.lsp.config("moon", {
    cmd = { moon_cmd, "lsp" },
    filetypes = { "moon" },
    root_markers = { "moon.toml", ".git" },
  })
  vim.lsp.enable("moon")
else
  local ok, lspconfig = pcall(require, "lspconfig")
  if ok then
    local configs = require("lspconfig.configs")
    local util = require("lspconfig.util")
    if not configs.moon then
      configs.moon = {
        default_config = {
          cmd = { moon_cmd, "lsp" },
          filetypes = { "moon" },
          root_dir = util.root_pattern("moon.toml", ".git"),
          single_file_support = true,
        },
      }
    end
    lspconfig.moon.setup({})
  end
end

-- 3. Per-buffer options + tree-sitter highlighting --------------------------
vim.api.nvim_create_autocmd("FileType", {
  pattern = "moon",
  callback = function(args)
    vim.bo[args.buf].commentstring = "// %s"
    vim.bo[args.buf].comments = ":\\/\\/"
    -- Built-in tree-sitter highlighting (parser + queries installed alongside).
    pcall(vim.treesitter.start, args.buf, "moon")
  end,
})
