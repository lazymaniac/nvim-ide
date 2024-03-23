local Util = require 'util'

return {

  -- [[ TELESCOPE ]] ---------------------------------------------------------------

  -- [telescope.nvim] - Fuzzy finder for project files
  -- see: `:h telescope`
  {
    'nvim-telescope/telescope.nvim',
    event = 'VeryLazy',
    cmd = 'Telescope',
    -- stylua: ignore
    keys = {
      { '<leader>,', '<cmd>Telescope buffers sort_mru=true sort_lastused=true layout_strategy=vertical<cr>', desc = 'Switch Buffer [,]' },
      { '<leader>:', '<cmd>Telescope command_history layout_strategy=vertical<cr>', desc = 'Command History [:]' },
      { '<leader><space>', Util.telescope('files', { layout_strategy='vertical' }) , desc = 'Find Files (root dir) [SPC]' },
      -- find
      { '<leader>fc', Util.telescope.config_files(), desc = 'Find Config File [fc]' },
      { '<leader>ff', Util.telescope('files', { cwd = false, layout_strategy='vertical' }), desc = 'Find Files (cwd) [ff]' },
      { '<leader>fr', '<cmd>Telescope oldfiles layout_strategy=vertical<cr>', desc = 'Recent [fr]' },
      { '<leader>fR', Util.telescope('oldfiles', { cwd = vim.loop.cwd(), layout_strategy = 'vertical' }), desc = 'Recent (cwd) [fR]' },
      -- git
      { '<leader>gc', '<cmd>Telescope git_commits layout_strategy=vertical<CR>', desc = 'Git Commits [gc]' },
      { '<leader>gs', '<cmd>Telescope git_status layout_strategy=vertical<CR>', desc = 'Git Status [gd]' },
      -- search
      { '<leader>s"', '<cmd>Telescope registers layout_strategy=vertical<cr>', desc = 'Registers [s"]' },
      { '<leader>sa', '<cmd>Telescope autocommands layout_strategy=vertical<cr>', desc = 'Auto Commands [sa]' },
      { '<leader>sb', '<cmd>Telescope current_buffer_fuzzy_find layout_strategy=vertical<cr>', desc = 'Fzf Buffer [sb]' },
      { '<leader>sc', '<cmd>Telescope command_history layout_strategy=vertical<cr>', desc = 'Command History [sc]' },
      { '<leader>sC', '<cmd>Telescope commands layout_strategy=vertical<cr>', desc = 'Commands [sC]' },
      { '<leader>sd', '<cmd>Telescope diagnostics bufnr=0 layout_strategy=vertical<cr>', desc = 'Document Diagnostics [sd]' },
      { '<leader>sD', '<cmd>Telescope diagnostics layout_strategy=vertical<cr>', desc = 'Workspace Diagnostics [sD]' },
      { '<leader>sg', Util.telescope('live_grep', { layout_strategy='vertical'}), desc = 'Grep (root dir) [sg]' },
      { '<leader>sG', Util.telescope('live_grep', { cwd = false, layout_strategy='vertical' }), desc = 'Grep (cwd) [sG]' },
      { '<leader>sh', '<cmd>Telescope help_tags layout_strategy=vertical<cr>', desc = 'Help Pages [sh]' },
      { '<leader>sH', '<cmd>Telescope highlights layout_strategy=vertical<cr>', desc = 'Search Highlight Groups [sH]' },
      { '<leader>sk', '<cmd>Telescope keymaps layout_strategy=vertical<cr>', desc = 'Key Maps [sk]' },
      { '<leader>sM', '<cmd>Telescope man_pages layout_strategy=vertical<cr>', desc = 'Man Pages [sM]' },
      { '<leader>sm', '<cmd>Telescope marks layout_strategy=vertical<cr>', desc = 'Jump to Mark [sm]' },
      { '<leader>so', '<cmd>Telescope vim_options layout_strategy=vertical<cr>', desc = 'Options [so]' },
      { '<leader>sR', '<cmd>Telescope resume<cr>', desc = 'Resume Last Search [sR]' },
      { '<leader>sw', Util.telescope('grep_string', { word_match = '-w', layout_strategy = 'vertical' }), desc = 'Word (root dir) [sw]' },
      { '<leader>sW', Util.telescope('grep_string', { cwd = false, word_match = '-w', layout_strategy = 'vertical' }), desc = 'Word (cwd) [sW]' },
      { '<leader>sw', Util.telescope('grep_string', { layout_strategy = 'vertical' }), mode = 'v', desc = 'Selection (root dir) [sw]' },
      { '<leader>sW', Util.telescope('grep_string', { cwd = false, layout_strategy = 'vertical' }), mode = 'v', desc = 'Selection (cwd) [sW]' },
      { '<leader>uC', Util.telescope('colorscheme', { enable_preview = true, layout_strategy = 'vertical' }), desc = 'Colorscheme with preview [uC]' },
      { '<leader>ss', function() require('telescope.builtin').lsp_document_symbols { layout_strategy = 'vertical' } end, desc = 'Goto Symbol [ss]' },
      { '<leader>sS', function() require('telescope.builtin').lsp_dynamic_workspace_symbols { layout_strategy = 'vertical' } end, desc = 'Goto Symbol (Workspace) [sS]' },
      { '<leader>sP', function() require('telescope.builtin').find_files { cwd = require('lazy.core.config').options.root, layout_strategy = 'vertical' } end, desc = 'Search Plugin File [sP]' },
    },
    opts = function()
      local actions = require 'telescope.actions'
      local open_with_trouble = function(...)
        return require('trouble.providers.telescope').open_with_trouble(...)
      end
      local open_selected_with_trouble = function(...)
        return require('trouble.providers.telescope').open_selected_with_trouble(...)
      end
      local find_files_no_ignore = function()
        local action_state = require 'telescope.actions.state'
        local line = action_state.get_current_line()
        Util.telescope('find_files', { no_ignore = true, default_text = line })()
      end
      local find_files_with_hidden = function()
        local action_state = require 'telescope.actions.state'
        local line = action_state.get_current_line()
        Util.telescope('find_files', { hidden = true, default_text = line })()
      end
      local egrep_actions = require 'telescope._extensions.egrepify.actions'
      return {
        defaults = {
          sorting_strategy = 'ascending',
          scroll_strategy = 'limit',
          layout_strategy = 'vertical',
          layout_config = {
            bottom_pane = {
              height = 25,
              preview_cutoff = 120,
              prompt_position = 'top',
            },
            center = {
              height = 0.4,
              mirror = true,
              preview_cutoff = 40,
              prompt_position = 'top',
              width = 0.35,
            },
            cursor = {
              height = 0.5,
              preview_cutoff = 40,
              preview_width = 0.6,
              width = 0.6,
            },
            horizontal = {
              anchor = 'S',
              height = 0.5,
              preview_cutoff = 120,
              preview_width = 0.65,
              prompt_position = 'top',
              mirror = false,
              width = 0.9,
            },
            vertical = {
              anchor = 'NE',
              height = 0.95,
              preview_cutoff = 10,
              preview_width = 0.6,
              prompt_position = 'top',
              mirror = true,
              width = 0.5,
            },
            flex = {
              height = 0.7,
              prompt_position = 'top',
              width = 0.5,
            },
          },
          winblend = 0,
          prompt_prefix = ' ',
          selection_caret = ' ',
          dynamic_preview_title = true,
          file_ignore_patterns = { '^target/' },
          vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--unrestricted',
            '--trim',
            '--glob',
            '!target/',
          },
          -- open files in the first window that is an actual file.
          -- use the current window if no other window is available.
          get_selection_window = function()
            local wins = vim.api.nvim_list_wins()
            table.insert(wins, 1, vim.api.nvim_get_current_win())
            for _, win in ipairs(wins) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].buftype == '' then
                return win
              end
            end
            return 0
          end,
          mappings = {
            i = {
              ['<c-t>'] = open_with_trouble,
              ['<a-t>'] = open_selected_with_trouble,
              ['<a-i>'] = find_files_no_ignore,
              ['<a-h>'] = find_files_with_hidden,
              ['<C-Down>'] = actions.cycle_history_next,
              ['<C-Up>'] = actions.cycle_history_prev,
              ['<C-f>'] = actions.preview_scrolling_down,
              ['<C-b>'] = actions.preview_scrolling_up,
            },
            n = {
              ['q'] = actions.close,
            },
          },
          preview = {
            mime_hook = function(filepath, bufnr, opts)
              local is_image = function(filepath)
                local image_extensions = { 'png', 'jpg' } -- Supported image formats
                local split_path = vim.split(filepath:lower(), '.', { plain = true })
                local extension = split_path[#split_path]
                return vim.tbl_contains(image_extensions, extension)
              end
              if is_image(filepath) then
                local term = vim.api.nvim_open_term(bufnr, {})
                local function send_output(_, data, _)
                  for _, d in ipairs(data) do
                    vim.api.nvim_chan_send(term, d .. '\r\n')
                  end
                end
                vim.fn.jobstart({
                  'catimg',
                  filepath, -- Terminal image viewer command
                }, { on_stdout = send_output, stdout_buffered = true, pty = true })
              else
                require('telescope.previewers.utils').set_preview_message(bufnr, opts.winid, 'Binary cannot be previewed')
              end
            end,
          },
        },
        pickers = {
          buffers = {
            mappings = {
              i = {
                ['<c-d>'] = actions.delete_buffer + actions.move_to_top,
              },
            },
          },
        },
        extensions = {
          egrepify = {
            -- intersect tokens in prompt ala "str1.*str2" that ONLY matches
            -- if str1 and str2 are consecutively in line with anything in between (wildcard)
            AND = true, -- default
            permutations = false, -- opt-in to imply AND & match all permutations of prompt tokens
            lnum = true, -- default, not required
            lnum_hl = 'EgrepifyLnum', -- default, not required, links to `Constant`
            col = false, -- default, not required
            col_hl = 'EgrepifyCol', -- default, not required, links to `Constant`
            title = true, -- default, not required, show filename as title rather than inline
            filename_hl = 'EgrepifyFile', -- default, not required, links to `Title`
            -- suffix = long line, see screenshot
            -- EXAMPLE ON HOW TO ADD PREFIX!
            prefixes = {
              -- ADDED ! to invert matches
              -- example prompt: ! sorter
              -- matches all lines that do not comprise sorter
              -- rg --invert-match -- sorter
              ['!'] = {
                flag = 'invert-match',
              },
              -- HOW TO OPT OUT OF PREFIX
              -- ^ is not a default prefix and safe example
              ['^'] = false,
            },
            -- default mappings
            mappings = {
              i = {
                -- toggle prefixes, prefixes is default
                ['<C-z>'] = egrep_actions.toggle_prefixes,
                -- toggle AND, AND is default, AND matches tokens and any chars in between
                ['<C-a>'] = egrep_actions.toggle_and,
                -- toggle permutations, permutations of tokens is opt-in
                ['<C-r>'] = egrep_actions.toggle_permutations,
              },
            },
          },
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = 'smart_case', -- or "ignore_case" or "respect_case"
          },
          lazy = {
            -- Optional theme (the extension doesn't set a default theme)
            theme = 'ivy',
            -- Whether or not to show the icon in the first column
            show_icon = true,
            -- Mappings for the actions
            mappings = {
              open_in_browser = '<C-o>',
              open_in_file_browser = '<M-b>',
              open_in_find_files = '<C-f>',
              open_in_live_grep = '<C-g>',
              open_in_terminal = '<C-t>',
              open_plugins_picker = '<C-b>', -- Works only after having called first another action
              open_lazy_root_find_files = '<C-r>f',
              open_lazy_root_live_grep = '<C-r>g',
              change_cwd_to_plugin = '<C-c>d',
            },
            -- Configuration that will be passed to the window that hosts the terminal
            -- For more configuration options check 'nvim_open_win()'
            terminal_opts = {
              relative = 'editor',
              style = 'minimal',
              border = 'rounded',
              title = 'Telescope lazy',
              title_pos = 'center',
              width = 0.5,
              height = 0.5,
            },
            -- Other telescope configuration options
          },
        },
        cmdline = {
          picker = {
            layout_config = {
              width = 80,
              height = 15,
            },
          },
          mappings = {
            complete = '<Tab>',
            run_selection = '<C-CR>',
            run_input = '<CR>',
          },
        },
      }
    end,
  },

  -- [telescope-import] - Search and add imports with telescope
  -- see: `:h telescope-import`
  {
    'piersolenski/telescope-import.nvim',
    dependencies = 'nvim-telescope/telescope.nvim',
    -- stylua: ignore
    keys = {
      { '<leader>si', '<cmd>Telescope import layout_strategy=cursor<cr>', mode = { 'n', 'v' }, desc = 'Search Imports [si]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'import'
    end,
  },

  -- [yaml-companion] - Search and apply YAML schema
  -- see: `:h yaml-companion`
  {
    'someone-stole-my-name/yaml-companion.nvim',
    dependencies = { 'neovim/nvim-lspconfig', 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim' },
    keys = {
      { '<leader>sy', '<cmd>Telescope yaml_schema<cr>', mode = { 'n', 'v' }, desc = 'Search YAML Schema [sy]' },
    },
    config = function()
      local cfg = require('yaml-companion').setup {}
      require('lspconfig')['yamlls'].setup(cfg)
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'yaml_schema'
    end,
  },

  -- [telescope-tabs] - Tabs selector with telescope
  -- see: `:h telescope-tabs`
  {
    'LukasPietzschmann/telescope-tabs',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader><tab>s', '<cmd>Telescope telescope-tabs list_tabs<cr>', mode = { 'n', 'v' }, desc = 'List Tabs [<tab>s]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'telescope-tabs'
      require('telescope-tabs').setup {}
    end,
  },

  -- [telescope-undo] - Search undo history with telescope.
  -- see: `:h telescope-undo`
  {
    'debugloop/telescope-undo.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>su', '<cmd>Telescope undo<cr>', desc = 'Undo History [su]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'undo'
    end,
  },

  -- [telescope-egrepify] - Enhanced grepping in Telescope
  -- see: `:h telescope-egrepify`
  {
    'fdschmidt93/telescope-egrepify.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>/', '<cmd>Telescope egrepify<cr>', mode = { 'n', 'v' }, desc = 'Enhanced Grep [/]', },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'egrepify'
    end,
  },

  {
    'rcarriga/nvim-notify',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    -- stylua: ignore
    keys = {
      ---@diagnostic disable-next-line: undefined-field
      { '<leader>sN', function() require('telescope').extensions.notify.notify() end, desc = 'Notifications [sN]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'notify'
    end,
  },

  {
    'nvim-telescope/telescope-fzf-native.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'fzf'
    end,
  },

  {
    'nvim-telescope/telescope-dap.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>dm', '<cmd>Telescope dap commands<cr>', desc = 'DAP Commands [dm]' },
      { '<leader>dn', '<cmd>Telescope dap configurations<cr>', desc = 'DAP Configurations [dn]' },
      { '<leader>dF', '<cmd>Telescope dap frames<cr>', desc = 'DAP Frames [dF]' },
      { '<leader>dB', '<cmd>Telescope dap list_breakpoints<cr>', desc = 'DAP List Breakpoints [dB]' },
      { '<leader>dV', '<cmd>Telescope dap variables<cr>', desc = 'DAP Variables [dV]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'dap'
    end,
  },

  {
    'tsakirist/telescope-lazy.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>sl', '<cmd>Telescope lazy<cr>', mode = { 'n', 'v' }, desc = 'List Lazy Plugins [sl]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'lazy'
    end,
  },

  {
    'paopaol/telescope-git-diffs.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim', 'sindrets/diffview.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>gc', '<cmd>Telescope git_diffs diff_commits<cr>', mode = { 'n', 'v' }, desc = 'Search Commits [gc]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'git_diffs'
    end,
  },

  {
    'benfowler/telescope-luasnip.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>sL', '<cmd>Telescope luasnip<cr>', mode = { 'n', 'v' }, desc = 'Search Snippets [sL]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'luasnip'
    end,
  },

  {
    'FeiyouG/commander.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    keys = {
      { '<leader>.', '<CMD>Telescope commander<CR>', mode = 'n', desc = 'Commander [.]' },
    },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('commander').setup {
        components = {
          'DESC',
          'KEYS',
          'CAT',
        },
        sort_by = {
          'DESC',
          'KEYS',
          'CAT',
          'CMD',
        },
        integration = {
          telescope = {
            enable = true,
          },
          lazy = {
            enable = true,
            set_plugin_name_as_cat = true,
          },
        },
      }
    end,
  },

  {
    'LinArcX/telescope-ports.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>sp', '<cmd>Telescope ports<cr>', mode = { 'n', 'v' }, desc = 'List Open Ports [sp]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'ports'
    end,
  },

  {
    'lpoto/telescope-docker.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    keys = {
      { '<leader>fD', '<Cmd>Telescope docker<CR>', desc = 'Docker [fD]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'docker'
    end,
  },

  {
    'ANGkeith/telescope-terraform-doc.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'terraform_doc'
    end,
  },

  {
    'cappyzawa/telescope-terraform.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'terraform'
    end,
  },

  {
    'fbuchlak/telescope-directory.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    -- stylua: ignore
    keys = {
      { '<Leader>fd', '<CMD>Telescope directory live_grep<CR>',  desc = 'Search Text in Directory [fd]', },
      { '<Leader>fe', '<CMD>Telescope directory find_files<CR>', desc = 'Search Files in Directory [fe]' },
    },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('telescope-directory').setup {}
    end,
  },

  {
    'isak102/telescope-git-file-history.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim', 'tpope/vim-fugitive' },
    keys = {
      { '<leader>fh', '<CMD>Telescope git_file_history<CR>', desc = 'Search File History [fh]' },
    },
    config = function()
      require('telescope').load_extension 'git_file_history'
    end,
  },
}
