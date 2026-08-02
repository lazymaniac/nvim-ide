local h = require 'tests.headless.harness'

local function plugin(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name or spec.url == name then
      return spec
    end
  end
  error('plugin spec not found: ' .. name)
end

h.describe('Voyager integration', function()
  h.it('loads published main eagerly with complete controls and compatible wrappers', function()
    local voyager = plugin(dofile('lua/plugins/coding.lua'), 'lazymaniac/voyager.nvim')

    h.equal(voyager.branch, 'main')
    h.equal(voyager.version, false)
    h.equal(voyager.lazy, false)
    h.deep_equal(voyager.dependencies, { 'MunifTanjim/nui.nvim' })
    h.deep_equal(voyager.opts, {
      lsp_keymaps = {
        definition = 'gd',
        declaration = false,
        references = 'gr',
        implementation = 'gI',
        type_definition = 'gy',
        incoming_calls = false,
        outgoing_calls = false,
      },
    })

    local actual = {}
    for _, mapping in ipairs(voyager.keys or {}) do
      actual[mapping[1]] = {
        rhs = mapping[2],
        mode = mapping.mode,
        desc = mapping.desc,
      }
    end
    h.deep_equal(actual, {
      ['<leader>vo'] = { rhs = '<cmd>VoyagerOpen<cr>', mode = 'n', desc = 'Open Voyager' },
      ['<leader>vf'] = { rhs = '<cmd>VoyagerFocus<cr>', mode = 'n', desc = 'Focus Voyager' },
      ['<leader>vs'] = { rhs = '<cmd>VoyagerSave<cr>', mode = 'n', desc = 'Save Voyager flow' },
      ['<leader>vl'] = { rhs = '<cmd>VoyagerLoad<cr>', mode = 'n', desc = 'Load Voyager flow' },
      ['<leader>vq'] = { rhs = '<cmd>VoyagerClose<cr>', mode = 'n', desc = 'Close Voyager' },
    })
  end)

  h.it('registers the Voyager which-key group', function()
    local which_key = plugin(dofile('lua/plugins/editor.lua'), 'folke/which-key.nvim')
    local previous = package.loaded['which-key']
    local added
    package.loaded['which-key'] = {
      setup = function() end,
      add = function(spec)
        added = spec
      end,
    }

    local ok, err = xpcall(function()
      which_key.config(nil, which_key.opts)
    end, debug.traceback)
    package.loaded['which-key'] = previous
    if not ok then
      error(err, 0)
    end

    local voyager_group
    for _, mapping in ipairs(added or {}) do
      if mapping[1] == '<leader>v' then
        voyager_group = mapping
        break
      end
    end
    h.deep_equal(voyager_group, { '<leader>v', group = '+[voyager]' })
  end)
end)
