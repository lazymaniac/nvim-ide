local Util = require 'util'

return {

  -- [[ TELESCOPE ]] ---------------------------------------------------------------

  -- [telescope.nvim] - Fuzzy finder for project files
  -- see: `:h telescope`
  -- link: https://github.com/nvim-telescope/telescope.nvim
  {
    'nvim-telescope/telescope.nvim',
    branch = 'master',
    event = 'VeryLazy',
    cmd = 'Telescope',
    -- stylua: ignore
    keys = {
      -- search
      { '<leader>p', '<cmd>Telescope registers layout_strategy=vertical<cr>', desc = 'Registers [s"]', },
      { '<leader>sP', function() require('telescope.builtin').find_files { cwd = require('lazy.core.config').options.root, layout_strategy = 'vertical' } end, desc = 'Search Plugin File [sP]', },
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
          fzf = {
            fuzzy = true, -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true, -- override the file sorter
            case_mode = 'smart_case', -- or "ignore_case" or "respect_case"
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

  -- [yaml-companion] - Search and apply YAML schema
  -- see: `:h yaml-companion`
  -- link: https://github.com/someone-stole-my-name/yaml-companion.nvim
  {
    'someone-stole-my-name/yaml-companion.nvim',
    branch = 'main',
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

  -- [telescope-fzf-native.nvim] - Power telescope search with fzf
  -- see: `:h telescope-fzf-native.nvim`
  -- link: https://github.com/nvim-telescope/telescope-fzf-native.nvim
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    branch = 'main',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'fzf'
    end,
  },

  -- [telescope-dap.nvim] - Integratio of nvim-dap with telescope
  -- see: `:h telescope-dap.nvim`
  -- link: https://github.com/nvim-telescope/telescope-dap.nvim
  {
    'nvim-telescope/telescope-dap.nvim',
    branch = 'master',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>dn', '<cmd>Telescope dap configurations<cr>',   desc = 'DAP Configurations [dn]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'dap'
    end,
  },

  -- [telescope-git-diffs] - Telescope picker for git diffs before commit.
  -- see: `:h telescope-git-diffs`
  -- link: https://github.com/paopaol/telescope-git-diffs.nvim
  {
    'paopaol/telescope-git-diffs.nvim',
    branch = 'main',
    dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim', 'sindrets/diffview.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>gC', '<cmd>Telescope git_diffs diff_commits<cr>', mode = { 'n', 'v' }, desc = 'Search Commits [gc]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'git_diffs'
    end,
  },

  -- [telescope-luasnip] - Telescope picker for luasnip.
  -- see: `:h telescope-luasnip`
  -- link: https://github.com/benfowler/telescope-luasnip.nvim
  {
    'benfowler/telescope-luasnip.nvim',
    branch = 'master',
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

  -- [telescope-docker] - Telecope picker for docker stuff.
  -- see: `:h telescope-docker`
  -- link: https://github.com/lpoto/telescope-docker.nvim
  {
    'lpoto/telescope-docker.nvim',
    branch = 'main',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    keys = {
      { '<leader>fd', '<Cmd>Telescope docker<CR>', desc = 'Docker [fd]' },
    },
    config = function()
      ---@diagnostic disable-next-line: undefined-field
      require('telescope').load_extension 'docker'
    end,
  },

  -- [telescope-git-file-history] - Telescope pcker for git file history.
  -- see: `:h telescope-git-file-history`
  -- link: https://github.com/isak102/telescope-git-file-history.nvim
  {
    'isak102/telescope-git-file-history.nvim',
    branch = 'master',
    dependencies = { 'nvim-telescope/telescope.nvim', 'tpope/vim-fugitive' },
    keys = {
      { '<leader>fh', '<CMD>Telescope git_file_history<CR>', desc = 'Search File History [fh]' },
    },
    config = function()
      require('telescope').load_extension 'git_file_history'
    end,
  },
}
