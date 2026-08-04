local External = require 'util.external'
local manifest = require 'nv_ide.toolchain.manifest'

local actions = {}
for _, action in ipairs(manifest.external_actions) do
  actions[action.id] = action
end

local function terminal(id)
  local action = assert(actions[id], 'unknown external action: ' .. id)
  return External.terminal(action)
end

local function bottom()
  return { preset = 'bottom' }
end

local function grep_directory(case_sensitive)
  return function(_, item)
    if not item then
      return
    end
    local args = {
      '-g',
      '!.git',
      '-g',
      '!node_modules',
      '-g',
      '!dist',
      '-g',
      '!build',
      '-g',
      '!coverage',
      '-g',
      '!.DS_Store',
      '-g',
      '!.docusaurus',
      '-g',
      '!.dart_tool',
    }
    if case_sensitive then
      table.insert(args, 1, '-s')
    end
    Snacks.picker.grep {
      cwd = vim.fn.fnamemodify(item.file, ':p:h'),
      cmd = 'rg',
      args = args,
      show_empty = true,
      hidden = true,
      ignored = true,
      follow = false,
      supports_live = true,
    }
  end
end

local function copy_file_path(_, item)
  if not item then
    return
  end
  local values = {
    BASENAME = vim.fn.fnamemodify(item.file, ':t:r'),
    EXTENSION = vim.fn.fnamemodify(item.file, ':t:e'),
    FILENAME = vim.fn.fnamemodify(item.file, ':t'),
    PATH = item.file,
    ['PATH (CWD)'] = vim.fn.fnamemodify(item.file, ':.'),
    ['PATH (HOME)'] = vim.fn.fnamemodify(item.file, ':~'),
    URI = vim.uri_from_fname(item.file),
  }
  local choices = vim.tbl_filter(function(name)
    return values[name] ~= ''
  end, vim.tbl_keys(values))
  table.sort(choices)
  vim.ui.select(choices, {
    prompt = 'Choose to copy to clipboard:',
    format_item = function(name)
      return ('%s: %s'):format(name, values[name])
    end,
  }, function(choice)
    if not choice then
      return
    end
    vim.fn.setreg('+', values[choice])
    Snacks.notify.info('Yanked `' .. values[choice] .. '`')
  end)
end

local function recursive_toggle(picker, item)
  local Actions = require 'snacks.explorer.actions'
  local Tree = require 'snacks.explorer.tree'
  local node = item and Tree:node(item.file)
  if not node then
    return
  end
  if not node.dir then
    picker:action 'confirm'
    return
  end

  local function toggle(current)
    Tree:toggle(current.path)
    Actions.update(picker, { refresh = true })
    vim.schedule(function()
      local children = vim.tbl_values(current.children or {})
      if #children == 1 and children[1].dir then
        toggle(children[1])
      end
    end)
  end
  toggle(node)
end

local function diff_selected(picker)
  local selected = picker:selected()
  if #selected ~= 2 then
    Snacks.notify.info 'Select exactly two entries for the diff'
    return
  end
  picker:close()
  vim.cmd('tabnew ' .. vim.fn.fnameescape(selected[1].file))
  vim.cmd('vert diffs ' .. vim.fn.fnameescape(selected[2].file))
  Snacks.notify.info(('Diffing %s against %s'):format(selected[1].file, selected[2].file))
end

return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      bigfile = {},
      dashboard = {
        preset = {
          keys = {
            { icon = ' ', key = 'f', desc = 'Find File', action = ":lua Snacks.dashboard.pick('files')" },
            { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
            { icon = ' ', key = 'g', desc = 'Find Text', action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = ' ', key = 'r', desc = 'Recent Files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = ' ', key = 's', desc = 'Restore Session', section = 'session' },
            { icon = '󰒲 ', key = 'l', desc = 'Lazy', action = ':Lazy update', enabled = package.loaded.lazy ~= nil },
            { icon = '󱊓 ', key = 'm', desc = 'Mason', action = ':Mason', enabled = package.loaded.lazy ~= nil },
            { icon = ' ', key = 't', desc = 'Typing', action = ':Typr' },
            { icon = ' ', key = 'S', desc = 'Typing stats', action = ':TyprStats' },
            { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
          },
          header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
        },
        sections = {
          { section = 'header' },
          {
            pane = 2,
            section = 'terminal',
            cmd = 'colorscript -e square',
            enabled = function()
              return vim.fn.executable 'colorscript' == 1
            end,
            height = 5,
            padding = 1,
          },
          { section = 'keys', gap = 1, padding = 1 },
          { pane = 2, icon = ' ', title = 'Recent Files', section = 'recent_files', indent = 2, padding = 1 },
          { pane = 2, icon = ' ', title = 'Projects', section = 'projects', indent = 2, padding = 1 },
          {
            pane = 2,
            icon = ' ',
            title = 'Git Status',
            section = 'terminal',
            enabled = function()
              return vim.fn.executable 'git' == 1 and Snacks.git.get_root() ~= nil
            end,
            cmd = 'git status --short --branch --renames',
            height = 5,
            padding = 1,
            ttl = 300,
            indent = 3,
          },
          { section = 'startup' },
        },
      },
      explorer = { replace_netrw = true },
      gitbrowse = { what = 'commit' },
      image = {
        force = true,
        doc = {
          enabled = true,
          inline = true,
          float = true,
          max_width = 80,
          max_height = 40,
          conceal = function(_, kind)
            return kind == 'math'
          end,
        },
        math = { enabled = true },
      },
      indent = {
        indent = { char = '│' },
        scope = { char = '│' },
      },
      input = {},
      lazygit = {
        config = {
          os = { editPreset = 'nvim-remote' },
          gui = { nerdFontsVersion = '3' },
        },
      },
      notifier = {
        level = vim.log.levels.TRACE,
        style = 'fancy',
      },
      picker = {
        prompt = ' 󱎸 > ',
        ui_select = true,
        layout = {
          preset = function()
            return vim.o.columns >= 120 and 'default' or 'vertical'
          end,
        },
        formatters = {
          file = { filename_first = true, truncate = 40 },
          selected = { show_always = true, unselected = true },
        },
        sources = {
          autocmds = { layout = bottom() },
          buffers = {
            layout = bottom(),
            hidden = false,
            unloaded = true,
            current = true,
            sort_lastused = true,
            win = {
              input = { keys = { ['<c-x>'] = { 'bufdelete', mode = { 'n', 'i' } } } },
              list = { keys = { dd = 'bufdelete' } },
            },
          },
          commands = { layout = bottom() },
          diagnostics = { layout = bottom(), filter = { cwd = true } },
          diagnostics_buffer = { layout = bottom(), filter = { buf = true } },
          explorer = {
            hidden = true,
            ignored = false,
            follow = false,
            auto_close = true,
            layout = { preset = 'sidebar', preview = false, layout = { position = 'right', width = 60 } },
            formatters = { file = { filename_only = true }, severity = { pos = 'right' } },
            matcher = { sort_empty = false, fuzzy = false },
            actions = {
              copy_file_path = { action = copy_file_path },
              search_in_directory = { action = grep_directory(false) },
              search_in_directory_case_sensitive = { action = grep_directory(true) },
              recursive_toggle = recursive_toggle,
              diff = { action = diff_selected },
            },
            win = {
              list = {
                keys = {
                  Y = 'copy_file_path',
                  s = 'search_in_directory',
                  S = 'search_in_directory_case_sensitive',
                  D = 'diff',
                  ['<CR>'] = 'recursive_toggle',
                },
              },
            },
          },
          files = { layout = bottom(), show_empty = true, hidden = true, ignored = false, follow = false },
          git_files = { layout = bottom(), untracked = false, submodules = false },
          grep = { layout = bottom(), regex = true, show_empty = true, live = true },
          grep_buffers = { layout = bottom(), live = true, buffers = true, need_search = false },
          grep_word = { layout = bottom(), regex = false, live = false },
          help = { layout = bottom() },
          highlights = { layout = bottom() },
          jumps = { layout = bottom() },
          keymaps = { layout = bottom(), global = true, ['local'] = true },
          lazy = { layout = bottom() },
          lines = { layout = { preview = 'main', preset = 'ivy' }, jump = { match = true } },
          loclist = { layout = bottom() },
          lsp_declarations = { layout = bottom(), include_current = false, auto_confirm = true },
          lsp_definitions = { layout = bottom(), include_current = false, auto_confirm = true },
          lsp_implementations = { layout = bottom(), include_current = false, auto_confirm = true },
          lsp_references = { layout = bottom(), include_declaration = true, include_current = false, auto_confirm = true },
          lsp_symbols = { layout = { preset = 'right' }, tree = true },
          lsp_type_definitions = { layout = bottom(), include_current = false, auto_confirm = true },
          lsp_workspace_symbols = { layout = bottom() },
          man = { layout = bottom() },
          marks = { layout = bottom() },
          projects = {
            dev = { '~/dev', '~/workspace' },
            confirm = 'load_session',
            matcher = { frecency = true, sort_empty = true, cwd_bonus = false },
            win = {
              preview = { minimal = true },
              input = {
                keys = {
                  ['<c-e>'] = { { 'tcd', 'picker_explorer' }, mode = { 'n', 'i' } },
                  ['<c-f>'] = { { 'tcd', 'picker_files' }, mode = { 'n', 'i' } },
                  ['<c-g>'] = { { 'tcd', 'picker_grep' }, mode = { 'n', 'i' } },
                  ['<c-r>'] = { { 'tcd', 'picker_recent' }, mode = { 'n', 'i' } },
                  ['<c-w>'] = { { 'tcd' }, mode = { 'n', 'i' } },
                },
              },
            },
          },
          qflist = { layout = bottom() },
          recent = {
            layout = bottom(),
            filter = {
              paths = {
                [vim.fn.stdpath 'data'] = false,
                [vim.fn.stdpath 'cache'] = false,
                [vim.fn.stdpath 'state'] = false,
              },
            },
          },
          registers = { layout = bottom() },
          smart = { layout = bottom(), matcher = { cwd_bonus = true, frecency = true, sort_empty = true } },
          undo = {
            layout = bottom(),
            win = {
              preview = { wo = { number = false, relativenumber = false, signcolumn = 'no' } },
              input = {
                keys = {
                  ['<c-y>'] = { 'yank_add', mode = { 'n', 'i' } },
                  ['<c-s-y>'] = { 'yank_del', mode = { 'n', 'i' } },
                },
              },
            },
          },
        },
      },
      quickfile = { exclude = { 'latex' } },
      scope = {},
      scratch = {},
      scroll = {
        animate = { duration = { step = 10, total = 200 } },
        animate_repeat = { delay = 100, duration = { step = 5, total = 50 } },
      },
      statuscolumn = {},
      terminal = { win = { position = 'float' } },
      words = {},
      zen = {},
    },
    -- stylua: ignore
    keys = {
      { '<leader><space>', function() Snacks.picker.smart() end, desc = 'Smart Find Files [ ]' },
      { '<leader>,', function() Snacks.picker.buffers() end, desc = 'Buffers [,]' },
      { '<leader>/', function() Snacks.picker.grep() end, desc = 'Grep [/]' },
      { '<leader>:', function() Snacks.picker.command_history() end, desc = 'Command History [:]' },
      { '<leader>e', function() Snacks.explorer() end, desc = 'File Explorer [e]' },
      { '<leader>gL', function() Snacks.picker.git_log_line() end, desc = 'Git Log Line [gL]' },
      { '<leader>sb', function() Snacks.picker.lines() end, desc = 'Buffer Lines [sb]' },
      { '<leader>sB', function() Snacks.picker.grep_buffers() end, desc = 'Grep Open Buffers [sB]' },
      { '<leader>sw', function() Snacks.picker.grep_word() end, desc = 'Visual selection or word [sw]', mode = { 'n', 'x' } },
      { '<leader>sf', function() Snacks.picker.files() end, desc = 'Find Files [sf]' },
      { '<leader>sF', function() Snacks.picker.files { hidden = true, ignored = true, follow = false } end, desc = 'Find All Files [sF]' },
      { '<leader>sg', function() Snacks.picker.git_files() end, desc = 'Find Git Files [sg]' },
      { '<leader>sp', function() Snacks.picker.projects() end, desc = 'Projects [sp]' },
      { '<leader>sr', function() Snacks.picker.recent() end, desc = 'Recent [sr]' },
      { '<leader>p', function() Snacks.picker.registers() end, desc = 'Registers [p]' },
      { '<leader>s/', function() Snacks.picker.search_history() end, desc = 'Search History [s/]' },
      { '<leader>sc', function() Snacks.picker.command_history() end, desc = 'Command History [sc]' },
      { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = 'Diagnostics [sd]' },
      { '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, desc = 'Buffer Diagnostics [sD]' },
      { '<leader>sl', function() Snacks.picker.loclist() end, desc = 'Location List [sl]' },
      { '<leader>sm', function() Snacks.picker.marks() end, desc = 'Marks [sm]' },
      { '<leader>sq', function() Snacks.picker.qflist() end, desc = 'Quickfix List [sq]' },
      { '<leader>sR', function() Snacks.picker.resume() end, desc = 'Resume [sR]' },
      { '<leader>su', function() Snacks.picker.undo() end, desc = 'Undo History [su]' },
      { '<leader>mf', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, desc = 'Find Config File [mf]' },
      { '<leader>ma', function() Snacks.picker.autocmds() end, desc = 'Autocmds [ma]' },
      { '<leader>mc', function() Snacks.picker.commands() end, desc = 'Commands [mc]' },
      { '<leader>mH', function() Snacks.picker.highlights() end, desc = 'Highlights [mH]' },
      { '<leader>mh', function() Snacks.picker.help() end, desc = 'Help Pages [mh]' },
      { '<leader>mk', function() Snacks.picker.keymaps() end, desc = 'Keymaps [mk]' },
      { '<leader>mI', function() Snacks.picker.icons() end, desc = 'Icons [mI]' },
      { '<leader>mM', function() Snacks.picker.man() end, desc = 'Man Pages [mM]' },
      { '<leader>mj', function() Snacks.picker.jumps() end, desc = 'Jumps [mj]' },
      { '<leader>mp', function() Snacks.picker.lazy() end, desc = 'Search for Plugin Spec [mp]' },
      { '<leader>mC', function() require('nvchad.themes').open() end, desc = 'Colorschemes [mC]' },
      { '<leader>mi', function() Snacks.picker.lsp_config() end, desc = 'LSP Info [mi]' },
      { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition (gd)' },
      { 'gD', function() Snacks.picker.lsp_declarations() end, desc = 'Goto Declaration (gD)' },
      { 'gr', function() Snacks.picker.lsp_references() end, nowait = true, desc = 'References (gr)' },
      { 'gI', function() Snacks.picker.lsp_implementations() end, desc = 'Goto Implementation (gI)' },
      { 'gy', function() Snacks.picker.lsp_type_definitions() end, desc = 'Goto Type Definition (gy)' },
      { '<leader>o', function() Snacks.picker.lsp_symbols() end, desc = 'LSP Symbols [o]' },
      { '<leader>cw', function() Snacks.picker.lsp_workspace_symbols() end, desc = 'LSP Workspace Symbols [cw]' },
      { '<leader>z', function() Snacks.zen() end, desc = 'Toggle Zen Mode [z]' },
      { '<leader>.', function() Snacks.scratch() end, desc = 'Toggle Scratch Buffer [.]' },
      { '<leader>S', function() Snacks.scratch.select() end, desc = 'Select Scratch Buffer [S]' },
      { '<leader>mn', function() Snacks.notifier.show_history() end, desc = 'Notification History [mn]' },
      { '<leader>bd', function() Snacks.bufdelete() end, desc = 'Delete Current Buffer [bd]' },
      { '<leader>bo', function() Snacks.bufdelete.other() end, desc = 'Delete Other Buffers [bo]' },
      { '<leader>cR', function() Snacks.rename.rename_file() end, desc = 'Rename File [cR]' },
      { '<leader>gB', function() Snacks.gitbrowse() end, desc = 'Git Browse [gB]', mode = { 'n', 'v' } },
      { '<leader>gg', function() Snacks.lazygit() end, desc = 'Lazygit [gg]' },
      { '<leader>un', function() Snacks.notifier.hide() end, desc = 'Dismiss All Notifications [un]' },
      { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Next Reference', mode = 'n' },
      { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Prev Reference', mode = 'n' },
      { '<leader>la', terminal('cloudlens'), desc = 'Cloud Resources TUI [la]' },
      { '<leader>lb', terminal('btop'), desc = 'System Monitor TUI [lb]' },
      { '<leader>lc', terminal('nap'), desc = 'Code Snippets TUI [lc]' },
      { '<leader>ld', terminal('podman-tui'), desc = 'Podman TUI [ld]' },
      { '<leader>lD', terminal('lazydocker'), desc = 'Docker TUI [lD]' },
      { '<leader>lg', terminal('glab-tui'), desc = 'GitLab TUI [lg]' },
      { '<leader>lh', terminal('clx'), desc = 'Hacker News TUI [lh]' },
      { '<leader>lj', terminal('euporie-notebook'), desc = 'Jupyter Notebooks TUI [lj]' },
      { '<leader>lk', terminal('tiki'), desc = 'Kanban TUI [lk]' },
      { '<leader>lK', terminal('k9s'), desc = 'Kubernetes TUI [lK]' },
      { '<leader>ln', terminal('termscp'), desc = 'Network Client TUI [ln]' },
      { '<leader>lp', terminal('python3'), desc = 'Python Terminal [lp]' },
      { '<leader>lr', terminal('posting'), desc = 'REST Client TUI [lr]' },
      { '<leader>ls', terminal('harlequin'), desc = 'Database TUI [ls]' },
      { '<leader>lt', terminal('omm'), desc = 'TODO TUI [lt]' },
      { '<leader>lu', terminal('dua'), desc = 'Disk Usage TUI [lu]' },
      { '<leader>lv', terminal('jshell'), desc = 'JShell Terminal [lv]' },
      { '<c-/>', function() Snacks.terminal() end, desc = 'Toggle Terminal (c-/)', mode = { 'n', 't' } },
      { '<a-/>', function() Snacks.terminal() end, desc = 'Toggle Terminal (c-/)', mode = { 'n', 't' } },
      { '<leader>lz', terminal('zellij'), desc = 'Zellij Terminal [lz]' },
      { '<a-z>', terminal('zellij'), desc = 'Zellij Terminal <a-z>' },
    },
    init = function()
      vim.api.nvim_create_autocmd('User', {
        pattern = 'VeryLazy',
        callback = function()
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd

          Snacks.toggle.option('spell', { name = 'Spelling' }):map '<leader>us'
          Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
          Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map '<leader>uL'
          Snacks.toggle.animate():map '<leader>ua'
          Snacks.toggle.diagnostics():map '<leader>ud'
          Snacks.toggle.dim():map '<leader>uD'
          Snacks.toggle.indent():map '<leader>uI'
          Snacks.toggle.line_number():map '<leader>ul'
          Snacks.toggle.option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map '<leader>uc'
          Snacks.toggle.treesitter():map '<leader>uT'
          Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):map '<leader>ub'
          Snacks.toggle.inlay_hints():map '<leader>uh'
          Snacks.toggle.scroll():map '<leader>uS'
          Snacks.toggle.words():map '<leader>uW'
          Snacks.toggle.zoom():map '<leader>uz'
        end,
      })
    end,
  },
}
