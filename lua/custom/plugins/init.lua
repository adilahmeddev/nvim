-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
--
return {
  {
    'norcalli/nvim-colorizer.lua',
    config = function()
      require('colorizer').setup()
    end,
  },
  -- require 'custom.plugins.themes.kanagawa',
  require 'custom.plugins.rustaceanvim',
  -- require 'custom.plugins.n'
}
