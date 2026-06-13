local mason_lsp_servers = {
  'clangd',
  'gopls',
  'vtsls',
  'basedpyright',
  'rust_analyzer',
  'jsonls',
  'lua_ls',
}

local local_lsp_servers = {
  'moon_lsp',
}

local lsp_server_configs = {
  lua_ls = {
    settings = {
      Lua = {
        completion = {
          callSnippet = 'Replace',
        },
      },
    },
  },
}

local mason_tools = {
  'stylua',
}

local log_path = vim.fn.stdpath 'config' .. '/log_file.txt'

local function reset_lsp_log()
  local file = io.open(log_path, 'w')
  if file then
    file:write('[lsp] startup ' .. os.date '%Y-%m-%d %H:%M:%S' .. '\n')
    file:close()
  end
end

local function log(msg)
  local file = io.open(log_path, 'a')
  if file then
    file:write('[lsp] ' .. msg .. '\n')
    file:close()
  end
end

local function setup_lsp()
  reset_lsp_log()

  -- Apply blink.cmp capabilities before enabling servers so completions work
  local blink_ok, blink = pcall(require, 'blink.cmp')
  if blink_ok then
    vim.lsp.config('*', {
      capabilities = blink.get_lsp_capabilities(),
    })
    log('applied blink.cmp capabilities')
  else
    log('WARN: blink.cmp not loaded yet, completions may not work')
  end

  -- Global callbacks for all LSP clients: log errors and exits
  vim.lsp.config('*', {
    on_error = function(code, err)
      log('ERROR code=' .. tostring(code) .. ': ' .. tostring(err))
    end,
    on_exit = function(code, signal, client_id)
      local msg = 'exit client_id=' .. tostring(client_id) .. ' code=' .. tostring(code) .. ' signal=' .. tostring(signal)
      log(msg)
    end,
  })

  for _, name in ipairs(vim.list_extend(vim.deepcopy(mason_lsp_servers), local_lsp_servers)) do
    vim.lsp.config(name, lsp_server_configs[name] or {})
    log('configured ' .. name)
  end

  vim.lsp.enable(local_lsp_servers)
  log('mason-lspconfig will enable: ' .. table.concat(mason_lsp_servers, ', '))
  log('enabled local-only: ' .. table.concat(local_lsp_servers, ', '))
end

-- Log LSP detach events
vim.api.nvim_create_autocmd('LspDetach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-detach-log', { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client then
      log('detached ' .. client.name .. ' from buffer ' .. event.buf)
    end
  end,
})

-- LspAttach: buffer-local keymaps and features
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client then
      log('attached ' .. client.name .. ' to buffer ' .. event.buf)
    end
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
    map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
    map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')
    map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')
    -- grt (type definition) and grx (codelens run) are built-in defaults in 0.12

    -- Highlight references of symbol under cursor
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })
      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    -- Toggle inlay hints
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, '[T]oggle Inlay [H]ints')
    end

    -- Linked editing ranges (e.g., edit HTML opening+closing tags together)
    if client and client:supports_method('textDocument/linkedEditingRange') then
      vim.lsp.linked_editing_range.enable(true, { client_id = client.id })
    end
  end,
})

-- Diagnostic Config
vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  } or {},
  virtual_text = {
    source = 'if_many',
    spacing = 2,
  },
}

-- LSP plugin specs
return {
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    'mason-org/mason.nvim',
    opts = {
      registries = { 'github:mason-org/mason-registry' },
    },
  },
  {
    -- Provides default cmd/filetypes/root_markers for LSP servers via lsp/*.lua files.
    -- We don't call lspconfig.setup() — Neovim 0.12 reads these from the runtimepath.
    'neovim/nvim-lspconfig',
    lazy = false,
  },
  {
    'mason-org/mason-lspconfig.nvim',
    dependencies = {
      'mason-org/mason.nvim',
      'neovim/nvim-lspconfig',
      'saghen/blink.cmp',
    },
    opts = {
      ensure_installed = mason_lsp_servers,
      automatic_enable = mason_lsp_servers,
    },
    config = function(_, opts)
      setup_lsp()
      require('mason-lspconfig').setup(opts)
    end,
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      ensure_installed = mason_tools,
    },
  },
  {
    'j-hui/fidget.nvim',
    opts = {},
  },
}
-- vim: ts=2 sts=2 sw=2 et
