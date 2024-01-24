return {

  -- tokyonight
  {
    'folke/tokyonight.nvim',
    opts = { style = 'moon' },
  },

  -- catppuccin
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        flavour = 'mocha', -- latte, frappe, macchiato, mocha
        background = { -- :h background
          light = 'latte',
          dark = 'mocha',
        },
        aransparent_background = false, -- disables setting the background color.
        show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
        term_colors = false, -- sets terminal colors (e.g. `g:terminal_color_0`)
        dim_inactive = {
          enabled = true, -- dims the background color of inactive window
          shade = 'dark',
          percentage = 0.15, -- percentage of the shade to apply to the inactive window
        },
        no_italic = false, -- Force no italic
        no_bold = false, -- Force no bold
        no_underline = false, -- Force no underline
        styles = { -- Handles the styles of general hi groups (see `:h highlight-args`):
          comments = { 'italic', 'bold' }, -- Change the style of comments
          conditionals = { 'italic' },
          loops = { 'italic' },
          functions = { 'italic' },
          keywords = { 'italic', 'bold' },
          strings = { 'italic' },
          variables = { 'bold' },
          numbers = {},
          booleans = { 'italic', 'bold' },
          properties = {},
          types = { 'italic', 'bold' },
          operators = { 'bold' },
        },
        color_overrides = {
          latte = {
            rosewater = '#c14a4a',
            flamingo = '#c14a4a',
            red = '#c14a4a',
            maroon = '#c14a4a',
            pink = '#945e80',
            mauve = '#945e80',
            peach = '#c35e0a',
            yellow = '#b47109',
            green = '#6c782e',
            teal = '#4c7a5d',
            sky = '#4c7a5d',
            sapphire = '#4c7a5d',
            blue = '#45707a',
            lavender = '#45707a',
            text = '#654735',
            subtext1 = '#73503c',
            subtext0 = '#805942',
            overlay2 = '#8c6249',
            overlay1 = '#8c856d',
            overlay0 = '#a69d81',
            surface2 = '#bfb695',
            surface1 = '#d1c7a3',
            surface0 = '#e3dec3',
            base = '#f9f5d7',
            mantle = '#f0ebce',
            crust = '#e8e3c8',
          },
        },
        integrations = {
          aerial = true,
          bufferline = true,
          alpha = true,
          cmp = true,
          dashboard = true,
          dap = true,
          dap_ui = true,
          flash = true,
          fidget = true,
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
            virtual_text = {
              errors = { 'italic' },
              hints = { 'italic' },
              warnings = { 'italic' },
              information = { 'italic' },
            },
            underlines = {
              errors = { 'underline' },
              hints = { 'underline' },
              warnings = { 'underline' },
              information = { 'underline' },
            },
            inlay_hints = {
              background = true,
            },
          },
          navic = { enabled = true, custom_bg = 'lualine' },
          neogit = true,
          neotest = true,
          neotree = true,
          noice = true,
          notify = true,
          octo = true,
          overseer = true,
          rainbow_delimiters = true,
          semantic_tokens = true,
          symbols_outline = true,
          telescope = true,
          treesitter = true,
          treesitter_context = true,
          which_key = true,
          window_picker = true,
        },
      }
    end,
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
      vim.api.nvim_set_hl(0, 'MoltenOutputBorder', { link = 'Normal' })
      vim.api.nvim_set_hl(0, 'MoltenOutputBorderFail', { link = 'MoonflyCrimson' })
      vim.api.nvim_set_hl(0, 'MoltenOutputBorderSuccess', { link = 'MoonflyBlue' })
    end,
  },

  {
    'olimorris/onedarkpro.nvim',
    priority = 1000, -- Ensure it loads first
  },

  { 'EdenEast/nightfox.nvim' },

  { 'projekt0n/github-nvim-theme' },
}
