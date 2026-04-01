-- Reads lsp-servers.json and returns mason install list + server configs.
--
-- JSON schema:
--   servers  - map of server_name -> config (passed to vim.lsp.config)
--   tools    - list of non-LSP tools for mason to install (formatters, linters)
--   local_only - list of server names to skip mason install (use system binary)

local M = {}

local function read_json()
  local path = vim.fn.stdpath('config') .. '/lsp-servers.json'
  local file = io.open(path, 'r')
  if not file then
    vim.notify('lsp-servers.json not found at ' .. path, vim.log.levels.WARN)
    return nil
  end
  local content = file:read('*a')
  file:close()
  return vim.json.decode(content)
end

function M.load()
  local config = read_json()
  if not config then
    return { servers = {}, mason_ensure_installed = {} }
  end

  local servers = config.servers or {}
  local tools = config.tools or {}
  local local_only = {}
  for _, name in ipairs(config.local_only or {}) do
    local_only[name] = true
  end

  local mason_ensure_installed = {}
  for name, _ in pairs(servers) do
    if not local_only[name] then
      table.insert(mason_ensure_installed, name)
    end
  end
  for _, tool in ipairs(tools) do
    table.insert(mason_ensure_installed, tool)
  end

  return {
    servers = servers,
    mason_ensure_installed = mason_ensure_installed,
  }
end

return M
