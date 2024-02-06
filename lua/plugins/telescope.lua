local Util = require 'util'

return {

  -- [[ TELESCOPE ]] ---------------------------------------------------------------

  -- [telescope.nvim] - Fuzzy finder for project files
  -- see: `:h telescope`
  {
    'nvim-telescope/telescope.nvim',
    event = 'VeryLazy',
    cmd = 'Telescope',
    version = false, -- telescope did only one release, so use HEAD for now
    -- stylua: ignore
    keys = {
      { '<leader>,', '<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>', desc = 'Switch Buffer [,]' },
      { '<leader>:', '<cmd>Telescope command_history<cr>', desc = 'Command History [:]' },
      { '<leader><space>', Util.telescope 'files', desc = 'Find Files (root dir) [SPC]' },
      -- find
      { '<leader>fb', '<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>', desc = 'Buffers [fb]' },
      { '<leader>fc', Util.telescope.config_files(), desc = 'Find Config File [fc]' },
      { '<leader>ff', Util.telescope 'files', desc = 'Find Files (root dir) [ff]' },
      { '<leader>fF', Util.telescope('files', { cwd = false }), desc = 'Find Files (cwd) [fF]' },
      { '<leader>fr', '<cmd>Telescope oldfiles<cr>', desc = 'Recent [fr]' },
      { '<leader>fR', Util.telescope('oldfiles', { cwd = vim.loop.cwd() }), desc = 'Recent (cwd) [fR]' },
      -- git
      { '<leader>gc', '<cmd>Telescope git_commits<CR>', desc = 'Git Commits [gc]' },
      { '<leader>gs', '<cmd>Telescope git_status<CR>', desc = 'Git Status [gd]' },
      -- search
      { '<leader>s"', '<cmd>Telescope registers<cr>', desc = 'Registers [s"]' },
      { '<leader>sa', '<cmd>Telescope autocommands<cr>', desc = 'Auto Commands [sa]' },
      { '<leader>sb', '<cmd>Telescope current_buffer_fuzzy_find<cr>', desc = 'Fzf Buffer [sb]' },
      { '<leader>sc', '<cmd>Telescope command_history<cr>', desc = 'Command History [sc]' },
      { '<leader>sC', '<cmd>Telescope commands<cr>', desc = 'Commands [sC]' },
      { '<leader>sd', '<cmd>Telescope diagnostics bufnr=0<cr>', desc = 'Document Diagnostics [sd]' },
      { '<leader>sD', '<cmd>Telescope diagnostics<cr>', desc = 'Workspace Diagnostics [sD]' },
      { '<leader>sg', Util.telescope 'live_grep', desc = 'Grep (root dir) [sg]' },
      { '<leader>sG', Util.telescope('live_grep', { cwd = false }), desc = 'Grep (cwd) [sG]' },
      { '<leader>sh', '<cmd>Telescope help_tags<cr>', desc = 'Help Pages [sh]' },
      { '<leader>sH', '<cmd>Telescope highlights<cr>', desc = 'Search Highlight Groups [sH]' },
      { '<leader>sk', '<cmd>Telescope keymaps<cr>', desc = 'Key Maps [sk]' },
      { '<leader>sM', '<cmd>Telescope man_pages<cr>', desc = 'Man Pages [sM]' },
      { '<leader>sm', '<cmd>Telescope marks<cr>', desc = 'Jump to Mark [sm]' },
      { '<leader>so', '<cmd>Telescope vim_options<cr>', desc = 'Options [so]' },
      { '<leader>sR', '<cmd>Telescope resume<cr>', desc = 'Resume Last Search [sR]' },
      { '<leader>sw', Util.telescope('grep_string', { word_match = '-w' }), desc = 'Word (root dir) [sw]' },
      { '<leader>sW', Util.telescope('grep_string', { cwd = false, word_match = '-w' }), desc = 'Word (cwd) [sW]' },
      { '<leader>sw', Util.telescope 'grep_string', mode = 'v', desc = 'Selection (root dir) [sw]' },
      { '<leader>sW', Util.telescope('grep_string', { cwd = false }), mode = 'v', desc = 'Selection (cwd) [sW]' },
      { '<leader>uC', Util.telescope('colorscheme', { enable_preview = true }), desc = 'Colorscheme with preview [uC]' },
      { '<leader>ss', function() require('telescope.builtin').lsp_document_symbols {} end, desc = 'Goto Symbol [ss]' },
      { '<leader>sS', function() require('telescope.builtin').lsp_dynamic_workspace_symbols {} end, desc = 'Goto Symbol (Workspace) [sS]' },
      { '<leader>fp', function() require('telescope.builtin').find_files { cwd = require('lazy.core.config').options.root } end, desc = 'Find Plugin File [fp]' },
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
      return {
        defaults = {
          layout_strategy = 'vertical',
          layout_config = { prompt_position = 'bottom' },
          sorting_strategy = 'ascending',
          winblend = 0,
          prompt_prefix = ' ',
          selection_caret = ' ',
          vimgrep_arguments = {
            'rg',
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
            '--smart-case',
            '--unrestricted',
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
      { '<leader>si', '<cmd>Telescope import<cr>', mode = { 'n', 'v' }, desc = 'Search Imports [si]' },
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
      local egrep_actions = require 'telescope._extensions.egrepify.actions'
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').setup {
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
        },
      }
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
    -- stylua: ignore
    keys = {
      { '<leader>sf', '<cmd>Telescope fzf<cr>', mode = { 'n', 'v' }, desc = 'Search FZF [sf]' },
    },
    build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').setup {
        extensions = {
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = 'smart_case', -- or "ignore_case" or "respect_case"
            -- the default case_mode is "smart_case"
          },
        },
      }
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
      require('telescope').setup {
        extensions = {
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
      }
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
    'nvim-telescope/telescope-frecency.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>F', '<cmd>Telescope frecency workspace=CWD<cr>', mode = { 'n', 'v' }, desc = 'Frecent Files [F]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').setup {
        extensions = {
          frecency = {
            show_scores = true,
            show_unindexed = true,
            ignore_patterns = { '*.git/*', '*/tmp/*', '*/target/*', '*/build/*' },
            disable_devicons = false,
          },
        },
      }
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'frecency'
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
    'jonarrien/telescope-cmdline.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    keys = {
      { ':', '<Cmd>Telescope cmdline<CR>', desc = 'CMD [:]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').setup {
        extensions = {
          cmdline = {
            picker = {
              layout_config = {
                width = 120,
                height = 25,
              },
            },
            mappings = {
              complete = '<Tab>',
              run_selection = '<C-CR>',
              run_input = '<CR>',
            },
          },
        },
      }
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'cmdline'
    end,
  },

  {
    'fbuchlak/telescope-directory.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    -- stylua: ignore
    keys = {
      { '<Leader>fd', '<CMD>Telescope directory live_grep<CR>', desc = 'Search Text in Directory [fd]', },
      { '<Leader>fe', '<CMD>Telescope directory find_files<CR>', desc = 'Search Files in Directory [fe]' },
    },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('telescope-directory').setup {}
    end,
  },
}
