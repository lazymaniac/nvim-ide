-- LSP progress notification
local progress = vim.defaulttable()
vim.api.nvim_create_autocmd('LspProgress', {
  ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local value = ev.data.params.value --[[@as {percentage?: number, title?: string, message?: string, kind: "begin" | "report" | "end"}]]
    if not client or type(value) ~= 'table' then
      return
    end
    local p = progress[client.id]

    for i = 1, #p + 1 do
      if i == #p + 1 or p[i].token == ev.data.params.token then
        p[i] = {
          token = ev.data.params.token,
          msg = ('[%3d%%] %s%s'):format(
            value.kind == 'end' and 100 or value.percentage or 100,
            value.title or '',
            value.message and (' **%s**'):format(value.message) or ''
          ),
          done = value.kind == 'end',
        }
        break
      end
    end

    local msg = {} ---@type string[]
    progress[client.id] = vim.tbl_filter(function(v)
      return table.insert(msg, v.msg) or not v.done
    end, p)

    local spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }
    vim.notify(table.concat(msg, '\n'), 'info', {
      id = 'lsp_progress',
      title = client.name,
      opts = function(notif)
        notif.icon = #progress[client.id] == 0 and ' ' or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
      end,
    })
  end,
})

return {

  -- [[ UI ENHANCEMENTS ]] ---------------------------------------------------------------
  --
  -- -- [ui] - UI enhancements like buffer line, status line, term support, lsp signature etc.
  -- see: `:h nvui`
  -- link: https://github.com/NvChad/ui
  {
    'nvchad/ui',
    config = function()
      require 'nvchad'
    end,
  },

  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      terminal = {
        win = {
          position = 'float',
        },
      },
      bigfile = { enabled = true },
      dashboard = {
        width = 80,
        row = nil, -- dashboard position. nil for center
        col = nil, -- dashboard position. nil for center
        pane_gap = 4, -- empty columns between vertical panes
        autokeys = '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ', -- autokey sequence
        -- These settings are used by some built-in sections
        preset = {
          -- Used by the `keys` section to show keymaps.
          -- Set your custom keymaps here.
          -- When using a function, the `items` argument are the default keymaps.
          keys = {
            { icon = ' ', key = 'f', desc = 'Find File', action = ":lua Snacks.dashboard.pick('files')" },
            { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
            { icon = ' ', key = 'g', desc = 'Find Text', action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = ' ', key = 'r', desc = 'Recent Files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = ' ', key = 's', desc = 'Restore Session', section = 'session' },
            { icon = '󰒲 ', key = 'l', desc = 'Lazy', action = ':Lazy update', enabled = package.loaded.lazy ~= nil },
            { icon = '󱊓 ', key = 'm', desc = 'Mason', action = ':Mason', enabled = package.loaded.lazy ~= nil },
            { icon = ' ', key = 'L', desc = 'Leetcode', action = ':Leet' },
            { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
          },
          -- Used by the `header` section
          header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
        },
        -- item field formatters
        sections = {
          { section = 'header' },
          {
            pane = 2,
            section = 'terminal',
            cmd = 'colorscript -e square',
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
              return Snacks.git.get_root() ~= nil
            end,
            cmd = 'git status --short --branch --renames',
            height = 5,
            padding = 1,
            ttl = 5 * 60,
            indent = 3,
          },
          { section = 'startup' },
        },
      },
      explorer = { replace_netrw = true },
      indent = { enabled = true },
      input = { enabled = true },
      lazygit = {
        configure = true,
        -- extra configuration for lazygit that will be merged with the default
        -- snacks does NOT have a full yaml parser, so if you need `"test"` to appear with the quotes
        -- you need to double quote it: `"\"test\""`
        config = {
          os = { editPreset = 'nvim-remote' },
          gui = {
            -- set to an empty string "" to disable icons
            nerdFontsVersion = '3',
          },
        },
        theme_path = vim.fs.normalize(vim.fn.stdpath 'cache' .. '/lazygit-theme.yml'),
        -- Theme for lazygit
        theme = {
          [241] = { fg = 'Special' },
          activeBorderColor = { fg = 'MatchParen', bold = true },
          cherryPickedCommitBgColor = { fg = 'Identifier' },
          cherryPickedCommitFgColor = { fg = 'Function' },
          defaultFgColor = { fg = 'Normal' },
          inactiveBorderColor = { fg = 'FloatBorder' },
          optionsTextColor = { fg = 'Function' },
          searchingActiveBorderColor = { fg = 'MatchParen', bold = true },
          selectedLineBgColor = { bg = 'Visual' }, -- set to `default` to have no background colour
          unstagedChangesColor = { fg = 'DiagnosticError' },
        },
        win = {
          style = 'lazygit',
        },
      },
      notifier = {
        enabled = true,
        timeout = 3000,
      },
      picker = {
        prompt = ' ',
        sources = {
          explorer = {
            finder = 'explorer',
            sort = { fields = { 'sort' } },
            supports_live = true,
            tree = true,
            watch = true,
            diagnostics = true,
            diagnostics_open = false,
            git_status = true,
            git_status_open = false,
            follow_file = true,
            focus = 'list',
            auto_close = true,
            jump = { close = false },
            layout = { preset = 'sidebar', preview = false, layout = { position = 'right' } },
            formatters = {
              file = { filename_only = true },
              severity = { pos = 'right' },
            },
            matcher = { sort_empty = false, fuzzy = false },
            config = function(opts)
              return require('snacks.picker.source.explorer').setup(opts)
            end,
            win = {
              list = {
                keys = {
                  ['<BS>'] = 'explorer_up',
                  ['l'] = 'confirm',
                  ['h'] = 'explorer_close', -- close directory
                  ['a'] = 'explorer_add',
                  ['d'] = 'explorer_del',
                  ['r'] = 'explorer_rename',
                  ['c'] = 'explorer_copy',
                  ['m'] = 'explorer_move',
                  ['o'] = 'explorer_open', -- open with system application
                  ['P'] = 'toggle_preview',
                  ['y'] = 'explorer_yank',
                  ['u'] = 'explorer_update',
                  ['<c-c>'] = 'tcd',
                  ['.'] = 'explorer_focus',
                  ['I'] = 'toggle_ignored',
                  ['H'] = 'toggle_hidden',
                  ['Z'] = 'explorer_close_all',
                  [']g'] = 'explorer_git_next',
                  ['[g'] = 'explorer_git_prev',
                },
              },
            },
          },
          projects = {
            finder = 'recent_projects',
            format = 'file',
            dev = { '~/dev', '~/workspace' },
            confirm = 'load_session',
            patterns = { '.git', '_darcs', '.hg', '.bzr', '.svn', 'package.json', 'Makefile' },
            recent = true,
            matcher = {
              frecency = true, -- use frecency boosting
              sort_empty = true, -- sort even when the filter is empty
              cwd_bonus = false,
            },
            sort = { fields = { 'score:desc', 'idx' } },
            win = {
              preview = { minimal = true },
              input = {
                keys = {
                  -- every action will always first change the cwd of the current tabpage to the project
                  ['<c-e>'] = { { 'tcd', 'picker_explorer' }, mode = { 'n', 'i' } },
                  ['<c-f>'] = { { 'tcd', 'picker_files' }, mode = { 'n', 'i' } },
                  ['<c-g>'] = { { 'tcd', 'picker_grep' }, mode = { 'n', 'i' } },
                  ['<c-r>'] = { { 'tcd', 'picker_recent' }, mode = { 'n', 'i' } },
                  ['<c-w>'] = { { 'tcd' }, mode = { 'n', 'i' } },
                  ['<c-t>'] = {
                    function(picker)
                      vim.cmd 'tabnew'
                      Snacks.notify 'New tab opened'
                      picker:close()
                      Snacks.picker.projects()
                    end,
                    mode = { 'n', 'i' },
                  },
                },
              },
            },
          },
        },
        focus = 'input',
        layout = {
          cycle = true,
          --- Use the default layout or vertical if the window is too narrow
          preset = function()
            return vim.o.columns >= 120 and 'default' or 'vertical'
          end,
        },
        ---@class snacks.picker.matcher.Config
        matcher = {
          fuzzy = true, -- use fuzzy matching
          smartcase = true, -- use smartcase
          ignorecase = true, -- use ignorecase
          sort_empty = false, -- sort results when the search string is empty
          filename_bonus = true, -- give bonus for matching file names (last part of the path)
          file_pos = true, -- support patterns like `file:line:col` and `file:line`
          -- the bonusses below, possibly require string concatenation and path normalization,
          -- so this can have a performance impact for large lists and increase memory usage
          cwd_bonus = true, -- give bonus for matching files in the cwd
          frecency = false, -- frecency bonus
          history_bonus = false, -- give more weight to chronological order
        },
        sort = {
          -- default sort is by score, text length and index
          fields = { 'score:desc', '#text', 'idx' },
        },
        ui_select = true, -- replace `vim.ui.select` with the snacks picker
        ---@class snacks.picker.formatters.Config
        formatters = {
          file = {
            filename_first = true, -- display filename before the file path
            truncate = 40, -- truncate the file path to (roughly) this length
            filename_only = false, -- only show the filename
          },
          selected = {
            show_always = true, -- only show the selected column when there are multiple selections
            unselected = true, -- use the unselected icon for unselected items
          },
          severity = {
            icons = true, -- show severity icons
            level = false, -- show severity level
            ---@type "left"|"right"
            pos = 'left', -- position of the diagnostics
          },
        },
        ---@class snacks.picker.previewers.Config
        previewers = {
          git = {
            native = false, -- use native (terminal) or Neovim for previewing git diffs and commits
          },
          file = {
            max_size = 1024 * 1024, -- 1MB
            max_line_length = 500, -- max line length
            ft = nil, ---@type string? filetype for highlighting. Use `nil` for auto detect
          },
          man_pager = nil, ---@type string? MANPAGER env to use for `man` preview
        },
        ---@class snacks.picker.jump.Config
        jump = {
          jumplist = true, -- save the current position in the jumplist
          tagstack = false, -- save the current position in the tagstack
          reuse_win = false, -- reuse an existing window if the buffer is already open
          close = true, -- close the picker when jumping/editing to a location (defaults to true)
          match = false, -- jump to the first match position. (useful for `lines`)
        },
        toggles = {
          follow = 'f',
          hidden = 'h',
          ignored = 'i',
          modified = 'm',
          regex = { icon = 'R', value = false },
        },
        win = {
          -- input window
          input = {
            keys = {
              -- to close the picker on ESC instead of going to normal mode,
              -- add the following keymap to your config
              -- ["<Esc>"] = { "close", mode = { "n", "i" } },
              ['/'] = 'toggle_focus',
              ['<C-Down>'] = { 'history_forward', mode = { 'i', 'n' } },
              ['<C-Up>'] = { 'history_back', mode = { 'i', 'n' } },
              ['<C-c>'] = { 'close', mode = 'i' },
              ['<C-w>'] = { '<c-s-w>', mode = { 'i' }, expr = true, desc = 'delete word' },
              ['<CR>'] = { 'confirm', mode = { 'n', 'i' } },
              ['<Down>'] = { 'list_down', mode = { 'i', 'n' } },
              ['<Esc>'] = 'close',
              ['<S-CR>'] = { { 'pick_win', 'jump' }, mode = { 'n', 'i' } },
              ['<S-Tab>'] = { 'select_and_prev', mode = { 'i', 'n' } },
              ['<Tab>'] = { 'select_and_next', mode = { 'i', 'n' } },
              ['<Up>'] = { 'list_up', mode = { 'i', 'n' } },
              ['<a-d>'] = { 'inspect', mode = { 'n', 'i' } },
              ['<a-f>'] = { 'toggle_follow', mode = { 'i', 'n' } },
              ['<a-h>'] = { 'toggle_hidden', mode = { 'i', 'n' } },
              ['<a-i>'] = { 'toggle_ignored', mode = { 'i', 'n' } },
              ['<a-m>'] = { 'toggle_maximize', mode = { 'i', 'n' } },
              ['<a-p>'] = { 'toggle_preview', mode = { 'i', 'n' } },
              ['<a-w>'] = { 'cycle_win', mode = { 'i', 'n' } },
              ['<c-a>'] = { 'select_all', mode = { 'n', 'i' } },
              ['<c-b>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
              ['<c-d>'] = { 'list_scroll_down', mode = { 'i', 'n' } },
              ['<c-f>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },
              ['<c-g>'] = { 'toggle_live', mode = { 'i', 'n' } },
              ['<c-j>'] = { 'list_down', mode = { 'i', 'n' } },
              ['<c-k>'] = { 'list_up', mode = { 'i', 'n' } },
              ['<c-n>'] = { 'list_down', mode = { 'i', 'n' } },
              ['<c-p>'] = { 'list_up', mode = { 'i', 'n' } },
              ['<c-q>'] = { 'qflist', mode = { 'i', 'n' } },
              ['<c-s>'] = { 'edit_split', mode = { 'i', 'n' } },
              ['<c-u>'] = { 'list_scroll_up', mode = { 'i', 'n' } },
              ['<c-v>'] = { 'edit_vsplit', mode = { 'i', 'n' } },
              ['<c-z>h'] = { 'layout_left', mode = { 'i', 'n' } },
              ['<c-z><c-h>'] = { 'layout_left', mode = { 'i', 'n' } },
              ['<c-z>j'] = { 'layout_bottom', mode = { 'i', 'n' } },
              ['<c-z><c-j>'] = { 'layout_bottom', mode = { 'i', 'n' } },
              ['<c-z>k'] = { 'layout_top', mode = { 'i', 'n' } },
              ['<c-z><c-k>'] = { 'layout_top', mode = { 'i', 'n' } },
              ['<c-z>l'] = { 'layout_right', mode = { 'i', 'n' } },
              ['<c-z><c-l>'] = { 'layout_right', mode = { 'i', 'n' } },
              ['?'] = 'toggle_help_input',
              ['G'] = 'list_bottom',
              ['gg'] = 'list_top',
              ['j'] = 'list_down',
              ['k'] = 'list_up',
              ['q'] = 'close',
            },
            b = {
              minipairs_disable = true,
            },
          },
          -- result list window
          list = {
            keys = {
              ['/'] = 'toggle_focus',
              ['<2-LeftMouse>'] = 'confirm',
              ['<CR>'] = 'confirm',
              ['<Down>'] = 'list_down',
              ['<Esc>'] = 'close',
              ['<S-CR>'] = { { 'pick_win', 'jump' } },
              ['<S-Tab>'] = { 'select_and_prev', mode = { 'n', 'x' } },
              ['<Tab>'] = { 'select_and_next', mode = { 'n', 'x' } },
              ['<Up>'] = 'list_up',
              ['<a-d>'] = 'inspect',
              ['<a-f>'] = 'toggle_follow',
              ['<a-h>'] = 'toggle_hidden',
              ['<a-i>'] = 'toggle_ignored',
              ['<a-m>'] = 'toggle_maximize',
              ['<a-p>'] = 'toggle_preview',
              ['<a-w>'] = 'cycle_win',
              ['<c-a>'] = 'select_all',
              ['<c-b>'] = 'preview_scroll_up',
              ['<c-d>'] = 'list_scroll_down',
              ['<c-f>'] = 'preview_scroll_down',
              ['<c-j>'] = 'list_down',
              ['<c-k>'] = 'list_up',
              ['<c-n>'] = 'list_down',
              ['<c-p>'] = 'list_up',
              ['<c-s>'] = 'edit_split',
              ['<c-u>'] = 'list_scroll_up',
              ['<c-v>'] = 'edit_vsplit',
              ['<c-z>h'] = { 'layout_left', mode = { 'i', 'n' } },
              ['<c-z><c-h>'] = { 'layout_left', mode = { 'i', 'n' } },
              ['<c-z>j'] = { 'layout_bottom', mode = { 'i', 'n' } },
              ['<c-z><c-j>'] = { 'layout_bottom', mode = { 'i', 'n' } },
              ['<c-z>k'] = { 'layout_top', mode = { 'i', 'n' } },
              ['<c-z><c-k>'] = { 'layout_top', mode = { 'i', 'n' } },
              ['<c-z>l'] = { 'layout_right', mode = { 'i', 'n' } },
              ['<c-z><c-l>'] = { 'layout_right', mode = { 'i', 'n' } },
              ['?'] = 'toggle_help_list',
              ['G'] = 'list_bottom',
              ['gg'] = 'list_top',
              ['i'] = 'focus_input',
              ['j'] = 'list_down',
              ['k'] = 'list_up',
              ['q'] = 'close',
              ['zb'] = 'list_scroll_bottom',
              ['zt'] = 'list_scroll_top',
              ['zz'] = 'list_scroll_center',
            },
            wo = {
              conceallevel = 2,
              concealcursor = 'nvc',
            },
          },
          -- preview window
          preview = {
            keys = {
              ['<Esc>'] = 'close',
              ['q'] = 'close',
              ['i'] = 'focus_input',
              ['<ScrollWheelDown>'] = 'list_scroll_wheel_down',
              ['<ScrollWheelUp>'] = 'list_scroll_wheel_up',
              ['<a-w>'] = 'cycle_win',
            },
          },
        },
      },
      quickfile = { enabled = true },
      scope = { enabled = true },
      scroll = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      styles = {
        notification = {
          -- wo = { wrap = true } -- Wrap notifications
        },
      },
    },
    -- stylua: ignore
    keys = {
      -- Top Pickers & Explorer
      { '<leader><space>', function() Snacks.picker.smart() end, desc = 'Smart Find Files' },
      { '<leader>,', function() Snacks.picker.buffers() end, desc = 'Buffers' },
      { '<leader>/', function() Snacks.picker.grep() end, desc = 'Grep' },
      { '<leader>:', function() Snacks.picker.command_history() end, desc = 'Command History' },
      { '<leader>sN', function() Snacks.picker.notifications() end, desc = 'Notification History' },
      { '<leader>e', function() Snacks.explorer() end, desc = 'File Explorer' },
      -- find
      { '<leader>fb', function() Snacks.picker.buffers() end, desc = 'Buffers' },
      { '<leader>fc', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, desc = 'Find Config File' },
      { '<leader>ff', function() Snacks.picker.files() end, desc = 'Find Files' },
      { '<leader>fg', function() Snacks.picker.git_files() end, desc = 'Find Git Files' },
      { '<leader>fp', function() Snacks.picker.projects() end, desc = 'Projects' },
      { '<leader>fr', function() Snacks.picker.recent() end, desc = 'Recent' },
      -- git
      { '<leader>gb', function() Snacks.picker.git_branches() end, desc = 'Git Branches' },
      { '<leader>gl', function() Snacks.picker.git_log() end, desc = 'Git Log' },
      { '<leader>gL', function() Snacks.picker.git_log_line() end, desc = 'Git Log Line' },
      { '<leader>gs', function() Snacks.picker.git_status() end, desc = 'Git Status' },
      { '<leader>gS', function() Snacks.picker.git_stash() end, desc = 'Git Stash' },
      { '<leader>gd', function() Snacks.picker.git_diff() end, desc = 'Git Diff (Hunks)' },
      { '<leader>gf', function() Snacks.picker.git_log_file() end, desc = 'Git Log File' },
      -- Grep
      { '<leader>sb', function() Snacks.picker.lines() end, desc = 'Buffer Lines' },
      { '<leader>sB', function() Snacks.picker.grep_buffers() end, desc = 'Grep Open Buffers' },
      { '<leader>sg', function() Snacks.picker.grep() end, desc = 'Grep' },
      { '<leader>sw', function() Snacks.picker.grep_word() end, desc = 'Visual selection or word', mode = { 'n', 'x' } },
      -- search
      { '<leader>p', function() Snacks.picker.registers() end, desc = 'Registers' },
      { '<leader>s/', function() Snacks.picker.search_history() end, desc = 'Search History' },
      { '<leader>sa', function() Snacks.picker.autocmds() end, desc = 'Autocmds' },
      { '<leader>sb', function() Snacks.picker.lines() end, desc = 'Buffer Lines' },
      { '<leader>sc', function() Snacks.picker.command_history() end, desc = 'Command History' },
      { '<leader>sC', function() Snacks.picker.commands() end, desc = 'Commands' },
      { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = 'Diagnostics' },
      { '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, desc = 'Buffer Diagnostics' },
      { '<leader>sh', function() Snacks.picker.help() end, desc = 'Help Pages' },
      { '<leader>sH', function() Snacks.picker.highlights() end, desc = 'Highlights' },
      { '<leader>si', function() Snacks.picker.icons() end, desc = 'Icons' },
      { '<leader>sj', function() Snacks.picker.jumps() end, desc = 'Jumps' },
      { '<leader>sk', function() Snacks.picker.keymaps() end, desc = 'Keymaps' },
      { '<leader>sl', function() Snacks.picker.loclist() end, desc = 'Location List' },
      { '<leader>sm', function() Snacks.picker.marks() end, desc = 'Marks' },
      { '<leader>sM', function() Snacks.picker.man() end, desc = 'Man Pages' },
      { '<leader>sp', function() Snacks.picker.lazy() end, desc = 'Search for Plugin Spec' },
      { '<leader>sq', function() Snacks.picker.qflist() end, desc = 'Quickfix List' },
      { '<leader>sR', function() Snacks.picker.resume() end, desc = 'Resume' },
      { '<leader>su', function() Snacks.picker.undo() end, desc = 'Undo History' },
      { '<leader>uC', function() Snacks.picker.colorschemes() end, desc = 'Colorschemes' },
      -- LSP
      { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition' },
      { 'gD', function() Snacks.picker.lsp_declarations() end, desc = 'Goto Declaration' },
      { 'gr', function() Snacks.picker.lsp_references() end, nowait = true, desc = 'References' },
      { 'gI', function() Snacks.picker.lsp_implementations() end, desc = 'Goto Implementation' },
      { 'gy', function() Snacks.picker.lsp_type_definitions() end, desc = 'Goto T[y]pe Definition' },
      { '<leader>ss', function() Snacks.picker.lsp_symbols() end, desc = 'LSP Symbols' },
      { '<leader>sS', function() Snacks.picker.lsp_workspace_symbols() end, desc = 'LSP Workspace Symbols' },
      -- Other
      { '<leader>z', function() Snacks.zen() end, desc = 'Toggle Zen Mode' },
      { '<leader>Z', function() Snacks.zen.zoom() end, desc = 'Toggle Zoom' },
      { '<leader>.', function() Snacks.scratch() end, desc = 'Toggle Scratch Buffer' },
      { '<leader>S', function() Snacks.scratch.select() end, desc = 'Select Scratch Buffer' },
      { '<leader>sn', function() Snacks.notifier.show_history() end, desc = 'Notification History' },
      { '<leader>bd', function() Snacks.bufdelete() end, desc = 'Delete Buffer' },
      { '<leader>fR', function() Snacks.rename.rename_file() end, desc = 'Rename File' },
      { '<leader>gB', function() Snacks.gitbrowse() end, desc = 'Git Browse', mode = { 'n', 'v' } },
      { '<leader>gg', function() Snacks.lazygit() end, desc = 'Lazygit' },
      { '<leader>un', function() Snacks.notifier.hide() end, desc = 'Dismiss All Notifications' },
      { '<c-/>', function() Snacks.terminal() end, desc = 'Toggle Terminal' },
      { '<c-_>', function() Snacks.terminal() end, desc = 'which_key_ignore' },
      { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Next Reference', mode = { 'n', 't' } },
      { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Prev Reference', mode = { 'n', 't' } },
    },
    init = function()
      vim.api.nvim_create_autocmd('User', {
        pattern = 'VeryLazy',
        callback = function()
          -- Setup some globals for debugging (lazy-loaded)
          _G.dd = function(...)
            Snacks.debug.inspect(...)
          end
          _G.bt = function()
            Snacks.debug.backtrace()
          end
          vim.print = _G.dd -- Override print to use snacks for `:=` command

          -- Create some toggle mappings
          Snacks.toggle.option('spell', { name = 'Spelling' }):map '<leader>us'
          Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
          Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map '<leader>uL'
          Snacks.toggle.diagnostics():map '<leader>ud'
          Snacks.toggle.line_number():map '<leader>ul'
          Snacks.toggle.option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map '<leader>uc'
          Snacks.toggle.treesitter():map '<leader>uT'
          Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):map '<leader>ub'
          Snacks.toggle.inlay_hints():map '<leader>uh'
          Snacks.toggle.indent():map '<leader>ug'
          Snacks.toggle.dim():map '<leader>uD'
        end,
      })
    end,
  },

  -- [bufferline.nvim] - This is what powers fancy-looking tabs, which include filetype icons and close buttons.
  -- see: `:h bufferline`
  -- link: https://github.com/akinsho/bufferline.nvim
  {
    'akinsho/bufferline.nvim',
    branch = 'main',
    event = 'VeryLazy',
    keys = {
      { '<leader>bp', '<Cmd>BufferLineTogglePin<CR>', desc = 'Toggle pin [bp]' },
      { '<leader>bP', '<Cmd>BufferLineGroupClose ungrouped<CR>', desc = 'Delete non-pinned buffers [bP]' },
      { '<leader>bo', '<Cmd>BufferLineCloseOthers<CR>', desc = 'Delete other buffers [bo]' },
      { '<leader>br', '<Cmd>BufferLineCloseRight<CR>', desc = 'Delete buffers to the right [br]' },
      { '<leader>bl', '<Cmd>BufferLineCloseLeft<CR>', desc = 'Delete buffers to the left [bl]' },
      { '<S-h>', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev buffer <S-h>' },
      { '<S-l>', '<cmd>BufferLineCycleNext<cr>', desc = 'Next buffer <S-l>' },
      { '[b', '<cmd>BufferLineCyclePrev<cr>', desc = 'Prev buffer <[b>' },
      { ']b', '<cmd>BufferLineCycleNext<cr>', desc = 'Next buffer <]b>' },
    },
    opts = {
      options = {
        mode = 'buffers', -- Set to "tabs" to only show tabpages instead
        -- style_preset = require('bufferline').style_preset.minimal, -- or style_preset.minimal
        themable = true, --Allows highlight groups to be overridden i.e. sets highlights as default
        numbers = 'ordinal', -- "none" | "ordinal" | "buffer_id" | "both" | function({ ordinal, id, lower, raise }): string,
        close_command = function(n)
          Snacks.bufdelete.delete { buf = n }
        end, -- can be a string | function, see "Mouse actions"
        right_mouse_command = function(n)
          Snacks.bufdelete.delete { buf = n }
        end, -- can be a string | function, see "Mouse actions"
        left_mouse_command = 'buffer %d', -- can be a string | function, see "Mouse actions"
        middle_mouse_command = nil, -- can be a string | function, see "Mouse actions"
        indicator = { style = 'icon', icon = '▎' },
        buffer_close_icon = ' ',
        modified_icon = '●',
        close_icon = ' ',
        left_trunc_marker = ' ',
        right_trunc_marker = ' ',
        max_name_length = 30,
        max_prefix_length = 30, -- prefix used when a buffer is de-duplicated
        truncate_names = true, -- Whether or not tab names should be truncated
        tab_size = 18,
        diagnostics = false, -- | "nvim_lsp" | "coc" | false
        diagnostics_update_in_insert = false,
        color_icons = true, -- Whether or not to add the filetype icon to highlights
        show_buffer_icons = true, -- Disable filetype icons for buffers
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,
        show_duplicate_prefix = true, -- Whether to show duplicate buffer prefix
        persist_buffer_sort = true, -- Whether or not custom sorted buffers should persist
        move_wraps_at_ends = true, -- whether or not the move command "wraps" at the first or last position
        -- can also be a table containing 2 custom separators
        -- [focused and unfocused]. eg: { '|', '|' }
        separator_style = { '|' }, -- 'slant' | 'slope' | 'thick' | 'thin' | { 'any', 'any' },
        enforce_regular_tabs = true,
        always_show_bufferline = false,
        hover = {
          enabled = true,
          delay = 200,
          reveal = { 'close' },
        },
        sort_by = nil, -- 'id' | 'extension' | 'relative_directory' | 'directory' | 'tabs' | function(buffer_a, buffer_b)
        --   -- add custom logic
        -- return buffer_a.modified > buffer_b.modified
        -- end,
        offsets = {
          {
            filetype = 'neo-tree',
            text = 'Explorer',
            highlight = 'Directory',
            text_align = 'left',
          },
        },
      },
    },
    config = function(_, opts)
      require('bufferline').setup(opts)
      -- Fix bufferline when restoring a session
      vim.api.nvim_create_autocmd('BufAdd', {
        callback = function()
          vim.schedule(function()
            ---@diagnostic disable-next-line: undefined-global
            pcall(nvim_bufferline)
          end)
        end,
      })
    end,
  },

  {
    'echasnovski/mini.icons',
    opts = {},
    lazy = true,
    init = function()
      package.preload['nvim-web-devicons'] = function()
        require('mini.icons').mock_nvim_web_devicons()
        return package.loaded['nvim-web-devicons']
      end
    end,
  },

  {
    'VonHeikemen/fine-cmdline.nvim',
    dependencies = {
      { 'MunifTanjim/nui.nvim' },
    },
    keys = {
      {
        ':',
        '<cmd>FineCmdline<cr>',
        mode = { 'n', 'v' },
        desc = 'CMD',
      },
    },
    config = function()
      require('fine-cmdline').setup {
        cmdline = {
          enable_keymaps = true,
          smart_history = true,
          prompt = ': ',
        },
        popup = {
          position = {
            row = '10%',
            col = '50%',
          },
          size = {
            width = '60%',
          },
          border = {
            style = 'rounded',
          },
          win_options = {
            winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
          },
        },
      }
    end,
  },

  -- [nui.nvim] - UI components like popups.
  -- see: `:h nui`
  -- link: https://github.com/MunifTanjim/nui.nvim
  { 'MunifTanjim/nui.nvim', branch = 'main' },

  -- [floating-help.nvim] - Vim help shown in floating popup
  -- see: 'h: floating-help'
  -- link: https://github.com/Tyler-Barham/floating-help.nvim
  {
    'Tyler-Barham/floating-help.nvim',
    branch = 'main',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      { '<F1>', '<cmd>FloatingHelpToggle<cr>', mode = { 'n' }, desc = 'Toggle Floating Help <F1>' },
      { '<F5>', function() require("floating-help").open('t=help', vim.fn.expand("<cword>")) end, mode = { 'n' }, desc = 'Search cword in Help <F5>' },
      { '<F6>', function() require("floating-help").open('t=man', vim.fn.expand("<cword>")) end, mode = { 'n' }, desc = 'Search cwrod in Man <F6>' },
    },
    config = function()
      require('floating-help').setup {
        -- Defaults
        width = 82, -- Whole numbers are columns/rows
        height = 0.99, -- Decimals are a percentage of the editor
        position = 'E', -- NW,N,NW,W,C,E,SW,S,SE (C==center)
        borderchars = { '─', '│', '─', '│', '╭', '╮', '╯', '╰' },
      }
      -- Only replace cmds, not search; only replace the first instance
      local function cmd_abbrev(abbrev, expansion)
        local cmd = 'cabbr ' .. abbrev .. ' <c-r>=(getcmdpos() == 1 && getcmdtype() == ":" ? "' .. expansion .. '" : "' .. abbrev .. '")<CR>'
        vim.cmd(cmd)
      end
      -- Redirect `:h` to `:FloatingHelp`
      cmd_abbrev('h', 'FloatingHelp')
      cmd_abbrev('help', 'FloatingHelp')
      cmd_abbrev('helpc', 'FloatingHelpClose')
      cmd_abbrev('helpclose', 'FloatingHelpClose')
    end,
  },

  -- [numb.nvim] - Show preview of location when jumping to line with `:{number}`
  -- see: `:h numb`
  -- link: https://github.com/nacro90/numb.nvim
  {
    'nacro90/numb.nvim',
    branch = 'master',
    event = 'VeryLazy',
    opts = {
      show_numbers = true, -- Enable 'number' for the window while peeking
      show_cursorline = true, -- Enable 'cursorline' for the window while peeking
      hide_relativenumbers = true, -- Enable turning off 'relativenumber' for the window while peeking
      number_only = false, -- Peek only when the command is only a number instead of when it starts with a number
      centered_peeking = true, -- Peeked line will be centered relative to window
    },
    config = function(_, opts)
      require('numb').setup(opts)
    end,
  },

  -- [nvim-window-picker] - Allows to decide where to split a window from neo-tree
  -- see: `:h window-picker`
  -- link: https://github.com/s1n7ax/nvim-window-picker
  {
    's1n7ax/nvim-window-picker',
    branch = 'main',
    name = 'window-picker',
    event = 'VeryLazy',
    opts = {
      -- type of hints you want to get
      -- following types are supported
      -- 'statusline-winbar' | 'floating-big-letter'
      -- 'statusline-winbar' draw on 'statusline' if possible, if not 'winbar' will be
      -- 'floating-big-letter' draw big letter on a floating window
      -- used
      hint = 'floating-big-letter',
      -- when you go to window selection mode, status bar will show one of
      -- following letters on them so you can use that letter to select the window
      selection_chars = 'FJDKSLA;CMRUEIWOQP',
      -- This section contains picker specific configurations
      picker_config = {
        statusline_winbar_picker = {
          -- You can change the display string in status bar.
          -- It supports '%' printf style. Such as `return char .. ': %f'` to display
          -- buffer file path. See :h 'stl' for details.
          selection_display = function(char)
            return '%=' .. char .. '%='
          end,
          -- whether you want to use winbar instead of the statusline
          -- "always" means to always use winbar,
          -- "never" means to never use winbar
          -- "smart" means to use winbar if cmdheight=0 and statusline if cmdheight > 0
          use_winbar = 'never', -- "always" | "never" | "smart"
        },
        floating_big_letter = {
          -- window picker plugin provides bunch of big letter fonts
          -- fonts will be lazy loaded as they are being requested
          -- additionally, user can pass in a table of fonts in to font
          -- property to use instead
          font = 'ansi-shadow', -- ansi-shadow |
        },
      },
      -- whether to show 'Pick window:' prompt
      show_prompt = true,
      -- prompt message to show to get the user input
      prompt_message = 'Pick window: ',
      -- if you want to manually filter out the windows, pass in a function that
      -- takes two parameters. You should return window ids that should be
      -- included in the selection
      -- EX:-
      -- function(window_ids, filters)
      --    -- folder the window_ids
      --    -- return only the ones you want to include
      --    return {1000, 1001}
      -- end
      filter_func = nil,
      -- following filters are only applied when you are using the default filter
      -- defined by this plugin. If you pass in a function to "filter_func"
      -- property, you are on your own
      filter_rules = {
        -- when there is only one window available to pick from, use that window
        -- without prompting the user to select
        autoselect_one = true,
        -- whether you want to include the window you are currently on to window
        -- selection or not
        include_current_win = false,
        -- filter using buffer options
        bo = {
          -- if the file type is one of following, the window will be ignored
          filetype = { 'NvimTree', 'neo-tree', 'notify' },
          -- if the file type is one of following, the window will be ignored
          buftype = { 'terminal' },
        },
        -- filter using window options
        wo = {},
        -- if the file path contains one of following names, the window
        -- will be ignored
        file_path_contains = {},
        -- if the file name contains one of following names, the window will be
        -- ignored
        file_name_contains = {},
      },
    },
    config = function(_, opts)
      require('window-picker').setup(opts)
    end,
  },

  -- [markview.nvim] - Markdown previever
  -- see: `:h markview.nvim`
  -- link: https://github.com/OXY2DEV/markview.nvim
  {
    'OXY2DEV/markview.nvim',
    lazy = false, -- Recommended
    ft = { 'markdown', 'norg' },
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
  },

  {
    'sphamba/smear-cursor.nvim',
    opts = {
      -- Smear cursor when switching buffers or windows.
      smear_between_buffers = true,
      -- Smear cursor when moving within line or to neighbor lines.
      -- Use `min_horizontal_distance_smear` and `min_vertical_distance_smear` for finer control
      smear_between_neighbor_lines = true,
      -- Draw the smear in buffer space instead of screen space when scrolling
      scroll_buffer_space = true,
      -- Set to `true` if your font supports legacy computing symbols (block unicode symbols).
      -- Smears will blend better on all backgrounds.
      legacy_computing_symbols_support = false,
    },
  },
}
