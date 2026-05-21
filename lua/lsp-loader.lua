-- Reads lsp-servers.json and returns server configs + mason install list.
--
-- JSON schema:
--   servers - map of server_name -> config (passed to vim.lsp.config).
--             Set `local = true` on a server to skip mason install and use the
--             system binary instead.
--   tools   - list of non-LSP tools for mason to install (formatters, linters)

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
  cached_config = read_json() or { servers = {}, tools = {} }
  return cached_config
end

local cached_mappings = nil

-- Build bidirectional maps between lspconfig server names and mason package names.
-- Cached only when mason-registry is loaded; otherwise returns empty maps so we
-- retry on a later call.
local function get_mason_mappings()
  if cached_mappings then
    return cached_mappings
  end
  local lsp_to_mason = {}
  local mason_to_lsp = {}
  local ok, registry = pcall(require, 'mason-registry')
  if not ok then
    return { lsp_to_mason = lsp_to_mason, mason_to_lsp = mason_to_lsp }
  end
  for _, pkg_spec in ipairs(registry.get_all_package_specs()) do
    local lspconfig_name = vim.tbl_get(pkg_spec, 'neovim', 'lspconfig')
    if lspconfig_name then
      lsp_to_mason[lspconfig_name] = pkg_spec.name
      mason_to_lsp[pkg_spec.name] = lspconfig_name
    end
  end
  cached_mappings = { lsp_to_mason = lsp_to_mason, mason_to_lsp = mason_to_lsp }
  return cached_mappings
end

function M.servers()
  local raw = get_config().servers or {}
  local mason_to_lsp = get_mason_mappings().mason_to_lsp
  local normalized = {}
  for name, config in pairs(raw) do
    local lsp_name = mason_to_lsp[name] or name
    if lsp_name ~= name then
      log('normalized mason name ' .. name .. ' -> ' .. lsp_name)
    end
    local clean = {}
    for k, v in pairs(config) do
      if k ~= 'local' then
        clean[k] = v
      end
    end
    normalized[lsp_name] = clean
  end
  return normalized
end

-- Must be called after mason.nvim has been set up (registry sources loaded).
-- Server keys may be either lspconfig names or mason package names; both are
-- handled. Servers with `local = true` skip mason install.
function M.mason_ensure_installed()
  local config = get_config()
  local servers = config.servers or {}
  local tools = config.tools or {}
  local mappings = get_mason_mappings()
  local lsp_to_mason = mappings.lsp_to_mason
  local mason_to_lsp = mappings.mason_to_lsp

  local result = {}
  for name, server_config in pairs(servers) do
    if server_config['local'] then
      log(name .. ' (local, skipping mason)')
    elseif mason_to_lsp[name] then
      log(name .. ' (mason name, using as-is)')
      table.insert(result, name)
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
