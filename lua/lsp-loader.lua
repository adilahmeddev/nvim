-- Reads lsp-servers.json and returns server configs + mason install list.
--
-- JSON schema:
--   servers    - map of server_name -> config (passed to vim.lsp.config)
--   tools      - list of non-LSP tools for mason to install (formatters, linters)
--   local_only - list of server names to skip mason install (use system binary)

local M = {}

local log_path = vim.fn.stdpath 'config' .. '/log_file.txt'

-- Overwrite log on each startup
do
  local f = io.open(log_path, 'w')
  if f then
    f:write('[lsp-loader] startup ' .. os.date '%Y-%m-%d %H:%M:%S' .. '\n')
    f:close()
  end
end

local function log(msg)
  local f = io.open(log_path, 'a')
  if f then
    f:write('[lsp-loader] ' .. msg .. '\n')
    f:close()
  end
end

M.log = log

local function read_json()
  local path = vim.fn.stdpath 'config' .. '/lsp-servers.json'
  local file = io.open(path, 'r')
  if not file then
    vim.notify('lsp-servers.json not found at ' .. path, vim.log.levels.WARN)
    return nil
  end
  local content = file:read '*a'
  file:close()
  return vim.json.decode(content)
end

local cached_config = nil

local function get_config()
  if cached_config then
    return cached_config
  end
  cached_config = read_json() or { servers = {}, tools = {}, local_only = {} }
  return cached_config
end

function M.servers()
  return get_config().servers or {}
end

-- Must be called after mason.nvim has been set up (registry sources loaded).
-- Resolves LSP server names to mason package names using the registry.
function M.mason_ensure_installed()
  local config = get_config()
  local servers = config.servers or {}
  local tools = config.tools or {}

  local local_only = {}
  for _, name in ipairs(config.local_only or {}) do
    local_only[name] = true
  end

  -- Build lspconfig_name -> mason_package_name from the registry
  local lsp_to_mason = {}
  local ok, registry = pcall(require, 'mason-registry')
  if ok then
    for _, pkg_spec in ipairs(registry.get_all_package_specs()) do
      local lspconfig_name = vim.tbl_get(pkg_spec, 'neovim', 'lspconfig')
      if lspconfig_name then
        lsp_to_mason[lspconfig_name] = pkg_spec.name
      end
    end
  end
  local result = {}
  for name, _ in pairs(servers) do
    if local_only[name] then
      log(name .. ' (local_only, skipping mason)')
    else
      local mason_name = lsp_to_mason[name]
      if mason_name then
        log(name .. ' -> mason:' .. mason_name)
        table.insert(result, mason_name)
      else
        log(name .. ' (no mason mapping, using name as-is)')
        table.insert(result, name)
      end
    end
  end
  for _, tool in ipairs(tools) do
    table.insert(result, tool)
  end

  return result
end

return M
