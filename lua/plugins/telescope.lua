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
      { '<leader><space>', Util.telescope 'files', desc = 'Find Files (root dir)' },
      -- find
      { '<leader>fb', '<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>', desc = '[B]uffers' },
      { '<leader>fc', Util.telescope.config_files(), desc = 'Find [C]onfig File' },
      { '<leader>ff', Util.telescope 'files', desc = 'Find [F]iles (root dir)' },
      { '<leader>fF', Util.telescope('files', { cwd = false }), desc = 'Find [F]iles (cwd)' },
      { '<leader>fr', '<cmd>Telescope oldfiles<cr>', desc = '[R]ecent' },
      { '<leader>fR', Util.telescope('oldfiles', { cwd = vim.loop.cwd() }), desc = '[R]ecent (cwd)' },
      -- git
      { '<leader>gc', '<cmd>Telescope git_commits<CR>', desc = 'Git [C]ommits' },
      { '<leader>gs', '<cmd>Telescope git_status<CR>', desc = 'Git [S]tatus' },
      -- search
      { '<leader>s"', '<cmd>Telescope registers<cr>', desc = 'Registers ["]' },
      { '<leader>sa', '<cmd>Telescope autocommands<cr>', desc = '[A]uto Commands' },
      { '<leader>sb', '<cmd>Telescope current_buffer_fuzzy_find<cr>', desc = 'Fzf [B]uffer' },
      { '<leader>sc', '<cmd>Telescope command_history<cr>', desc = '[C]ommand History' },
      { '<leader>sC', '<cmd>Telescope commands<cr>', desc = '[C]ommands' },
      { '<leader>sd', '<cmd>Telescope diagnostics bufnr=0<cr>', desc = 'Document [D]iagnostics' },
      { '<leader>sD', '<cmd>Telescope diagnostics<cr>', desc = '[W]orkspace Diagnostics' },
      { '<leader>sg', Util.telescope 'live_grep', desc = '[G]rep (root dir)' },
      { '<leader>sG', Util.telescope('live_grep', { cwd = false }), desc = '[G]rep (cwd)' },
      { '<leader>sh', '<cmd>Telescope help_tags<cr>', desc = '[H]elp Pages' },
      { '<leader>sH', '<cmd>Telescope highlights<cr>', desc = 'Search [H]ighlight Groups' },
      { '<leader>sk', '<cmd>Telescope keymaps<cr>', desc = '[K]ey Maps' },
      { '<leader>sM', '<cmd>Telescope man_pages<cr>', desc = '[M]an Pages' },
      { '<leader>sm', '<cmd>Telescope marks<cr>', desc = 'Jump to [M]ark' },
      { '<leader>so', '<cmd>Telescope vim_options<cr>', desc = '[O]ptions' },
      { '<leader>sR', '<cmd>Telescope resume<cr>', desc = '[R]esume' },
      { '<leader>sw', Util.telescope('grep_string', { word_match = '-w' }), desc = '[W]ord (root dir)' },
      { '<leader>sW', Util.telescope('grep_string', { cwd = false, word_match = '-w' }), desc = '[W]ord (cwd)' },
      { '<leader>sw', Util.telescope 'grep_string', mode = 'v', desc = 'Selection (root dir)' },
      { '<leader>sW', Util.telescope('grep_string', { cwd = false }), mode = 'v', desc = 'Selection (cwd)' },
      { '<leader>uC', Util.telescope('colorscheme', { enable_preview = true }), desc = '[C]olorscheme with preview' },
      { '<leader>ss', function() require('telescope.builtin').lsp_document_symbols {} end, desc = 'Goto [S]ymbol' },
      { '<leader>sS', function() require('telescope.builtin').lsp_dynamic_workspace_symbols {} end, desc = 'Goto [S]ymbol (Workspace)' },
      ---@diagnostic disable-next-line: undefined-field
      { '<leader>sN', function() require('telescope').extensions.notify.notify() end, desc = '[N]otifications' },
      { '<leader>fp', function() require('telescope.builtin').find_files { cwd = require('lazy.core.config').options.root } end, desc = 'Find [P]lugin File' },
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
      { '<leader>si', '<cmd>Telescope import<cr>', mode = { 'n', 'v' }, desc = 'Search Imports' },
    },
    config = function()
      require('telescope').load_extension 'import'
    end,
  },

  -- [yaml-companion] - Search and apply YAML schema
  -- see: `:h yaml-companion`
  {
    'someone-stole-my-name/yaml-companion.nvim',
    dependencies = { 'neovim/nvim-lspconfig', 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim' },
    keys = {
      { '<leader>sy', '<cmd>Telescope yaml_schema<cr>', mode = { 'n', 'v' }, desc = 'Search YAML Schema' },
    },
    config = function()
      local cfg = require('yaml-companion').setup {}
      require('lspconfig')['yamlls'].setup(cfg)
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
      { '<leader><tab>s', '<cmd>Telescope telescope-tabs list_tabs<cr>', mode = { 'n', 'v' }, desc = 'List Tabs' },
    },
    config = function()
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
      { '<leader>su', '<cmd>Telescope undo<cr>', desc = 'Undo History' },
    },
    config = function()
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
      { '<leader>/', '<cmd>Telescope egrepify<cr>', mode = { 'n', 'v' }, desc = 'Enhanced Grep', },
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
      require('telescope').load_extension 'egrepify'
    end,
  },

  {
    'rcarriga/nvim-notify',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('telescope').load_extension 'notify'
    end,
  },

  {
    'nvim-telescope/telescope-fzf-native.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>sf', '<cmd>Telescope fzf<cr>', mode = { 'n', 'v' }, desc = 'Search FZF' },
    },
    build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
    config = function()
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
      require('telescope').load_extension 'fzf'
    end,
  },

  {
    'nvim-telescope/telescope-dap.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('telescope').load_extension 'dap'
    end,
  },
}
