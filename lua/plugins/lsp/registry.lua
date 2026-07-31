local M = {}

local internal_keys = {
  enabled = true,
  keys = true,
  managed = true,
  owner = true,
}

local function default_dependencies()
  return {
    protocol_capabilities = vim.lsp.protocol.make_client_capabilities,
    blink_capabilities = function(capabilities)
      local ok, blink = pcall(require, 'blink.cmp')
      if not ok then return capabilities end
      return blink.get_lsp_capabilities(capabilities)
    end,
    config = vim.lsp.config,
    enable = vim.lsp.enable,
  }
end

local function dependencies(overrides)
  return vim.tbl_deep_extend('force', default_dependencies(), overrides or {})
end

local function public_config(config)
  config = vim.deepcopy(config)
  for key in pairs(internal_keys) do
    config[key] = nil
  end
  return config
end

local function shared_capabilities(opts, deps)
  local protocol = deps.protocol_capabilities()
  local blink = deps.blink_capabilities(vim.deepcopy(protocol)) or {}
  return vim.tbl_deep_extend('force', {}, protocol, blink, opts.capabilities or {})
end

---@param opts table
---@param overrides? table
function M.setup(opts, overrides)
  opts = opts or {}
  local deps = dependencies(overrides)
  local capabilities = shared_capabilities(opts, deps)
  local configured = {}

  for server, server_opts in pairs(opts.servers or {}) do
    server_opts = server_opts == true and {} or server_opts
    if type(server_opts) == 'table'
      and server_opts.enabled ~= false
      and server_opts.managed ~= false
      and server_opts.owner == nil
      and not configured[server]
    then
      local config = vim.tbl_deep_extend('force', {
        capabilities = vim.deepcopy(capabilities),
      }, vim.deepcopy(opts.defaults or {}), vim.deepcopy(server_opts))
      config = public_config(config)

      local handled = false
      local named = opts.setup and opts.setup[server]
      if named then handled = named(server, config) == true end
      local wildcard = opts.setup and opts.setup['*']
      if wildcard then handled = wildcard(server, config) == true or handled end

      if not handled then
        deps.config(server, config)
        deps.enable(server)
      end
      configured[server] = true
    end
  end

  return configured
end

return M
