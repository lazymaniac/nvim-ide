return {

  -- catppuccin
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        flavour = 'latte', -- latte, frappe, macchiato, mocha
        background = { -- :h background
          light = 'latte',
          dark = 'mocha',
        },
        transparent_background = false, -- disables setting the background color.
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
          comments = {}, -- Change the style of comments
          conditionals = { 'italic' },
          loops = { 'italic' },
          functions = {},
          keywords = { 'italic' },
          strings = {},
          variables = { 'bold' },
          numbers = {},
          booleans = { 'italic' },
          properties = { 'bold' },
          types = {},
          operators = { 'italic' },
        },
        color_overrides = {},
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
    'EdenEast/nightfox.nvim',
    config = function()
      require('nightfox').setup {
        options = {
          -- Compiled file's destination location
          compile_path = vim.fn.stdpath 'cache' .. '/nightfox',
          compile_file_suffix = '_compiled', -- Compiled file suffix
          transparent = false, -- Disable setting background
          terminal_colors = true, -- Set terminal colors (vim.g.terminal_color_*) used in `:terminal`
          dim_inactive = true, -- Non focused panes set to alternative background
          module_default = true, -- Default enable value for modules
          colorblind = {
            enable = false, -- Enable colorblind support
            simulate_only = false, -- Only show simulated colorblind colors and not diff shifted
            severity = {
              protan = 0, -- Severity [0,1] for protan (red)
              deutan = 0, -- Severity [0,1] for deutan (green)
              tritan = 0, -- Severity [0,1] for tritan (blue)
            },
          },
          styles = { -- Style to be applied to different syntax groups
            comments = 'italic', -- Value is any valid attr-list value `:help attr-list`
            conditionals = 'italic',
            constants = 'bold',
            functions = 'NONE',
            keywords = 'italic',
            numbers = 'NONE',
            operators = 'italic',
            strings = 'NONE',
            types = 'NONE',
            variables = 'bold',
          },
          inverse = { -- Inverse highlight for different types
            match_paren = false,
            visual = false,
            search = false,
          },
          modules = { -- List of various plugins and additional options
            -- ...
          },
        },
        palettes = {},
        specs = {},
        groups = {},
      }
    end,
  },

  {
    'loganswartz/sunburn.nvim',
    dependencies = { 'loganswartz/polychrome.nvim' },
    -- you could do this, or use the standard vimscript `colorscheme sunburn`
    config = function()
    end,
  },
}
