return {

  -- tokyonight
  {
    'folke/tokyonight.nvim',
    opts = { style = 'moon' },
  },

  { 'calind/selenized.nvim' },

  -- catppuccin
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    opts = {
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { 'undercurl' },
            hints = { 'undercurl' },
            warnings = { 'undercurl' },
            information = { 'undercurl' },
          },
        },
        navic = { enabled = true, custom_bg = 'lualine' },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        semantic_tokens = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    },
  },
  {
    'sainnhe/everforest',
    init = function()
      vim.cmd [[let g:everforest_background = 'hard']]
    end,
  },

  {
    'oxfist/night-owl.nvim',
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
  },
  {
    'bluz71/vim-moonfly-colors',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.syntax 'enable'
      vim.cmd.colorscheme 'moonfly'

      vim.api.nvim_set_hl(0, 'MoltenOutputBorder', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'MoltenOutputBorderFail', { link = 'MoonflyCrimson' })
      vim.api.nvim_set_hl(0, 'MoltenOutputBorderSuccess', { link = 'MoonflyBlue' })
    end,
  },
  {
    'scottmckendry/cyberdream.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('cyberdream').setup {
        -- Recommended - see "Configuring" below for more config options
        transparent = true,
        italic_comments = true,
        hide_fillchars = true,
        borderless_telescope = true,
      }
    end,
  },
  {
    'fynnfluegge/monet.nvim',
    name = 'monet',
    config = function()
      require('monet').setup {
        transparent_background = true,
        semantic_tokens = true,
        highlight_overrides = {},
        color_overrides = {},
        styles = {
          strings = { 'italic' },
        },
      }
    end,
  },
}
