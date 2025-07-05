return {
  -- [base46] - Colorscheme management plugin
  -- see: `:h base46`
  -- link: https://github.com/NvChad/base46
  {
    'nvchad/base46',
    lazy = true,
    build = function()
      require('base46').load_all_highlights()
    end,
  },
}
