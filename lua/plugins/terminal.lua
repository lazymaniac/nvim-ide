return {

  -- [[ TERMINAL ]] ---------------------------------------------------------------
  -- [toggleterm.nvim] - Terminal integration in nvim
  -- see: `:h toggleterm`
  {
    'akinsho/toggleterm.nvim',
    event = 'VeryLazy',
    version = false,
    -- stylua: ignore
    keys = {
      { '<leader>an', '<cmd>lua _NODE_TOGGLE()<cr>', mode = { 'n' }, desc = 'node [an]', },
      { '<leader>au', '<cmd>lua _NCDU_TOGGLE()<cr>', mode = { 'n' }, desc = 'ncdu [au]', },
      { '<leader>ab', '<cmd>lua _BTOP_TOGGLE()<cr>', mode = { 'n' }, desc = 'btop [ab]', },
      { '<leader>ap', '<cmd>lua _PYTHON_TOGGLE()<cr>', mode = { 'n' }, desc = 'Python [ap]', },
      { '<leader>ad', '<cmd>lua _LAZYDOCKER_TOGGLE()<cr>', mode = { 'n' }, desc = 'Lazydocker [ad]', },
      { '<leader>as', '<cmd>lua _LAZYSQL_TOGGLE()<cr>', mode = { 'n' }, desc = 'Lazysql [as]', },
      { '<leader>ag', '<cmd>lua _LAZYGIT_TOGGLE()<cr>', mode = { 'n' }, desc = 'Lazygit [ag]', },
      { '<leader>af', '<cmd>ToggleTerm direction=float<cr>', mode = { 'n' }, desc = 'Floating Terminal [af]', },
      { '<leader>av', '<cmd>ToggleTerm direction=vertical<cr>', mode = { 'n' }, desc = 'Vertical Split Terminal [av]', },
      { '<leader>ah', '<cmd>ToggleTerm direction=horizontal<cr>', mode = { 'n' }, desc = 'Horizontal Split Terminal [ah]', },
      { '<leader>at', '<cmd>ToggleTerm direction=tab<cr>', mode = { 'n' }, desc = 'Terminal In Tab [at]', },
      { '<leader>a1', '<cmd>ToggleTerm 1<cr>', mode = { 'n' }, desc = 'Terminal 1 [a1]', },
      { '<leader>a2', '<cmd>ToggleTerm 2<cr>', mode = { 'n' }, desc = 'Terminal 2 [a2]', },
      { '<leader>a3', '<cmd>ToggleTerm 3<cr>', mode = { 'n' }, desc = 'Terminal 3 [a3]', },
      { '<leader>a4', '<cmd>ToggleTerm 4<cr>', mode = { 'n' }, desc = 'Terminal 4 [a4]', },
    },
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
  },
}
