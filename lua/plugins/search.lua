local Util = require 'util'

return {

  -- [[ SEARCHING AND REPLACING ]] ---------------------------------------------------------------

  -- [ssr.nvim] - Search and replace in-file
  -- see: `:h ssr.nvim`
  -- link: https://github.com/cshuaimin/ssr.nvim
  {
    'cshuaimin/ssr.nvim',
    branch = 'main',
    event = 'VeryLazy',
    module = 'ssr',
    -- stylua: ignore
    keys = {
      { '<leader>se', function() require('ssr').open() end, mode = { 'n', 'v' }, desc = 'Search and Replace (Buffer) [se]' },
    },
    config = function()
      require('ssr').setup {
        border = 'rounded',
        min_width = 50,
        min_height = 5,
        max_width = 120,
        max_height = 25,
        adjust_window = true,
        keymaps = {
          close = 'q',
          next_match = 'n',
          prev_match = 'N',
          replace_confirm = '<cr>',
          replace_all = '<leader><cr>',
        },
      }
    end,
  },

  -- [nvim-spectre] - Search files with replace option
  -- see: `:h nvim-spectre`
  -- link: https://github.com/cshuaimin/ssr.nvim
  {
    'nvim-pack/nvim-spectre',
    branch = 'master',
    event = 'VeryLazy',
    build = false,
    cmd = 'Spectre',
    -- stylua: ignore
    keys = {
      { '<leader>sr', function() require('spectre').open() end, desc = 'Search and Replace [sr]' },
    },
    opts = { open_cmd = 'noswapfile vnew' },
  },

  -- [leap.nvim] - Jump in code with s and S keys
  -- see: `:h leap.nvim`
  -- link: https://github.com/ggandor/leap.nvim
  {
    'ggandor/leap.nvim',
    branch = 'main',
    event = 'VeryLazy',
    keys = {
      { 's',  mode = { 'n', 'x', 'o' }, desc = 'Leap forward to <s>' },
      { 'S',  mode = { 'n', 'x', 'o' }, desc = 'Leap backward to <S>' },
      { 'gs', mode = { 'n', 'x', 'o' }, desc = 'Leap from windows <gs>' },
    },
    config = function(_, opts)
      local leap = require 'leap'
      for k, v in pairs(opts) do
        leap.opts[k] = v
      end
      leap.add_default_mappings(true)
      vim.keymap.del({ 'x', 'o' }, 'x')
      vim.keymap.del({ 'x', 'o' }, 'X')
    end,
  },

  -- [improved-search] - Enhance searching with n and N keys
  -- see: `:h improved-search`
  -- link: https://github.com/backdround/improved-search.nvim
  {
    'backdround/improved-search.nvim',
    branch = 'main',
    event = 'VeryLazy',
    config = function()
      local search = require 'improved-search'
      -- Search next / previous.
      vim.keymap.set({ 'n', 'x', 'o' }, 'n', search.stable_next)
      vim.keymap.set({ 'n', 'x', 'o' }, 'N', search.stable_previous)
      -- Search current word without moving.
      vim.keymap.set('n', '!', search.current_word)
      -- Search selected text in visual mode
      vim.keymap.set('x', '!', search.in_place) -- search selection without moving
      vim.keymap.set('x', '*', search.forward)  -- search selection forward
      vim.keymap.set('x', '#', search.backward) -- search selection backward
      -- Search by motion in place
      vim.keymap.set('n', '|', search.in_place)
      -- You can also use search.forward / search.backward for motion selection.
    end,
  },
}
