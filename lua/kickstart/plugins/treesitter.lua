return {
  { -- Parser installation (highlight/indent are built-in in 0.12)
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    init = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = require('nvim-treesitter').get_installed(),
        callback = function()
          vim.treesitter.start()
        end,
      })
    end,
    build = ':TSUpdate',
    -- Incremental selection is built-in in 0.12:
    --   In visual mode: `an` to expand, `in` to shrink, `]n`/`[n` for siblings
  },
}
-- vim: ts=2 sts=2 sw=2 et
