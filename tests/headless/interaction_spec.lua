local h = require('tests.headless.harness')

local function plugin(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name or spec.url == name then
      return spec
    end
  end
  error('plugin spec not found: ' .. name)
end

local function includes(values, expected)
  if type(values) == 'string' then
    return values == expected
  end
  for _, value in ipairs(values or {}) do
    if value == expected then
      return true
    end
  end
  return false
end

h.describe('editor interactions', function()
  h.it('activates Leap without intercepting Enter or Backspace', function()
    local leap = plugin(dofile('lua/plugins/search.lua'), 'https://codeberg.org/andyg/leap.nvim')
    local modes = {}
    for _, key in ipairs(leap.keys or {}) do
      modes[key[1]] = key.mode
    end

    h.truthy(includes(modes.s, 'n'), 'Leap s must be active in normal mode')
    h.truthy(includes(modes.s, 'x'), 'Leap s must be active in visual mode')
    h.truthy(includes(modes.s, 'o'), 'Leap s must be active in operator-pending mode')
    h.truthy(includes(modes.S, 'n'), 'Leap S must be active in normal mode')
    h.falsy(includes(modes.S, 'x'), 'Leap S must not reserve visual mode')

    local saved_leap = package.loaded.leap
    local saved_user = package.loaded['leap.user']
    local repeat_keys
    package.loaded.leap = { opts = {} }
    package.loaded['leap.user'] = {
      set_repeat_keys = function(...)
        repeat_keys = { ... }
      end,
    }

    local ok, err = pcall(leap.config)
    package.loaded.leap = saved_leap
    package.loaded['leap.user'] = saved_user
    if not ok then
      error(err, 0)
    end

    h.falsy(repeat_keys, 'Leap must not install global Enter/Backspace repeat mappings')
  end)

  h.it('keeps native quickfix navigation and activation', function()
    local saved_util = package.loaded.util
    local configured = {}
    package.loaded.util = {
      safe_keymap_set = function(mode, lhs)
        configured[#configured + 1] = { mode = mode, lhs = lhs }
      end,
      format = { toggle = function() end },
    }

    local ok, err = pcall(dofile, 'lua/config/keymaps.lua')
    package.loaded.util = saved_util
    if not ok then
      error(err, 0)
    end

    for _, mapping in ipairs(configured) do
      h.falsy(mapping.lhs == '[q' or mapping.lhs == ']q', 'configuration must not replace native quickfix navigation')
    end

    h.equal(vim.fn.maparg('[q', 'n', false, true).desc, ':cprevious')
    h.equal(vim.fn.maparg(']q', 'n', false, true).desc, ':cnext')

    vim.fn.setqflist({ { filename = 'quickfix-entry.txt', lnum = 1, text = 'entry' } })
    vim.cmd.copen()
    h.deep_equal(vim.fn.maparg('<CR>', 'n', false, true), vim.empty_dict(), 'quickfix Enter must remain native')
    vim.cmd.cclose()
  end)

  h.it('installs buffer-local Tree-sitter parent and child selections', function()
    local treesitter = plugin(dofile('lua/plugins/treesitter.lua'), 'nvim-treesitter/nvim-treesitter')
    local saved_dap = package.loaded['nvim-dap-repl-highlights']
    local saved_nts = package.loaded['nvim-treesitter']
    local saved_create_autocmd = vim.api.nvim_create_autocmd
    local saved_create_augroup = vim.api.nvim_create_augroup
    local saved_get_lang = vim.treesitter.language.get_lang
    local saved_add = vim.treesitter.language.add
    local saved_start = vim.treesitter.start
    local saved_select = vim.treesitter.select
    local saved_keymap_set = vim.keymap.set

    local callback
    local mappings = {}
    local selections = {}
    package.loaded['nvim-dap-repl-highlights'] = { setup = function() end }
    package.loaded['nvim-treesitter'] = {
      install = function()
        return {}
      end,
      indentexpr = function()
        return 0
      end,
    }
    vim.api.nvim_create_augroup = function()
      return 1
    end
    vim.api.nvim_create_autocmd = function(_, opts)
      callback = opts.callback
      return 1
    end
    vim.treesitter.language.get_lang = function(filetype)
      return filetype
    end
    vim.treesitter.language.add = function()
      return true
    end
    vim.treesitter.start = function() end
    vim.treesitter.select = function(direction, count)
      selections[#selections + 1] = { direction, count }
    end
    vim.keymap.set = function(mode, lhs, rhs, opts)
      mappings[#mappings + 1] = { mode = mode, lhs = lhs, rhs = rhs, opts = opts }
    end

    local ok, err = xpcall(function()
      treesitter.config(nil, treesitter.opts)
      h.truthy(callback, 'Tree-sitter FileType callback must be registered')
      callback({ buf = vim.api.nvim_get_current_buf(), match = 'lua' })
      for _, mapping in ipairs(mappings) do
        if mapping.lhs == '<C-Space>' or mapping.lhs == '<BS>' then
          mapping.rhs()
        end
      end
    end, debug.traceback)

    package.loaded['nvim-dap-repl-highlights'] = saved_dap
    package.loaded['nvim-treesitter'] = saved_nts
    vim.api.nvim_create_autocmd = saved_create_autocmd
    vim.api.nvim_create_augroup = saved_create_augroup
    vim.treesitter.language.get_lang = saved_get_lang
    vim.treesitter.language.add = saved_add
    vim.treesitter.start = saved_start
    vim.treesitter.select = saved_select
    vim.keymap.set = saved_keymap_set
    if not ok then
      error(err, 0)
    end

    local grow
    local shrink
    for _, mapping in ipairs(mappings) do
      if mapping.lhs == '<C-Space>' then
        grow = mapping
      elseif mapping.lhs == '<BS>' then
        shrink = mapping
      end
    end

    h.truthy(grow, 'Tree-sitter grow mapping is missing')
    h.truthy(includes(grow.mode, 'n'))
    h.truthy(includes(grow.mode, 'x'))
    h.truthy(grow.opts.buffer, 'grow mapping must be buffer-local')
    h.truthy(shrink, 'Tree-sitter shrink mapping is missing')
    h.truthy(includes(shrink.mode, 'x'))
    h.truthy(shrink.opts.buffer, 'shrink mapping must be buffer-local')

    h.deep_equal(selections, { { 'parent', vim.v.count1 }, { 'child', vim.v.count1 } })
  end)

  h.it('separates diagnostic, conditional, and terminal ownership', function()
    local previous_util = package.loaded.util
    local previous_augroup = vim.api.nvim_create_augroup
    local previous_autocmd = vim.api.nvim_create_autocmd
    local previous_keymap = vim.keymap.set
    local previous_cmd = vim.cmd
    local previous_global = _G.set_terminal_keymaps
    local core, mapped, commands = {}, {}, {}
    local registration

    package.loaded.util = {
      safe_keymap_set = function(_, lhs) core[lhs] = true end,
      format = { toggle = function() end },
    }
    vim.api.nvim_create_augroup = function(name, opts)
      h.equal(name, 'nvide_terminal')
      h.deep_equal(opts, { clear = true })
      return 81
    end
    vim.api.nvim_create_autocmd = function(event, opts)
      registration = { event = event, opts = opts }
      return 82
    end
    vim.keymap.set = function(mode, lhs, rhs, opts)
      mapped[#mapped + 1] = { mode = mode, lhs = lhs, rhs = rhs, opts = opts }
    end
    vim.cmd = function(command) commands[#commands + 1] = command end

    local ok, err = xpcall(function()
      dofile 'lua/config/keymaps.lua'
      if registration then registration.opts.callback { buf = 37 } end
    end, debug.traceback)

    package.loaded.util = previous_util
    vim.api.nvim_create_augroup = previous_augroup
    vim.api.nvim_create_autocmd = previous_autocmd
    vim.keymap.set = previous_keymap
    vim.cmd = previous_cmd
    _G.set_terminal_keymaps = previous_global
    if not ok then error(err, 0) end

    local treesitter = plugin(
      dofile('lua/plugins/treesitter.lua'),
      'nvim-treesitter/nvim-treesitter-textobjects'
    )
    local owners = {}
    for lhs in pairs(core) do owners[lhs] = { 'core' } end
    for _, key in ipairs(treesitter.keys or {}) do
      owners[key[1]] = owners[key[1]] or {}
      owners[key[1]][#owners[key[1]] + 1] = 'treesitter'
    end
    h.deep_equal(owners['[d'], { 'core' }, 'conditional motions must not own [d')
    h.deep_equal(owners[']d'], { 'core' }, 'conditional motions must not own ]d')
    h.deep_equal(owners['[C'], { 'treesitter' })
    h.deep_equal(owners[']C'], { 'treesitter' })

    h.truthy(registration, 'terminal mappings must use nvim_create_autocmd')
    h.equal(registration.event, 'TermOpen')
    h.equal(registration.opts.group, 81)
    h.equal(registration.opts.pattern, 'term://*')
    h.equal(#mapped, 6)
    for _, item in ipairs(mapped) do
      h.equal(item.mode, 't')
      h.equal(item.opts.buffer, 37)
    end
    for _, command in ipairs(commands) do
      h.falsy(command:find('autocmd!', 1, true), 'terminal setup must not clear another TermOpen handler')
    end
  end)

  h.it('gives MiniSurround sole ownership of ys, ds, and cs', function()
    local surround = plugin(dofile('lua/plugins/coding.lua'), 'nvim-mini/mini.surround')
    h.deep_equal(surround.opts.mappings, {
      add = 'ys',
      delete = 'ds',
      find = '',
      find_left = '',
      highlight = '',
      replace = 'cs',
      suffix_last = '',
      suffix_next = '',
    })

    local markdown = plugin(dofile('lua/plugins/lsp/lang/markdown.lua'), 'tadmccorkle/markdown.nvim')
    h.equal(markdown.opts.mappings.inline_surround_delete, false)
    h.equal(markdown.opts.mappings.inline_surround_change, false)
  end)
end)
