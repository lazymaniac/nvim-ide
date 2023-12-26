return {
  -- edgy
  {
    'folke/edgy.nvim',
    enabled = true,
    event = 'VeryLazy',
    keys = {
      {
        '<leader>ue',
        function()
          require('edgy').toggle()
        end,
        desc = 'Edgy Toggle',
      },
      -- stylua: ignore
      { "<leader>uE", function() require("edgy").select() end, desc = "Edgy Select Window" },
    },
    opts = function()
      local opts = {
        bottom = {
          {
            ft = 'toggleterm',
            size = { height = 0.4 },
            filter = function(buf, win)
              return vim.api.nvim_win_get_config(win).relative == ''
            end,
          },
          {
            ft = 'noice',
            size = { height = 0.4 },
            filter = function(buf, win)
              return vim.api.nvim_win_get_config(win).relative == ''
            end,
          },
          {
            ft = 'lazyterm',
            title = 'LazyTerm',
            size = { height = 0.4 },
            filter = function(buf)
              return not vim.b[buf].lazyterm_cmd
            end,
          },
          'Trouble',
          {
            ft = 'trouble',
            filter = function(buf, win)
              return vim.api.nvim_win_get_config(win).relative == ''
            end,
          },
          { ft = 'qf', title = 'QuickFix' },
          { title = 'Spectre', ft = 'spectre_panel', size = { height = 0.4 } },
          { title = 'Neotest Output', ft = 'neotest-output-panel', size = { height = 15 } },
        },
        left = {
          { title = 'Neotest Summary', ft = 'neotest-summary' },
        },
        keys = {
          -- increase width
          ['<c-Right>'] = function(win)
            win:resize('width', 2)
          end,
          -- decrease width
          ['<c-Left>'] = function(win)
            win:resize('width', -2)
          end,
          -- increase height
          ['<c-Up>'] = function(win)
            win:resize('height', 2)
          end,
          -- decrease height
          ['<c-Down>'] = function(win)
            win:resize('height', -2)
          end,
        },
      }
      return opts
    end,
  },

  -- use edgy's selection window
  {
    'nvim-telescope/telescope.nvim',
    optional = true,
    opts = {
      defaults = {
        get_selection_window = function()
          require('edgy').goto_main()
          return 0
        end,
      },
    },
  },

  -- prevent neo-tree from opening files in edgy windows
  {
    'nvim-neo-tree/neo-tree.nvim',
    optional = true,
    opts = function(_, opts)
      opts.open_files_do_not_replace_types = opts.open_files_do_not_replace_types or { 'terminal', 'Trouble', 'qf', 'Outline', 'trouble' }
      table.insert(opts.open_files_do_not_replace_types, 'edgy')
    end,
  },

  -- Fix bufferline offsets when edgy is loaded
  {
    'akinsho/bufferline.nvim',
    optional = true,
    opts = function()
      local Offset = require 'bufferline.offset'
      if not Offset.edgy then
        local get = Offset.get
        Offset.get = function()
          if package.loaded.edgy then
            local layout = require('edgy.config').layout
            local ret = { left = '', left_size = 0, right = '', right_size = 0 }
            for _, pos in ipairs { 'left', 'right' } do
              local sb = layout[pos]
              if sb and #sb.wins > 0 then
                local title = ' Sidebar' .. string.rep(' ', sb.bounds.width - 8)
                ret[pos] = '%#EdgyTitle#' .. title .. '%*' .. '%#WinSeparator#│%*'
                ret[pos .. '_size'] = sb.bounds.width
              end
            end
            ret.total_size = ret.left_size + ret.right_size
            if ret.total_size > 0 then
              return ret
            end
          end
          return get()
        end
        Offset.edgy = true
      end
    end,
  },
}
