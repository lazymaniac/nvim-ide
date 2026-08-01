local M = {}

function M.assert_supported(dependencies)
  dependencies = dependencies or {}
  local has = dependencies.has or vim.fn.has
  if has 'nvim-0.12' == 1 then
    return
  end

  local version = (dependencies.version or vim.version)()
  local observed = ('%d.%d.%d'):format(version.major or 0, version.minor or 0, version.patch or 0)
  error(
    ('NV-IDE requires Neovim >= 0.12.0; found %s. Install a supported release from https://neovim.io/doc/install/'):format(
      observed
    ),
    0
  )
end

return M
