return {

  -- [[ TERMINAL ]] ---------------------------------------------------------------

  -- [toggleterm.nvim] - Terminal integration in nvim
  -- see: `:h toggleterm`
  -- link: https://github.com/akinsho/toggleterm.nvim
  {
    'akinsho/toggleterm.nvim',
    branch = 'main',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      { '<leader>an', '<cmd>lua _NODE_TOGGLE()<cr>',                                mode = { 'n' }, desc = 'node [an]', },
      { '<leader>au', '<cmd>lua _NCDU_TOGGLE()<cr>',                                mode = { 'n' }, desc = 'ncdu [au]', },
      { '<leader>ab', '<cmd>lua _BTOP_TOGGLE()<cr>',                                mode = { 'n' }, desc = 'btop [ab]', },
      { '<leader>ap', '<cmd>lua _PYTHON_TOGGLE()<cr>',                              mode = { 'n' }, desc = 'Python [ap]', },
      { '<leader>ad', '<cmd>lua _LAZYDOCKER_TOGGLE()<cr>',                          mode = { 'n' }, desc = 'Lazydocker [ad]', },
      { '<leader>as', '<cmd>lua _LAZYSQL_TOGGLE()<cr>',                             mode = { 'n' }, desc = 'Lazysql [as]', },
      { '<leader>ag', '<cmd>lua _LAZYGIT_TOGGLE()<cr>',                             mode = { 'n' }, desc = 'Lazygit [ag]', },
      { '<leader>af', '<cmd>ToggleTerm direction=float name="Terminal 1"<cr>',      mode = { 'n' }, desc = 'Floating Terminal [af]', },
      { '<leader>av', '<cmd>ToggleTerm direction=vertical name="Terminal 1"<cr>',   mode = { 'n' }, desc = 'Vertical Split Terminal [av]', },
      { '<leader>ah', '<cmd>ToggleTerm direction=horizontal name="Terminal 1"<cr>', mode = { 'n' }, desc = 'Horizontal Split Terminal [ah]', },
      { '<leader>at', '<cmd>ToggleTerm direction=tab name="Terminal 1"<cr>',        mode = { 'n' }, desc = 'Terminal In Tab [at]', },
      { '<leader>a1', '<cmd>ToggleTerm 1 name="Terminal 1"<cr>',                    mode = { 'n' }, desc = 'Terminal 1 [a1]', },
      { '<leader>a2', '<cmd>ToggleTerm 2 name="Terminal 2"<cr>',                    mode = { 'n' }, desc = 'Terminal 2 [a2]', },
      { '<leader>a3', '<cmd>ToggleTerm 3 name="Terminal 3"<cr>',                    mode = { 'n' }, desc = 'Terminal 3 [a3]', },
      { '<leader>a4', '<cmd>ToggleTerm 4 name="Terminal 4"<cr>',                    mode = { 'n' }, desc = 'Terminal 4 [a4]', },
      { '<leader>aa', '<cmd>ToggleTermToggleAll<cr>',                               mode = { 'n' }, desc = 'Toggle All Terminals [aa]', },
      { '<leader>al', '<cmd>TermSelect<cr>',                                        mode = { 'n' }, desc = 'List Active Terminals [al]', },
      { '<leader>ar', '<cmd>ToggleTermSetName<cr>',                                 mode = { 'n' }, desc = 'Rename Terminal [ar]', },
      { '<leader>ae', '<cmd>ToggleTermSendVisualSelection<cr>',                     mode = { 'v' }, desc = 'Execute Selection in Terminal [ae]', },
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
      shade_terminals = false,
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
        width = math.floor(vim.o.columns * 0.9),
        height = math.floor(vim.o.lines * 0.9),
      },
      winbar = {
        enabled = true,
        name_formatter = function(term) --  term: Terminal
          return term.name
        end,
      },
    },
  },
}
