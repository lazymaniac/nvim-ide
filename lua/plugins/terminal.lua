return {
  {
    'akinsho/toggleterm.nvim',
    version = false,
    opts = {
      size = function(term)
        if term.direction == 'horizontal' then
          return 10
        elseif term.direction == 'vertical' then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = -10,
      start_in_insert = true,
      insert_mappings = true,
      persist_mode = false,
      persist_size = false,
      direction = 'float',
      close_on_exit = true,
      shell = vim.o.shell,
      auto_scroll = true,
      float_opts = {
        border = 'curved', -- 'single' | 'double' | 'shadow' | 'curved' | ... other
        winblend = 10,
        highlights = {
          border = 'Normal',
          background = 'Normal',
        },
      },
      winbar = {
        enabled = false,
        name_formatter = function(term) --  term: Terminal
          return term.name
        end,
      },
    },
    keys = {
      {
        '<leader>an',
        '<cmd>lua _NODE_TOGGLE()<cr>',
        mode = { 'n' },
        desc = 'Termin[a]l [n]ode',
      },
      {
        '<leader>au',
        '<cmd>lua _NCDU_TOGGLE()<cr>',
        mode = { 'n' },
        desc = 'Termin[al ncd[u]',
      },
      {
        '<leader>ab',
        '<cmd>lua _BTOP_TOGGLE()<cr>',
        mode = { 'n' },
        desc = 'Termin[a]l [b]top',
      },
      {
        '<leader>ap',
        '<cmd>lua _PYTHON_TOGGLE()<cr>',
        mode = { 'n' },
        desc = 'Termin[a]l [p]ython',
      },
      {
        '<leader>af',
        '<cmd>ToggleTerm direction=float<cr>',
        mode = { 'n' },
        desc = 'Termin[a]l [f]floating',
      },
      {
        '<leader>av',
        '<cmd>ToggleTerm direction=vertical<cr>',
        mode = { 'n' },
        desc = 'Termin[a]l [v]ertical',
      },
      {
        '<leader>ah',
        '<cmd>ToggleTerm direction=horizontal<cr>',
        mode = { 'n' },
        desc = 'Termin[a]l [h]orizontal',
      },
      {
        '<leader>at',
        '<cmd>ToggleTerm direction=tab<cr>',
        mode = { 'n' },
        desc = 'Termin[a]l [t]ab',
      },
    },
  },
}
