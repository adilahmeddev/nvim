return {
  'ficcdaf/ashen.nvim',
  -- optional but recommended,
  -- pin to the latest stable release:
  lazy = false,
  priority = 1000, -- Make sure to load this before all the other start plugins.
  init = function()
    -- Load the colorscheme here.
    -- Like many other themes, this one has different styles, and you could load
    -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
    vim.cmd.colorscheme 'ash'

    -- You can configure highlights by doing something like:
  end,
  -- configuration is optional!
  opts = {
    -- your settings here
  },
}
