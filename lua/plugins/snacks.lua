return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      animate = {
        ---@type snacks.animate.Duration|number
        duration = 20, -- ms per step
        easing = 'linear',
        fps = 60, -- frames per second. Global setting for all animations
      },
      bigfile = {
        notify = true, -- show notification when big file detected
        size = 1.5 * 1024 * 1024, -- 1.5MB
        line_length = 1000, -- average line length (useful for minified files)
        -- Enable or disable features when big file detected
        ---@param ctx {buf: number, ft:string}
        setup = function(ctx)
          if vim.fn.exists ':NoMatchParen' ~= 0 then
            vim.cmd [[NoMatchParen]]
          end
          Snacks.util.wo(0, { foldmethod = 'manual', statuscolumn = '', conceallevel = 0 })
          vim.b.minianimate_disable = true
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ctx.buf) then
              vim.bo[ctx.buf].syntax = ctx.ft
            end
          end)
        end,
      },
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
      explorer = { replace_netrw = true },
      gitbrowse = {
        notify = true, -- show notification on open
        -- Handler to open the url in a browser
        ---@param url string
        open = function(url)
          if vim.fn.has 'nvim-0.10' == 0 then
            require('lazy.util').open(url, { system = true })
            return
          end
          vim.ui.open(url)
        end,
        ---@type "repo" | "branch" | "file" | "commit" | "permalink"
        what = 'commit', -- what to open. not all remotes support all types
        branch = nil, ---@type string?
        line_start = nil, ---@type number?
        line_end = nil, ---@type number?
        -- patterns to transform remotes to an actual URL
        remote_patterns = {
          { '^(https?://.*)%.git$', '%1' },
          { '^git@(.+):(.+)%.git$', 'https://%1/%2' },
          { '^git@(.+):(.+)$', 'https://%1/%2' },
          { '^git@(.+)/(.+)$', 'https://%1/%2' },
          { '^org%-%d+@(.+):(.+)%.git$', 'https://%1/%2' },
          { '^ssh://git@(.*)$', 'https://%1' },
          { '^ssh://([^:/]+)(:%d+)/(.*)$', 'https://%1/%3' },
          { '^ssh://([^/]+)/(.*)$', 'https://%1/%2' },
          { 'ssh%.dev%.azure%.com/v3/(.*)/(.*)$', 'dev.azure.com/%1/_git/%2' },
          { '^https://%w*@(.*)', 'https://%1' },
          { '^git@(.*)', 'https://%1' },
          { ':%d+', '' },
          { '%.git$', '' },
        },
        url_patterns = {
          ['github%.com'] = {
            branch = '/tree/{branch}',
            file = '/blob/{branch}/{file}#L{line_start}-L{line_end}',
            permalink = '/blob/{commit}/{file}#L{line_start}-L{line_end}',
            commit = '/commit/{commit}',
          },
          ['gitlab%.com'] = {
            branch = '/-/tree/{branch}',
            file = '/-/blob/{branch}/{file}#L{line_start}-L{line_end}',
            permalink = '/-/blob/{commit}/{file}#L{line_start}-L{line_end}',
            commit = '/-/commit/{commit}',
          },
          ['bitbucket%.org'] = {
            branch = '/src/{branch}',
            file = '/src/{branch}/{file}#lines-{line_start}-L{line_end}',
            permalink = '/src/{commit}/{file}#lines-{line_start}-L{line_end}',
            commit = '/commits/{commit}',
          },
          ['git.sr.ht'] = {
            branch = '/tree/{branch}',
            file = '/tree/{branch}/item/{file}',
            permalink = '/tree/{commit}/item/{file}#L{line_start}',
            commit = '/commit/{commit}',
          },
        },
      },
      image = {
        formats = {
          'png',
          'jpg',
          'jpeg',
          'gif',
          'bmp',
          'webp',
          'tiff',
          'heic',
          'avif',
          'mp4',
          'mov',
          'avi',
          'mkv',
          'webm',
          'pdf',
        },
        force = true, -- try displaying the image, even if the terminal does not support it
        doc = {
          -- enable image viewer for documents
          -- a treesitter parser must be available for the enabled languages.
          enabled = true,
          -- render the image inline in the buffer
          -- if your env doesn't support unicode placeholders, this will be disabled
          -- takes precedence over `opts.float` on supported terminals
          inline = true,
          -- render the image in a floating window
          -- only used if `opts.inline` is disabled
          float = true,
          max_width = 80,
          max_height = 40,
          -- Set to `true`, to conceal the image text when rendering inline.
          -- (experimental)
          conceal = function(lang, type)
            -- only conceal math expressions
            return type == 'math'
          end,
        },
        img_dirs = { 'img', 'images', 'assets', 'static', 'public', 'media', 'attachments' },
        -- window options applied to windows displaying image buffers
        -- an image buffer is a buffer with `filetype=image`
        wo = {
          wrap = false,
          number = false,
          relativenumber = false,
          cursorcolumn = false,
          signcolumn = 'no',
          foldcolumn = '0',
          list = false,
          spell = false,
          statuscolumn = '',
        },
        cache = vim.fn.stdpath 'cache' .. '/snacks/image',
        debug = {
          request = false,
          convert = false,
          placement = false,
        },
        env = {},
        -- icons used to show where an inline image is located that is
        -- rendered below the text.
        icons = {
          math = '󰪚 ',
          chart = '󰄧 ',
          image = ' ',
        },
        ---@class snacks.image.convert.Config
        convert = {
          notify = true, -- show a notification on error
          ---@type snacks.image.args
          mermaid = function()
            local theme = vim.o.background == 'light' and 'neutral' or 'dark'
            return { '-i', '{src}', '-o', '{file}', '-b', 'transparent', '-t', theme, '-s', '{scale}' }
          end,
          ---@type table<string,snacks.image.args>
          magick = {
            default = { '{src}[0]', '-scale', '1920x1080>' }, -- default for raster images
            vector = { '-density', 192, '{src}[0]' }, -- used by vector images like svg
            math = { '-density', 192, '{src}[0]', '-trim' },
            pdf = { '-density', 192, '{src}[0]', '-background', 'white', '-alpha', 'remove', '-trim' },
          },
        },
        math = {
          enabled = true, -- enable math expression rendering
          -- in the templates below, `${header}` comes from any section in your document,
          -- between a start/end header comment. Comment syntax is language-specific.
          -- * start comment: `// snacks: header start`
          -- * end comment:   `// snacks: header end`
          typst = {
            tpl = [[
        #set page(width: auto, height: auto, margin: (x: 2pt, y: 2pt))
        #show math.equation.where(block: false): set text(top-edge: "bounds", bottom-edge: "bounds")
        #set text(size: 12pt, fill: rgb("${color}"))
        ${header}
        ${content}]],
          },
          latex = {
            font_size = 'Large', -- see https://www.sascha-frank.com/latex-font-size.html
            -- for latex documents, the doc packages are included automatically,
            -- but you can add more packages here. Useful for markdown documents.
            packages = { 'amsmath', 'amssymb', 'amsfonts', 'amscd', 'mathtools' },
            tpl = [[
        \documentclass[preview,border=0pt,varwidth,12pt]{standalone}
        \usepackage{${packages}}
        \begin{document}
        ${header}
        { \${font_size} \selectfont
          \color[HTML]{${color}}
        ${content}}
        \end{document}]],
          },
        },
      },
      indent = {
        indent = {
          priority = 1,
          enabled = true, -- enable indent guides
          char = '│',
          only_scope = false, -- only show indent guides of the scope
          only_current = false, -- only show indent guides in the current window
          hl = 'SnacksIndent', ---@type string|string[] hl groups for indent guides
          -- can be a list of hl groups to cycle through
          -- hl = {
          --     "SnacksIndent1",
          --     "SnacksIndent2",
          --     "SnacksIndent3",
          --     "SnacksIndent4",
          --     "SnacksIndent5",
          --     "SnacksIndent6",
          --     "SnacksIndent7",
          --     "SnacksIndent8",
          -- },
        },
        -- animate scopes. Enabled by default for Neovim >= 0.10
        -- Works on older versions but has to trigger redraws during animation.
        ---@class snacks.indent.animate: snacks.animate.Config
        ---@field enabled? boolean
        --- * out: animate outwards from the cursor
        --- * up: animate upwards from the cursor
        --- * down: animate downwards from the cursor
        --- * up_down: animate up or down based on the cursor position
        ---@field style? "out"|"up_down"|"down"|"up"
        animate = {
          enabled = vim.fn.has 'nvim-0.10' == 1,
          style = 'out',
          easing = 'linear',
          duration = {
            step = 20, -- ms per step
            total = 500, -- maximum duration
          },
        },
        ---@class snacks.indent.Scope.Config: snacks.scope.Config
        scope = {
          enabled = true, -- enable highlighting the current scope
          priority = 200,
          char = '│',
          underline = false, -- underline the start of the scope
          only_current = false, -- only show scope in the current window
          hl = 'SnacksIndentScope', ---@type string|string[] hl group for scopes
        },
        chunk = {
          -- when enabled, scopes will be rendered as chunks, except for the
          -- top-level scope which will be rendered as a scope.
          enabled = false,
          -- only show chunk scopes in the current window
          only_current = false,
          priority = 200,
          hl = 'SnacksIndentChunk', ---@type string|string[] hl group for chunk scopes
          char = {
            corner_top = '┌',
            corner_bottom = '└',
            -- corner_top = "╭",
            -- corner_bottom = "╰",
            horizontal = '─',
            vertical = '│',
            arrow = '>',
          },
        },
        -- filter for buffers to enable indent guides
        filter = function(buf)
          return vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false and vim.bo[buf].buftype == ''
        end,
      },
      input = {
        icon = ' ',
        icon_hl = 'SnacksInputIcon',
        icon_pos = 'left',
        prompt_pos = 'title',
        win = { style = 'input' },
        expand = true,
      },
      lazygit = {
        -- automatically configure lazygit to use the current colorscheme
        -- and integrate edit with the current neovim instance
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
        timeout = 3000, -- default timeout in ms
        width = { min = 40, max = 0.4 },
        height = { min = 1, max = 0.6 },
        -- editor margin to keep free. tabline and statusline are taken into account automatically
        margin = { top = 0, right = 1, bottom = 0 },
        padding = true, -- add 1 cell of left/right padding to the notification window
        sort = { 'level', 'added' }, -- sort by level and time
        -- minimum log level to display. TRACE is the lowest
        -- all notifications are stored in history
        level = vim.log.levels.TRACE,
        icons = {
          error = ' ',
          warn = ' ',
          info = ' ',
          debug = ' ',
          trace = ' ',
        },
        keep = function(notif)
          return vim.fn.getcmdpos() > 0
        end,
        ---@type snacks.notifier.style
        style = 'fancy',
        top_down = true, -- place notifications from top to bottom
        date_format = '%R', -- time format for notifications
        -- format for footer when more lines are available
        -- `%d` is replaced with the number of lines.
        -- only works for styles with a border
        ---@type string|boolean
        more_format = ' ↓ %d lines ',
        refresh = 50, -- refresh at most every 50ms
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
          git_files = {
            finder = 'git_files',
            show_empty = true,
            format = 'file',
            untracked = false,
            submodules = false,
          },
          grep = {
            finder = 'grep',
            regex = true,
            format = 'file',
            show_empty = true,
            live = true, -- live grep by default
            supports_live = true,
          },
          grep_buffers = {
            finder = 'grep',
            format = 'file',
            live = true,
            buffers = true,
            need_search = false,
            supports_live = true,
          },
          grep_word = {
            finder = 'grep',
            regex = false,
            format = 'file',
            search = function(picker)
              return picker:word()
            end,
            live = false,
            supports_live = true,
          },
          help = {
            finder = 'help',
            format = 'text',
            previewers = {
              file = { ft = 'help' },
            },
            win = { preview = { minimal = true } },
            confirm = 'help',
          },
          highlights = {
            finder = 'vim_highlights',
            format = 'hl',
            preview = 'preview',
            confirm = 'close',
          },
          icons = {
            icon_sources = { 'nerd_fonts', 'emoji' },
            finder = 'icons',
            format = 'icon',
            layout = { preset = 'vscode' },
            confirm = 'put',
          },
          jumps = {
            finder = 'vim_jumps',
            format = 'file',
          },
          keymaps = {
            finder = 'vim_keymaps',
            format = 'keymap',
            preview = 'preview',
            global = true,
            plugs = false,
            ['local'] = true,
            modes = { 'n', 'v', 'x', 's', 'o', 'i', 'c', 't' },
            ---@param picker snacks.Picker
            confirm = function(picker, item)
              picker:norm(function()
                if item then
                  picker:close()
                  vim.api.nvim_input(item.item.lhs)
                end
              end)
            end,
            actions = {
              toggle_global = function(picker)
                picker.opts.global = not picker.opts.global
                picker:find()
              end,
              toggle_buffer = function(picker)
                picker.opts['local'] = not picker.opts['local']
                picker:find()
              end,
            },
            win = {
              input = {
                keys = {
                  ['<a-g>'] = { 'toggle_global', mode = { 'n', 'i' }, desc = 'Toggle Global Keymaps' },
                  ['<a-b>'] = { 'toggle_buffer', mode = { 'n', 'i' }, desc = 'Toggle Buffer Keymaps' },
                },
              },
            },
          },
          lazy = {
            finder = 'lazy_spec',
            pattern = "'",
          },
          lines = {
            finder = 'lines',
            format = 'lines',
            layout = {
              preview = 'main',
              preset = 'ivy',
            },
            jump = { match = true },
            -- allow any window to be used as the main window
            main = { current = true },
            ---@param picker snacks.Picker
            on_show = function(picker)
              local cursor = vim.api.nvim_win_get_cursor(picker.main)
              local info = vim.api.nvim_win_call(picker.main, vim.fn.winsaveview)
              picker.list:view(cursor[1], info.topline)
              picker:show_preview()
            end,
            sort = { fields = { 'score:desc', 'idx' } },
          },
          loclist = {
            finder = 'qf',
            format = 'file',
            qf_win = 0,
          },
          lsp_config = {
            finder = 'lsp.config#find',
            format = 'lsp.config#format',
            preview = 'lsp.config#preview',
            confirm = 'close',
            sort = { fields = { 'score:desc', 'attached_buf', 'attached', 'enabled', 'installed', 'name' } },
            matcher = { sort_empty = true },
          },
          lsp_declarations = {
            finder = 'lsp_declarations',
            format = 'file',
            include_current = false,
            auto_confirm = true,
            jump = { tagstack = true, reuse_win = true },
          },
          lsp_definitions = {
            finder = 'lsp_definitions',
            format = 'file',
            include_current = false,
            auto_confirm = true,
            jump = { tagstack = true, reuse_win = true },
          },
          lsp_implementations = {
            finder = 'lsp_implementations',
            format = 'file',
            include_current = false,
            auto_confirm = true,
            jump = { tagstack = true, reuse_win = true },
          },
          lsp_references = {
            finder = 'lsp_references',
            format = 'file',
            include_declaration = true,
            include_current = false,
            auto_confirm = true,
            jump = { tagstack = true, reuse_win = true },
          },
          lsp_symbols = {
            finder = 'lsp_symbols',
            format = 'lsp_symbol',
            tree = true,
            filter = {
              default = {
                'Class',
                'Constructor',
                'Enum',
                'Field',
                'Function',
                'Interface',
                'Method',
                'Module',
                'Namespace',
                'Package',
                'Property',
                'Struct',
                'Trait',
              },
              -- set to `true` to include all symbols
              markdown = true,
              help = true,
              -- you can specify a different filter for each filetype
              lua = {
                'Class',
                'Constructor',
                'Enum',
                'Field',
                'Function',
                'Interface',
                'Method',
                'Module',
                'Namespace',
                -- "Package", -- remove package since luals uses it for control flow structures
                'Property',
                'Struct',
                'Trait',
              },
            },
          },
          lsp_type_definitions = {
            finder = 'lsp_type_definitions',
            format = 'file',
            include_current = false,
            auto_confirm = true,
            jump = { tagstack = true, reuse_win = true },
          },
          lsp_workspace_symbols = {},
          man = {
            finder = 'system_man',
            format = 'man',
            preview = 'man',
            confirm = function(picker, item)
              picker:close()
              if item then
                vim.schedule(function()
                  vim.cmd('Man ' .. item.ref)
                end)
              end
            end,
          },
          marks = {
            finder = 'vim_marks',
            format = 'file',
            global = true,
            ['local'] = true,
          },
          notifications = {
            finder = 'snacks_notifier',
            format = 'notification',
            preview = 'preview',
            formatters = { severity = { level = true } },
            confirm = 'close',
          },
          picker_actions = {
            finder = 'meta_actions',
            format = 'text',
          },
          picker_format = {
            finder = 'meta_format',
            format = 'text',
          },
          picker_layouts = {
            finder = 'meta_layouts',
            format = 'text',
            on_change = function(picker, item)
              vim.schedule(function()
                picker:set_layout(item.text)
              end)
            end,
          },
          picker_preview = {
            finder = 'meta_preview',
            format = 'text',
          },
          pickers = {
            finder = 'meta_pickers',
            format = 'text',
            confirm = function(picker, item)
              picker:close()
              if item then
                vim.schedule(function()
                  Snacks.picker(item.text)
                end)
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
          qflist = {
            finder = 'qf',
            format = 'file',
          },
          recent = {
            finder = 'recent_files',
            format = 'file',
            filter = {
              paths = {
                [vim.fn.stdpath 'data'] = false,
                [vim.fn.stdpath 'cache'] = false,
                [vim.fn.stdpath 'state'] = false,
              },
            },
          },
          registers = {
            finder = 'vim_registers',
            format = 'register',
            preview = 'preview',
            confirm = { 'copy', 'close' },
          },
          smart = {
            multi = { 'buffers', 'recent', 'files' },
            format = 'file', -- use `file` format for all sources
            matcher = {
              cwd_bonus = true, -- boost cwd matches
              frecency = true, -- use frecency boosting
              sort_empty = true, -- sort even when the filter is empty
            },
            transform = 'unique_file',
          },
          spelling = {
            finder = 'vim_spelling',
            format = 'text',
            layout = { preset = 'vscode' },
            confirm = 'item_action',
          },
          treesitter = {
            finder = 'treesitter_symbols',
            format = 'lsp_symbol',
            tree = true,
            filter = {
              default = {
                'Class',
                'Enum',
                'Field',
                'Function',
                'Method',
                'Module',
                'Namespace',
                'Struct',
                'Trait',
              },
              -- set to `true` to include all symbols
              markdown = true,
              help = true,
            },
          },
          undo = {
            finder = 'vim_undo',
            format = 'undo',
            preview = 'diff',
            confirm = 'item_action',
            win = {
              preview = { wo = { number = false, relativenumber = false, signcolumn = 'no' } },
              input = {
                keys = {
                  ['<c-y>'] = { 'yank_add', mode = { 'n', 'i' } },
                  ['<c-s-y>'] = { 'yank_del', mode = { 'n', 'i' } },
                },
              },
            },
            actions = {
              yank_add = { action = 'yank', field = 'added_lines' },
              yank_del = { action = 'yank', field = 'removed_lines' },
            },
            icons = { tree = { last = '┌╴' } }, -- the tree is upside down
            diff = {
              ctxlen = 4,
              ignore_cr_at_eol = true,
              ignore_whitespace_change_at_eol = true,
              indent_heuristic = true,
            },
          },
          zoxide = {
            finder = 'files_zoxide',
            format = 'file',
            confirm = 'load_session',
            win = {
              preview = {
                minimal = true,
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
          text = {
            ft = nil, ---@type string? filetype for highlighting
          },
          file = {
            filename_first = true, -- display filename before the file path
            truncate = 40, -- truncate the file path to (roughly) this length
            filename_only = false, -- only show the filename
            icon_width = 2, -- width of the icon (in characters)
            git_status_hl = true, -- use the git status highlight group for the filename
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
          diff = {
            builtin = true, -- use Neovim for previewing diffs (true) or use an external tool (false)
            cmd = { 'delta' }, -- example to show a diff with delta
          },
          git = {
            builtin = true, -- use Neovim for previewing git output (true) or use git (false)
            args = {}, -- additional arguments passed to the git command. Useful to set pager options using `-c ...`
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
      },
      quickfile = { exclude = { 'latex' } },
      scope = { -- absolute minimum size of the scope.
        -- can be less if the scope is a top-level single line scope
        min_size = 2,
        -- try to expand the scope to this size
        max_size = nil,
        cursor = true, -- when true, the column of the cursor is used to determine the scope
        edge = true, -- include the edge of the scope (typically the line above and below with smaller indent)
        siblings = false, -- expand single line scopes with single line siblings
        -- what buffers to attach to
        filter = function(buf)
          return vim.bo[buf].buftype == '' and vim.b[buf].snacks_scope ~= false and vim.g.snacks_scope ~= false
        end,
        -- debounce scope detection in ms
        debounce = 30,
        treesitter = {
          -- detect scope based on treesitter.
          -- falls back to indent based detection if not available
          enabled = true,
          injections = true, -- include language injections when detecting scope (useful for languages like `vue`)
          ---@type string[]|{enabled?:boolean}
          blocks = {
            enabled = false, -- enable to use the following blocks
            'function_declaration',
            'function_definition',
            'method_declaration',
            'method_definition',
            'class_declaration',
            'class_definition',
            'do_statement',
            'while_statement',
            'repeat_statement',
            'if_statement',
            'for_statement',
          },
          -- these treesitter fields will be considered as blocks
          field_blocks = {
            'local_declaration',
          },
        },
        -- These keymaps will only be set if the `scope` plugin is enabled.
        -- Alternatively, you can set them manually in your config,
        -- using the `Snacks.scope.textobject` and `Snacks.scope.jump` functions.
        keys = {
          ---@type table<string, snacks.scope.TextObject|{desc?:string}>
          textobject = {
            ii = {
              min_size = 2, -- minimum size of the scope
              edge = false, -- inner scope
              cursor = false,
              treesitter = { blocks = { enabled = false } },
              desc = 'inner scope',
            },
            ai = {
              cursor = false,
              min_size = 2, -- minimum size of the scope
              treesitter = { blocks = { enabled = false } },
              desc = 'full scope',
            },
          },
          ---@type table<string, snacks.scope.Jump|{desc?:string}>
          jump = {
            ['[i'] = {
              min_size = 1, -- allow single line scopes
              bottom = false,
              cursor = false,
              edge = true,
              treesitter = { blocks = { enabled = false } },
              desc = 'jump to top edge of scope',
            },
            [']i'] = {
              min_size = 1, -- allow single line scopes
              bottom = true,
              cursor = false,
              edge = true,
              treesitter = { blocks = { enabled = false } },
              desc = 'jump to bottom edge of scope',
            },
          },
        },
      },
      scratch = {
        name = 'Scratch',
        ft = function()
          if vim.bo.buftype == '' and vim.bo.filetype ~= '' then
            return vim.bo.filetype
          end
          return 'markdown'
        end,
        ---@type string|string[]?
        icon = nil, -- `icon|{icon, icon_hl}`. defaults to the filetype icon
        root = vim.fn.stdpath 'data' .. '/scratch',
        autowrite = true, -- automatically write when the buffer is hidden
        -- unique key for the scratch file is based on:
        -- * name
        -- * ft
        -- * vim.v.count1 (useful for keymaps)
        -- * cwd (optional)
        -- * branch (optional)
        filekey = {
          cwd = true, -- use current working directory
          branch = true, -- use current branch name
          count = true, -- use vim.v.count1
        },
        win = { style = 'scratch' },
        ---@type table<string, snacks.win.Config>
        win_by_ft = {
          lua = {
            keys = {
              ['source'] = {
                '<cr>',
                function(self)
                  local name = 'scratch.' .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self.buf), ':e')
                  Snacks.debug.run { buf = self.buf, name = name }
                end,
                desc = 'Source buffer',
                mode = { 'n', 'x' },
              },
            },
          },
        },
      },
      scroll = {
        name = 'Scratch',
        ft = function()
          if vim.bo.buftype == '' and vim.bo.filetype ~= '' then
            return vim.bo.filetype
          end
          return 'markdown'
        end,
        ---@type string|string[]?
        icon = nil, -- `icon|{icon, icon_hl}`. defaults to the filetype icon
        root = vim.fn.stdpath 'data' .. '/scratch',
        autowrite = true, -- automatically write when the buffer is hidden
        -- unique key for the scratch file is based on:
        -- * name
        -- * ft
        -- * vim.v.count1 (useful for keymaps)
        -- * cwd (optional)
        -- * branch (optional)
        filekey = {
          cwd = true, -- use current working directory
          branch = true, -- use current branch name
          count = true, -- use vim.v.count1
        },
        win = { style = 'scratch' },
        ---@type table<string, snacks.win.Config>
        win_by_ft = {
          lua = {
            keys = {
              ['source'] = {
                '<cr>',
                function(self)
                  local name = 'scratch.' .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self.buf), ':e')
                  Snacks.debug.run { buf = self.buf, name = name }
                end,
                desc = 'Source buffer',
                mode = { 'n', 'x' },
              },
            },
          },
        },
      },
      statuscolumn = {
        left = { 'mark', 'sign' }, -- priority of signs on the left (high to low)
        right = { 'fold', 'git' }, -- priority of signs on the right (high to low)
        folds = {
          open = false, -- show open fold icons
          git_hl = false, -- use Git Signs hl for fold icons
        },
        git = {
          -- patterns to match Git signs
          patterns = { 'GitSign', 'MiniDiffSign' },
        },
        refresh = 50, -- refresh at most every 50ms
      },
      terminal = {
        win = {
          position = 'float',
        },
      },
      toggle = {
        map = vim.keymap.set, -- keymap.set function to use
        which_key = true, -- integrate with which-key to show enabled/disabled icons and colors
        notify = true, -- show a notification when toggling
        -- icons for enabled/disabled states
        icon = {
          enabled = ' ',
          disabled = ' ',
        },
        -- colors for enabled/disabled states
        color = {
          enabled = 'green',
          disabled = 'yellow',
        },
        wk_desc = {
          enabled = 'Disable ',
          disabled = 'Enable ',
        },
      },
      words = {
        debounce = 200, -- time in ms to wait before updating
        notify_jump = false, -- show a notification when jumping
        notify_end = true, -- show a notification when reaching the end
        foldopen = true, -- open folds after jumping
        jumplist = true, -- set jump point before jumping
        modes = { 'n', 'i', 'c' }, -- modes to show references
        filter = function(buf) -- what buffers to enable `snacks.words`
          return vim.g.snacks_words ~= false and vim.b[buf].snacks_words ~= false
        end,
      },
      zen = {
        -- You can add any `Snacks.toggle` id here.
        -- Toggle state is restored when the window is closed.
        -- Toggle config options are NOT merged.
        ---@type table<string, boolean>
        toggles = {
          dim = false,
          git_signs = true,
          mini_diff_signs = false,
          diagnostics = true,
          inlay_hints = true,
        },
        show = {
          statusline = false, -- can only be shown when using the global statusline
          tabline = false,
        },
        ---@type snacks.win.Config
        win = { style = 'zen' },
        --- Options for the `Snacks.zen.zoom()`
        ---@type snacks.zen.Config
        zoom = {
          toggles = {},
          show = { statusline = true, tabline = true },
          win = {
            backdrop = false,
            width = 0, -- full width
          },
        },
      },
    },
    -- stylua: ignore
    keys = {
      -- Top Pickers & Explorer
      { '<leader><space>', function() Snacks.picker.smart() end, desc = 'Smart Find Files [ ]', },
      { '<leader>,', function() Snacks.picker.buffers() end, desc = 'Buffers [,]', },
      { '<leader>/', function() Snacks.picker.grep() end, desc = 'Grep [/]', },
      { '<leader>:', function() Snacks.picker.command_history() end, desc = 'Command History [:]', },
      { '<leader>e', function() Snacks.explorer() end, desc = 'File Explorer [e]', },
      -- find
      { '<leader>fc', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, desc = 'Find Config File [fc]', },
      { '<leader>ff', function() Snacks.picker.files() end, desc = 'Find Files [ff]', },
      { '<leader>fg', function() Snacks.picker.git_files() end, desc = 'Find Git Files [fg]', },
      { '<leader>fp', function() Snacks.picker.projects() end, desc = 'Projects [fp]', },
      { '<leader>fr', function() Snacks.picker.recent() end, desc = 'Recent [fr]', },
      -- git
      { '<leader>gL', function() Snacks.picker.git_log_line() end, desc = 'Git Log Line [gL]', },
      -- Grep
      { '<leader>sb', function() Snacks.picker.lines() end, desc = 'Buffer Lines [sb]', },
      { '<leader>sB', function() Snacks.picker.grep_buffers() end, desc = 'Grep Open Buffers [sB]', },
      { '<leader>sw', function() Snacks.picker.grep_word() end, desc = 'Visual selection or word [sw]', mode = { 'n', 'x' }, },
      -- search
      { '<leader>p', function() Snacks.picker.registers() end, desc = 'Registers [p]', },
      { '<leader>s/', function() Snacks.picker.search_history() end, desc = 'Search History [s/]', },
      { '<leader>sa', function() Snacks.picker.autocmds() end, desc = 'Autocmds [sa]', },
      { '<leader>sb', function() Snacks.picker.lines() end, desc = 'Buffer Lines [sb]', },
      { '<leader>sc', function() Snacks.picker.command_history() end, desc = 'Command History [sc]', },
      { '<leader>sC', function() Snacks.picker.commands() end, desc = 'Commands [sC]', },
      { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = 'Diagnostics [sd]', },
      { '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, desc = 'Buffer Diagnostics [sD]', },
      { '<leader>sh', function() Snacks.picker.help() end, desc = 'Help Pages [sh]', },
      { '<leader>sH', function() Snacks.picker.highlights() end, desc = 'Highlights [sH]', },
      { '<leader>si', function() Snacks.picker.icons() end, desc = 'Icons [si]', },
      { '<leader>sj', function() Snacks.picker.jumps() end, desc = 'Jumps [sj]', },
      { '<leader>sk', function() Snacks.picker.keymaps() end, desc = 'Keymaps [sk]', },
      { '<leader>sl', function() Snacks.picker.loclist() end, desc = 'Location List [sl]', },
      { '<leader>sm', function() Snacks.picker.marks() end, desc = 'Marks [sm]', },
      { '<leader>sM', function() Snacks.picker.man() end, desc = 'Man Pages [sM]', },
      { '<leader>sp', function() Snacks.picker.lazy() end, desc = 'Search for Plugin Spec [sp]', },
      { '<leader>sq', function() Snacks.picker.qflist() end, desc = 'Quickfix List [sq]', },
      { '<leader>sR', function() Snacks.picker.resume() end, desc = 'Resume [sR]', },
      { '<leader>su', function() Snacks.picker.undo() end, desc = 'Undo History [su]', },
      { '<leader>uC', function() Snacks.picker.colorschemes() end, desc = 'Colorschemes [uC]', },
      -- LSP
      { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition (gd)', },
      { 'gD', function() Snacks.picker.lsp_declarations() end, desc = 'Goto Declaration (gD)', },
      { 'gr', function() Snacks.picker.lsp_references() end, nowait = true, desc = 'References (gr)', },
      { 'gI', function() Snacks.picker.lsp_implementations() end, desc = 'Goto Implementation (gI)', },
      { 'gy', function() Snacks.picker.lsp_type_definitions() end, desc = 'Goto Type Definition (gy)', },
      { '<leader>o', function() Snacks.picker.lsp_symbols() end, desc = 'LSP Symbols [o]', },
      { '<leader>cS', function() Snacks.picker.lsp_workspace_symbols() end, desc = 'LSP Workspace Symbols [sS]', },
      -- Other
      { '<leader>Z', function() Snacks.zen() end, desc = 'Toggle Zen Mode [Z]', },
      { '<leader>.', function() Snacks.scratch() end, desc = 'Toggle Scratch Buffer [.]', },
      { '<leader>S', function() Snacks.scratch.select() end, desc = 'Select Scratch Buffer [S]', },
      { '<leader>sn', function() Snacks.notifier.show_history() end, desc = 'Notification History [sn]', },
      { '<leader>bd', function() Snacks.bufdelete() end, desc = 'Delete Current Buffer [bd]', },
      { '<leader>bo', function() Snacks.bufdelete.other() end, desc = 'Delete Other Buffers [bo]', },
      { '<leader>fR', function() Snacks.rename.rename_file() end, desc = 'Rename File [fR]', },
      { '<leader>gB', function() Snacks.gitbrowse() end, desc = 'Git Browse [gB]', mode = { 'n', 'v' }, },
      { '<leader>gg', function() Snacks.lazygit() end, desc = 'Lazygit [gg]', },
      { '<leader>un', function() Snacks.notifier.hide() end, desc = 'Dismiss All Notifications [un]', },
      { ']]', function() Snacks.words.jump(vim.v.count1) end, desc = 'Next Reference', mode = { 'n'}, },
      { '[[', function() Snacks.words.jump(-vim.v.count1) end, desc = 'Prev Reference', mode = { 'n' }, },
      -- terminal apps
      { '<leader>la', function() Snacks.terminal.toggle 'cloudlens' end, desc = 'Cloud Resources TUI [lc]' },
      { '<leader>lb', function() Snacks.terminal.toggle 'btop' end, desc = 'System Monitor TUI [lb]' },
      { '<leader>lc', function() Snacks.terminal.toggle 'nap' end, desc = 'Code snippets TUI [lc]' },
      { '<leader>ld', function() Snacks.terminal.toggle 'podman-tui' end, desc = 'Podman TUI [ld]' },
      { '<leader>lD', function() Snacks.terminal.toggle 'lazydocker' end, desc = 'Docker TUI [lD]' },
      { '<leader>lg', function() Snacks.lazygit() end, desc = 'GIT TUI [lg]' },
      { '<leader>lh', function() Snacks.terminal.toggle 'clx' end, desc = 'Hackernews TUI [lh]' },
      { '<leader>lj', function() Snacks.terminal.toggle 'euporie-notebook' end, desc = 'Jupyter Notebooks TUI [lj]' },
      { '<leader>lK', function() Snacks.terminal.toggle 'k9s' end, desc = 'Kubernetes TUI [lk]' },
      { '<leader>ln', function() Snacks.terminal.toggle 'termscp' end, desc = 'Network Client [ln]' },
      { '<leader>lp', function() Snacks.terminal.toggle 'python3' end, desc = 'Python Term [lp]' },
      { '<leader>lr', function() Snacks.terminal.toggle 'posting' end, desc = 'REST Client TUI [lr]' },
      { '<leader>ls', function() Snacks.terminal.toggle 'harlequin' end, desc = 'Database TUI [ls]' },
      { '<leader>lt', function() Snacks.terminal.toggle 'omm --editor nvim' end, desc = 'TODO TUI [lt]' },
      { '<leader>lu', function() Snacks.terminal.toggle 'dua i' end, desc = 'Disk Usage TUI [lu]' },
      { '<leader>lv', function() Snacks.terminal.toggle 'jshell' end, desc = 'JShell Term [lv]' },
      { '<c-/>', function() Snacks.terminal.toggle 'zellij attach -c options --theme kanagawa-light --show-startup-tips true' end, desc = 'Toggle Terminal (c-/)' },
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
