local Util = require 'util'

return {

  -- [[ SEARCHING AND REPLACING ]] ---------------------------------------------------------------

  -- search/replace in multiple files
  {
    "MagicDuck/grug-far.nvim",
    opts = { headerMaxWidth = 80 },
    cmd = "GrugFar",
    keys = {
      {
        "<leader>sr",
        function()
          local grug = require("grug-far")
          local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
          grug.open({
            transient = true,
            prefills = {
              filesFilter = ext and ext ~= "" and "*." .. ext or nil,
            },
          })
        end,
        mode = { "n", "v" },
        desc = "Search and Replace",
      },
    },
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
