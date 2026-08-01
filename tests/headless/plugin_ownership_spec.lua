local h = require 'tests.headless.harness'

local function plugin(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name or spec.url == name then
      return spec
    end
  end
end

local function read(path)
  return table.concat(vim.fn.readfile(path), '\n')
end

local function plugin_source()
  local parts = {}
  for _, path in ipairs(vim.fn.glob('lua/plugins/**/*.lua', false, true)) do
    parts[#parts + 1] = read(path)
  end
  for _, path in ipairs(vim.fn.glob('lua/plugins/*.lua', false, true)) do
    parts[#parts + 1] = read(path)
  end
  return table.concat(parts, '\n')
end

local function has_trigger(spec)
  return spec.event ~= nil or spec.ft ~= nil or spec.cmd ~= nil or spec.keys ~= nil or spec.lazy == false or spec.priority ~= nil
end

local function all_plugin_modules()
  local paths = vim.fn.glob('lua/plugins/*.lua', false, true)
  vim.list_extend(paths, vim.fn.glob('lua/plugins/lsp/lang/*.lua', false, true))
  table.sort(paths)
  return paths
end

local fragment_owners = {
  ['folke/lazy.nvim'] = true,
  ['mfussenegger/nvim-dap'] = true,
  ['neovim/nvim-lspconfig'] = true,
  ['nvim-lua/plenary.nvim'] = true,
}

local function with_util_stub(body)
  local previous = package.loaded.util
  package.loaded.util = {
    safe_keymap_set = function() end,
    has = function()
      return false
    end,
    get_pkg_path = function()
      return '/tmp/mason-package'
    end,
    lsp = {
      action = setmetatable({}, {
        __index = function()
          return function() end
        end,
      }),
      execute = function() end,
      get_clients = function()
        return {}
      end,
      on_attach = function() end,
    },
  }
  local ok, result = xpcall(body, debug.traceback)
  package.loaded.util = previous
  if not ok then
    error(result, 0)
  end
  return result
end

h.describe('plugin ownership', function()
  h.it('removes approved duplicate and obsolete owners', function()
    local source = plugin_source()
    for _, removed in ipairs {
      'folke/todo-comments.nvim',
      'chrishrb/gx.nvim',
      'stevearc/dressing.nvim',
      'mason-bridge.nvim',
      'ray-x/go.nvim',
      'ray-x/guihua.lua',
      'nvim-tree/nvim-web-devicons',
    } do
      h.falsy(source:find(removed, 1, true), removed .. ' must have no remaining plugin owner')
    end
  end)

  h.it('initializes mini.icons and its compatibility shim before icon consumers', function()
    local specs = dofile 'lua/plugins/ui.lua'
    local icons = plugin(specs, 'echasnovski/mini.icons')
    local snacks = plugin(dofile 'lua/plugins/snacks.lua', 'folke/snacks.nvim')
    h.truthy(icons)
    h.equal(icons.lazy, false)
    h.truthy((icons.priority or 0) > (snacks.priority or 0), 'mini.icons must initialize before Snacks')

    local calls = {}
    local previous = package.loaded['mini.icons']
    package.loaded['mini.icons'] = {
      setup = function()
        calls[#calls + 1] = 'setup'
      end,
      mock_nvim_web_devicons = function()
        calls[#calls + 1] = 'shim'
      end,
    }
    local ok, err = xpcall(function()
      icons.config(nil, icons.opts)
    end, debug.traceback)
    package.loaded['mini.icons'] = previous
    if not ok then
      error(err, 0)
    end
    h.deep_equal(calls, { 'setup', 'shim' })
  end)

  h.it('retains the explicitly selected integration plugins', function()
    local leap = plugin(dofile 'lua/plugins/search.lua', 'https://codeberg.org/andyg/leap.nvim')
    local clangd = plugin(dofile 'lua/plugins/lsp/lang/clangd.lua', 'p00f/clangd_extensions.nvim')
    local tiny = plugin(dofile 'lua/plugins/coding.lua', 'rachartier/tiny-inline-diagnostic.nvim')
    local hlslens = plugin(dofile 'lua/plugins/editor.lua', 'kevinhwang91/nvim-hlslens')
    h.truthy(leap and leap.keys, 'Leap must remain explicitly mapped')
    h.truthy(clangd and has_trigger(clangd), 'clangd extensions must remain reachable')
    h.truthy(tiny and has_trigger(tiny), 'tiny inline diagnostics must remain active')
    h.truthy(hlslens and has_trigger(hlslens), 'hlslens must remain active')
  end)

  h.it('uses the published Haskell plugin branches', function()
    local haskell = dofile 'lua/plugins/lsp/lang/haskell.lua'
    h.equal(plugin(haskell, 'mrcjkb/haskell-tools.nvim').branch, 'main')
    h.equal(plugin(haskell, 'mrcjkb/haskell-snippets.nvim').branch, 'main')

    local neotest = plugin(dofile 'lua/plugins/tests.lua', 'nvim-neotest/neotest')
    h.equal(plugin(neotest.dependencies, 'mrcjkb/neotest-haskell').branch, 'main')
  end)

  h.it('uses hlargs only when parameter semantic tokens are unavailable', function()
    local hlargs = plugin(dofile 'lua/plugins/coding.lua', 'm-demare/hlargs.nvim')
    h.truthy(hlargs)
    h.truthy(hlargs.opts and type(hlargs.opts.disable) == 'function')

    local original = vim.lsp.get_clients
    vim.lsp.get_clients = function()
      return {
        {
          server_capabilities = {
            semanticTokensProvider = { legend = { tokenTypes = { 'variable', 'parameter' } } },
          },
        },
      }
    end
    local supported = hlargs.opts.disable('lua', 1)
    vim.lsp.get_clients = function()
      return {
        { server_capabilities = { semanticTokensProvider = { legend = { tokenTypes = { 'variable' } } } } },
      }
    end
    local unsupported = hlargs.opts.disable('lua', 1)
    vim.lsp.get_clients = original

    h.truthy(supported, 'hlargs must yield to parameter semantic tokens')
    h.falsy(unsupported, 'hlargs must remain the fallback without parameter semantic tokens')
  end)

  h.it('keeps the complete Go replacement workflow registered', function()
    local go = plugin(dofile 'lua/plugins/lsp/lang/go.lua', 'neovim/nvim-lspconfig')
    h.truthy(go and go.opts.servers.gopls, 'gopls is missing')

    local tooling = read 'lua/plugins/lint_and_format.lua'
    h.matches(tooling, "go = { 'goimports', 'gofumpt' }")
    h.matches(tooling, "go = { 'golangcilint' }")

    local tests = plugin(dofile 'lua/plugins/tests.lua', 'nvim-neotest/neotest')
    local dap_go = plugin(dofile 'lua/plugins/lsp/lang/go.lua', 'leoluz/nvim-dap-go')
    h.truthy(plugin(tests.dependencies or {}, 'nvim-neotest/neotest-go'), 'Neotest-Go is missing')
    h.truthy(dap_go, 'DAP-Go is missing')
    h.equal(dap_go.keys[1].ft, 'go')
  end)

  h.it('gives every standalone plugin an explicit load boundary', function()
    local failures = {}
    with_util_stub(function()
      for _, path in ipairs(all_plugin_modules()) do
        if path ~= 'lua/plugins/init.lua' then
          local ok, specs = xpcall(function()
            return dofile(path)
          end, debug.traceback)
          h.truthy(ok, ('failed to evaluate %s: %s'):format(path, specs))
          if type(specs) == 'table' then
            for _, spec in ipairs(specs) do
              local name = type(spec) == 'table' and (spec[1] or spec.url)
              if name and spec.priority and spec.lazy == true then
                failures[#failures + 1] = ('%s (%s) declares startup priority but remains lazy'):format(name, path)
              end
              if name and not fragment_owners[name] and not spec.optional and not has_trigger(spec) then
                failures[#failures + 1] = ('%s (%s)'):format(name, path)
              end
            end
          end
        end
      end
    end)
    h.deep_equal(failures, {}, 'plugins without explicit load boundaries: ' .. table.concat(failures, ', '))
  end)

  h.it('loads Flutter only for Dart buffers without Dressing', function()
    local flutter = plugin(dofile 'lua/plugins/lsp/lang/flutter.lua', 'nvim-flutter/flutter-tools.nvim')
    h.deep_equal(flutter.ft, { 'dart' })
    h.falsy(flutter.lazy == false)
    h.falsy(plugin(flutter.dependencies or {}, 'stevearc/dressing.nvim'))
    h.truthy(flutter.config, 'Flutter setup must remain enabled')
  end)
end)
