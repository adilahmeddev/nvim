-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '<leader>ff', function()
  local bufname = vim.api.nvim_buf_get_name(0)
  local is_real_file = bufname ~= '' and vim.uv.fs_stat(bufname) ~= nil
  if is_real_file then
    vim.cmd 'Neotree float reveal_force_cwd'
  else
    vim.cmd('Neotree float dir=' .. vim.fn.getcwd())
  end
end, { desc = 'NeoTree float reveal' })
-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

vim.api.nvim_create_user_command('LspInfo', function(opts)
  local entries = {}

  if opts.args == 'all' then
    local lsp_loader = require('lsp-loader')
    local servers = lsp_loader.servers()
    local active_clients = vim.lsp.get_clients()
    local active_names = {}
    for _, c in ipairs(active_clients) do
      active_names[c.name] = c
    end
    for name, config in pairs(servers) do
      local enabled = vim.lsp.is_enabled(name)
      local client = active_names[name]
      local status = client and 'active' or (enabled and 'enabled' or 'disabled')
      table.insert(entries, {
        name = name,
        status = status,
        info = {
          enabled = enabled,
          active = client ~= nil,
          id = client and client.id or nil,
          root_dir = client and client.root_dir or nil,
          cmd = (client and client.config.cmd) or config.cmd,
          filetypes = (client and client.config.filetypes) or config.filetypes,
          settings = (client and client.config.settings) or config.settings,
        },
      })
    end
  else
    local clients = vim.lsp.get_clients { bufnr = 0 }
    if #clients == 0 then
      vim.notify('No LSP clients attached to this buffer', vim.log.levels.INFO)
      return
    end
    for _, client in ipairs(clients) do
      table.insert(entries, {
        name = client.name,
        status = 'active',
        info = {
          id = client.id,
          root_dir = client.root_dir,
          cmd = client.config.cmd,
          filetypes = client.config.filetypes,
          settings = client.config.settings,
          capabilities = client.capabilities,
        },
      })
    end
  end

  table.sort(entries, function(a, b)
    return a.name < b.name
  end)

  local pickers = require('telescope.pickers')
  local finders = require('telescope.finders')
  local previewers = require('telescope.previewers')
  local conf = require('telescope.config').values

  pickers
    .new({}, {
      prompt_title = opts.args == 'all' and 'LSP Servers (all)' or 'LSP Clients (buffer)',
      finder = finders.new_table {
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.name .. '  [' .. entry.status .. ']',
            ordinal = entry.name .. ' ' .. entry.status,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer {
        title = 'Config',
        define_preview = function(self, entry)
          local lines = vim.split(vim.inspect(entry.value.info), '\n')
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.bo[self.state.bufnr].filetype = 'lua'
        end,
      },
    })
    :find()
end, {
  nargs = '?',
  complete = function()
    return { 'all' }
  end,
  desc = 'Show LSP clients for current buffer, or "all" for all configured servers',
})

vim.api.nvim_create_user_command('LspLog', function()
  local log_path = vim.fn.stdpath 'config' .. '/log_file.txt'
  vim.cmd.edit(log_path)
end, { desc = 'Open LSP log file' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- vim: ts=2 sts=2 sw=2 et
