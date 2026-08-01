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

local function mapping(spec, lhs)
  local found = {}
  for _, key in ipairs(spec.keys or {}) do
    if key[1] == lhs then
      found[#found + 1] = key
    end
  end
  return found
end

local function git_specs()
  local previous = package.loaded.util
  package.loaded.util = { safe_keymap_set = function() end }
  local ok, specs = xpcall(function()
    return dofile 'lua/plugins/git.lua'
  end, debug.traceback)
  package.loaded.util = previous
  if not ok then
    error(specs, 0)
  end
  return specs
end

h.describe('Snacks ownership', function()
  h.it('keeps scratch, scroll, and statuscolumn as separate valid modules', function()
    local snacks = plugin(dofile 'lua/plugins/snacks.lua', 'folke/snacks.nvim')
    h.truthy(type(snacks.opts.scratch) == 'table')
    h.truthy(type(snacks.opts.scroll) == 'table')
    h.truthy(type(snacks.opts.statuscolumn) == 'table')
    for _, scratch_field in ipairs { 'name', 'ft', 'icon', 'root', 'autowrite', 'filekey', 'win', 'win_by_ft' } do
      h.falsy(snacks.opts.scroll[scratch_field], 'scroll contains scratch field ' .. scratch_field)
    end
  end)

  h.it('declares each picker mapping once', function()
    local snacks = plugin(dofile 'lua/plugins/snacks.lua', 'folke/snacks.nvim')
    h.equal(#mapping(snacks, '<leader>sb'), 1)
  end)

  h.it('bounds default file sources and makes all-files search explicit', function()
    local snacks = plugin(dofile 'lua/plugins/snacks.lua', 'folke/snacks.nvim')
    local sources = snacks.opts.picker.sources
    h.falsy(sources.files.ignored)
    h.falsy(sources.files.follow)
    h.falsy(sources.explorer.ignored)
    h.falsy(sources.explorer.follow)

    local all_files = mapping(snacks, '<leader>sF')
    h.equal(#all_files, 1)
    h.matches(all_files[1].desc, 'All Files')
    local previous_snacks = _G.Snacks
    local all_files_options
    _G.Snacks = {
      picker = {
        files = function(opts) all_files_options = opts end,
      },
    }
    local ok, err = xpcall(all_files[1][2], debug.traceback)
    _G.Snacks = previous_snacks
    if not ok then error(err, 0) end
    h.deep_equal(all_files_options, { hidden = true, ignored = true, follow = false })
  end)

  h.it('keeps the ordinary shell and Zellij on separate mappings', function()
    local previous_external = package.loaded['util.external']
    local previous_snacks = _G.Snacks
    local ordinary_calls, zellij_calls = 0, 0
    package.loaded['util.external'] = {
      terminal = function(action)
        return function()
          if action.id == 'zellij' then zellij_calls = zellij_calls + 1 end
        end
      end,
    }
    _G.Snacks = {
      terminal = function() ordinary_calls = ordinary_calls + 1 end,
    }

    local ok, err = xpcall(function()
      local snacks = plugin(dofile 'lua/plugins/snacks.lua', 'folke/snacks.nvim')
      local shell = mapping(snacks, '<c-/>')
      local zellij = mapping(snacks, '<leader>lz')
      h.equal(#shell, 1)
      h.equal(#zellij, 1)
      shell[1][2]()
      zellij[1][2]()
    end, debug.traceback)

    package.loaded['util.external'] = previous_external
    _G.Snacks = previous_snacks
    if not ok then error(err, 0) end
    h.equal(ordinary_calls, 1)
    h.equal(zellij_calls, 1)
  end)

  h.it('keeps Gitsigns and Unified on distinct mappings', function()
    local git = git_specs()
    local unified = plugin(git, 'axkirillov/unified.nvim')
    h.equal(unified.keys[1][1], '<leader>gU')
    h.falsy(unified.keys[1][1] == '<leader>gd')
  end)

  h.it('gates external terminals and reports actionable missing tools', function()
    package.loaded['util.external'] = nil
    local external = require 'util.external'
    local toggled
    local notifications = {}
    local run = external.terminal({ id = 'missing-tui', command = { 'missing-tui', '--flag' } }, {
      executable = function()
        return 0
      end,
      notify = function(message, level)
        notifications[#notifications + 1] = { message = message, level = level }
      end,
      toggle = function(command)
        toggled = command
      end,
    })
    h.falsy(run())
    h.falsy(toggled)
    h.equal(#notifications, 1)
    h.matches(notifications[1].message, 'missing-tui')
    h.matches(notifications[1].message, ':checkhealth nv_ide')
    h.equal(notifications[1].level, vim.log.levels.WARN)

    local command
    run = external.terminal({ id = 'available-tui', command = { 'available-tui', '--flag' } }, {
      executable = function()
        return 1
      end,
      notify = function()
        error 'must not notify for available tools'
      end,
      toggle = function(value)
        command = value
      end,
    })
    h.truthy(run())
    h.deep_equal(command, { 'available-tui', '--flag' })
  end)

  h.it('opens mapped external terminals with the default adapters', function()
    local previous_external = package.loaded['util.external']
    local previous_snacks = _G.Snacks
    local previous_executable = vim.fn.executable
    local toggled

    local ok, failure = xpcall(function()
      package.loaded['util.external'] = nil
      vim.fn.executable = function(command)
        h.equal(command, 'python3')
        return 1
      end
      _G.Snacks = {
        terminal = {
          toggle = function(command)
            toggled = command
          end,
        },
      }

      local snacks = plugin(dofile 'lua/plugins/snacks.lua', 'folke/snacks.nvim')
      local terminals = mapping(snacks, '<leader>lp')
      h.equal(#terminals, 1)
      local invoked, invoke_error = pcall(terminals[1][2])
      h.truthy(invoked, tostring(invoke_error))
      h.deep_equal(toggled, { 'python3' })
    end, debug.traceback)

    package.loaded['util.external'] = previous_external
    _G.Snacks = previous_snacks
    vim.fn.executable = previous_executable
    if not ok then
      error(failure, 0)
    end
  end)

  h.it('contains deliberate overrides instead of a copied default schema', function()
    local lines = vim.fn.readfile 'lua/plugins/snacks.lua'
    h.truthy(#lines < 700, ('Snacks config still contains %d lines of copied schema'):format(#lines))
    local snacks = plugin(dofile 'lua/plugins/snacks.lua', 'folke/snacks.nvim')
    h.falsy(snacks.opts.toggle, 'default toggle schema should not be copied locally')
    h.falsy(snacks.opts.animate, 'default animate schema should not be copied locally')
  end)

  h.it('leaves statuscolumn ownership exclusively to Snacks', function()
    local options = read 'lua/config/options.lua'
    local ui = read 'lua/util/ui.lua'
    h.falsy(options:find('vim.opt.statuscolumn', 1, true))
    h.falsy(ui:find('function M.statuscolumn', 1, true))
    h.falsy(ui:find('function M.get_signs', 1, true))
    h.falsy(ui:find('function M.get_mark', 1, true))
  end)
end)
