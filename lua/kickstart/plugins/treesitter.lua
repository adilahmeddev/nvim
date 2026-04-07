return {
  { -- Parser installation (highlight/indent are built-in in 0.12)
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    main = 'nvim-treesitter.config',
    init = function()
      vim.api.nvim_create_autocmd('User', {
        pattern = 'TSUpdate',
        callback = function()
          require('nvim-treesitter.parsers').moon = {
            install_info = {
              url = 'https://github.com/adilahmeddev/tree-sitter-moon',
              branch = 'master',
              files = { 'src/parser.c' },
              queries = 'queries',
              generate = true,
            },
          }
        end,
      })
    end,
    opts = {
      ensure_installed = { 'moon' },
    },
    -- Incremental selection is built-in in 0.12:
    --   In visual mode: `an` to expand, `in` to shrink, `]n`/`[n` for siblings
  },
}
-- vim: ts=2 sts=2 sw=2 et
