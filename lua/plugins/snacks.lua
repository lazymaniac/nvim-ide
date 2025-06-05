return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      animate = {
        enabled = true,
      },
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
          pick = nil,
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
            { icon = ' ', key = 't', desc = 'Typing', action = ':Typr' },
            { icon = ' ', key = 'S', desc = 'Typing stats', action = ':TyprStats' },
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
      gitbrowse = {
        enabled = true,
      },
      image = {
        enabled = true,
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
          autocmds = {
            finder = 'vim_autocmds',
            format = 'autocmd',
            preview = 'preview',
          },
          buffers = {
            finder = 'buffers',
            format = 'buffer',
            hidden = true,
            unloaded = true,
            current = true,
            sort_lastused = true,
            win = {
              input = {
                keys = {
                  ['<c-x>'] = { 'bufdelete', mode = { 'n', 'i' } },
                },
              },
              list = { keys = { ['dd'] = 'bufdelete' } },
            },
          },
          cliphist = {
            finder = 'system_cliphist',
            format = 'text',
            preview = 'preview',
            confirm = { 'copy', 'close' },
          },
          colorschemes = {
            finder = 'vim_colorschemes',
            format = 'text',
            preview = 'colorscheme',
            preset = 'vertical',
            confirm = function(picker, item)
              picker:close()
              if item then
                picker.preview.state.colorscheme = nil
                vim.schedule(function()
                  vim.cmd('colorscheme ' .. item.text)
                end)
              end
            end,
          },
          command_history = {
            finder = 'vim_history',
            name = 'cmd',
            format = 'text',
            preview = 'none',
            layout = {
              preset = 'vscode',
            },
            confirm = 'cmd',
            formatters = { text = { ft = 'vim' } },
          },
          commands = {
            finder = 'vim_commands',
            format = 'command',
            preview = 'preview',
            confirm = 'cmd',
          },
          diagnostics = {
            finder = 'diagnostics',
            format = 'diagnostic',
            sort = {
              fields = {
                'is_current',
                'is_cwd',
                'severity',
                'file',
                'lnum',
              },
            },
            matcher = { sort_empty = true },
            -- only show diagnostics from the cwd by default
            filter = { cwd = true },
          },
          diagnostics_buffer = {
            finder = 'diagnostics',
            format = 'diagnostic',
            sort = {
              fields = { 'severity', 'file', 'lnum' },
            },
            matcher = { sort_empty = true },
            filter = { buf = true },
          },
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
            hidden = true,
            ignored = true,
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
            actions = {
              copy_file_path = {
                action = function(_, item)
                  if not item then
                    return
                  end
                  local vals = {
                    ['BASENAME'] = vim.fn.fnamemodify(item.file, ':t:r'),
                    ['EXTENSION'] = vim.fn.fnamemodify(item.file, ':t:e'),
                    ['FILENAME'] = vim.fn.fnamemodify(item.file, ':t'),
                    ['PATH'] = item.file,
                    ['PATH (CWD)'] = vim.fn.fnamemodify(item.file, ':.'),
                    ['PATH (HOME)'] = vim.fn.fnamemodify(item.file, ':~'),
                    ['URI'] = vim.uri_from_fname(item.file),
                  }
                  local options = vim.tbl_filter(function(val)
                    return vals[val] ~= ''
                  end, vim.tbl_keys(vals))
                  if vim.tbl_isempty(options) then
                    vim.notify('No values to copy', vim.log.levels.WARN)
                    return
                  end
                  table.sort(options)
                  vim.ui.select(options, {
                    prompt = 'Choose to copy to clipboard:',
                    format_item = function(list_item)
                      return ('%s: %s'):format(list_item, vals[list_item])
                    end,
                  }, function(choice)
                    local result = vals[choice]
                    if result then
                      vim.fn.setreg('+', result)
                      Snacks.notify.info('Yanked `' .. result .. '`')
                    end
                  end)
                end,
              },
              search_in_directory = {
                action = function(_, item)
                  if not item then
                    return
                  end
                  local dir = vim.fn.fnamemodify(item.file, ':p:h')
                  Snacks.picker.grep {
                    cwd = dir,
                    cmd = 'rg',
                    args = {
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
                    },
                    show_empty = true,
                    hidden = true,
                    ignored = true,
                    follow = false,
                    supports_live = true,
                  }
                end,
              },
              search_in_directory_case_sensitive = {
                action = function(_, item)
                  if not item then
                    return
                  end
                  local dir = vim.fn.fnamemodify(item.file, ':p:h')
                  Snacks.picker.grep {
                    cwd = dir,
                    cmd = 'rg',
                    args = {
                      '-s',
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
                    },
                    show_empty = true,
                    hidden = true,
                    ignored = true,
                    follow = false,
                    supports_live = true,
                  }
                end,
              },
              diff = {
                action = function(picker)
                  picker:close()
                  local sel = picker:selected()
                  if #sel > 0 and sel then
                    Snacks.notify.info(sel[1].file)
                    -- vim.cmd("tabnew " .. sel[1].file .. " vert diffs " .. sel[2].file)
                    vim.cmd('tabnew ' .. sel[1].file)
                    vim.cmd('vert diffs ' .. sel[2].file)
                    Snacks.notify.info('Diffing ' .. sel[1].file .. ' against ' .. sel[2].file)
                    return
                  end

                  Snacks.notify.info 'Select two entries for the diff'
                end,
              },
            },
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
                  ['Y'] = 'copy_file_path',
                  ['s'] = 'search_in_directory',
                  ['S'] = 'search_in_directory_case_sensitive',
                  ['D'] = 'diff',
                },
              },
            },
          },
          files = {
            finder = 'files',
            format = 'file',
            show_empty = true,
            hidden = false,
            ignored = false,
            follow = false,
            supports_live = true,
          },
          git_branches = {
            all = false,
            finder = 'git_branches',
            format = 'git_branch',
            preview = 'git_log',
            confirm = 'git_checkout',
            win = {
              input = {
                keys = {
                  ['<c-a>'] = { 'git_branch_add', mode = { 'n', 'i' } },
                  ['<c-x>'] = { 'git_branch_del', mode = { 'n', 'i' } },
                },
              },
            },
            ---@param picker snacks.Picker
            on_show = function(picker)
              for i, item in ipairs(picker:items()) do
                if item.current then
                  picker.list:view(i)
                  Snacks.picker.actions.list_scroll_center(picker)
                  break
                end
              end
            end,
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
          lsp_symbols = {
            layout = {
              preset = 'vscode',
              preview = 'main',
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
      { '<leader><space>', function() Snacks.picker.smart() end,                                 desc = 'Smart Find Files [ ]' },
      { '<leader>,',       function() Snacks.picker.buffers() end,                               desc = 'Buffers [,]' },
      { '<leader>/',       function() Snacks.picker.grep() end,                                  desc = 'Grep [/]' },
      { '<leader>:',       function() Snacks.picker.command_history() end,                       desc = 'Command History [:]' },
      { '<leader>e',       function() Snacks.explorer() end,                                     desc = 'File Explorer [e]' },
      -- find
      { '<leader>fb',      function() Snacks.picker.buffers() end,                               desc = 'Buffers [fb]' },
      { '<leader>fc',      function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, desc = 'Find Config File [fc]' },
      { '<leader>ff',      function() Snacks.picker.files() end,                                 desc = 'Find Files [ff]' },
      { '<leader>fg',      function() Snacks.picker.git_files() end,                             desc = 'Find Git Files [fg]' },
      { '<leader>fp',      function() Snacks.picker.projects() end,                              desc = 'Projects [fp]' },
      { '<leader>fr',      function() Snacks.picker.recent() end,                                desc = 'Recent [fr]' },
      -- git
      { '<leader>gL',      function() Snacks.picker.git_log_line() end,                          desc = 'Git Log Line [gL]' },
      -- Grep
      { '<leader>sb',      function() Snacks.picker.lines() end,                                 desc = 'Buffer Lines [sb]' },
      { '<leader>sB',      function() Snacks.picker.grep_buffers() end,                          desc = 'Grep Open Buffers [sB]' },
      { '<leader>sg',      function() Snacks.picker.grep() end,                                  desc = 'Grep [sg]' },
      { '<leader>sw',      function() Snacks.picker.grep_word() end,                             desc = 'Visual selection or word [sw]', mode = { 'n', 'x' } },
      -- search
      { '<leader>p',       function() Snacks.picker.registers() end,                             desc = 'Registers [p]' },
      { '<leader>s/',      function() Snacks.picker.search_history() end,                        desc = 'Search History [s/]' },
      { '<leader>sa',      function() Snacks.picker.autocmds() end,                              desc = 'Autocmds [sa]' },
      { '<leader>sb',      function() Snacks.picker.lines() end,                                 desc = 'Buffer Lines [sb]' },
      { '<leader>sc',      function() Snacks.picker.command_history() end,                       desc = 'Command History [sc]' },
      { '<leader>sC',      function() Snacks.picker.commands() end,                              desc = 'Commands [sC]' },
      { '<leader>sd',      function() Snacks.picker.diagnostics() end,                           desc = 'Diagnostics [sd]' },
      { '<leader>sD',      function() Snacks.picker.diagnostics_buffer() end,                    desc = 'Buffer Diagnostics [sD]' },
      { '<leader>sh',      function() Snacks.picker.help() end,                                  desc = 'Help Pages [sh]' },
      { '<leader>sH',      function() Snacks.picker.highlights() end,                            desc = 'Highlights [sH]' },
      { '<leader>si',      function() Snacks.picker.icons() end,                                 desc = 'Icons [si]' },
      { '<leader>sj',      function() Snacks.picker.jumps() end,                                 desc = 'Jumps [sj]' },
      { '<leader>sk',      function() Snacks.picker.keymaps() end,                               desc = 'Keymaps [sk]' },
      { '<leader>sl',      function() Snacks.picker.loclist() end,                               desc = 'Location List [sl]' },
      { '<leader>sm',      function() Snacks.picker.marks() end,                                 desc = 'Marks [sm]' },
      { '<leader>sM',      function() Snacks.picker.man() end,                                   desc = 'Man Pages [sM]' },
      { '<leader>sp',      function() Snacks.picker.lazy() end,                                  desc = 'Search for Plugin Spec [sp]' },
      { '<leader>sq',      function() Snacks.picker.qflist() end,                                desc = 'Quickfix List [sq]' },
      { '<leader>sR',      function() Snacks.picker.resume() end,                                desc = 'Resume [sR]' },
      { '<leader>su',      function() Snacks.picker.undo() end,                                  desc = 'Undo History [su]' },
      { '<leader>uC',      function() Snacks.picker.colorschemes() end,                          desc = 'Colorschemes [uC]' },
      -- LSP
      { 'gd',              function() Snacks.picker.lsp_definitions() end,                       desc = 'Goto Definition (gd)' },
      { 'gD',              function() Snacks.picker.lsp_declarations() end,                      desc = 'Goto Declaration (gD)' },
      { 'gr',              function() Snacks.picker.lsp_references() end,                        nowait = true,                          desc = 'References (gr)' },
      { 'gI',              function() Snacks.picker.lsp_implementations() end,                   desc = 'Goto Implementation (gI)' },
      { 'gy',              function() Snacks.picker.lsp_type_definitions() end,                  desc = 'Goto Type Definition (gy)' },
      { '<leader>cs',      function() Snacks.picker.lsp_symbols() end,                           desc = 'LSP Symbols [ss]' },
      -- { '<leader>o',       function() Snacks.picker.lsp_symbols() end,                           desc = 'LSP Symbols [o]' },
      { '<leader>cS',      function() Snacks.picker.lsp_workspace_symbols() end,                 desc = 'LSP Workspace Symbols [sS]' },
      -- Other
      { '<leader>Z',       function() Snacks.zen() end,                                          desc = 'Toggle Zen Mode [Z]' },
      { '<leader>.',       function() Snacks.scratch() end,                                      desc = 'Toggle Scratch Buffer [.]' },
      { '<leader>S',       function() Snacks.scratch.select() end,                               desc = 'Select Scratch Buffer [S]' },
      { '<leader>sn',      function() Snacks.notifier.show_history() end,                        desc = 'Notification History [sn]' },
      { '<leader>bd',      function() Snacks.bufdelete() end,                                    desc = 'Delete Buffer [bd]' },
      { '<leader>fR',      function() Snacks.rename.rename_file() end,                           desc = 'Rename File [fR]' },
      { '<leader>gB',      function() Snacks.gitbrowse() end,                                    desc = 'Git Browse [gB]',               mode = { 'n', 'v' } },
      { '<leader>gg',      function() Snacks.lazygit() end,                                      desc = 'Lazygit [gg]' },
      { '<leader>un',      function() Snacks.notifier.hide() end,                                desc = 'Dismiss All Notifications [un]' },
      { '<c-/>',           function() Snacks.terminal() end,                                     desc = 'Toggle Terminal (c-/)' },
      { ']]',              function() Snacks.words.jump(vim.v.count1) end,                       desc = 'Next Reference',                mode = { 'n', 't' } },
      { '[[',              function() Snacks.words.jump(-vim.v.count1) end,                      desc = 'Prev Reference',                mode = { 'n', 't' } },
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
        end,
      })
    end,
  },
}
