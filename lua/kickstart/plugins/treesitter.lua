return {
  { -- Parser installation (highlight/indent are built-in in 0.12)
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    config = function()
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
    -- Incremental selection is built-in in 0.12:
    --   In visual mode: `an` to expand, `in` to shrink, `]n`/`[n` for siblings
  },
}
-- vim: ts=2 sts=2 sw=2 et
