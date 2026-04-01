return {
  {
    'stevearc/quicker.nvim',
    ft = 'qf',
    ---@module "quicker"
    ---@type quicker.SetupOptions
    opts = {},
    config = function()
      require('quicker').setup {}
    end,
  },
}
