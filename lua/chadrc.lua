return {
  base46 = {
    theme = 'nightowl', -- kanagawa/everforest/onedark/atom/atom_colored
    hl_add = {},
    hl_override = {},
    integrations = { 'dap', 'treesitter', 'whichkey' },
    changed_themes = {},
    transparency = false,
    theme_toggle = { 'nightowl', 'kanagawa' },
  },

  ui = {
    cmp = {
      icons_left = true, -- only for non-atom styles!
      lspkind_text = true,
      style = 'default', -- default/flat_light/flat_dark/atom/atom_colored
      format_colors = {
        tailwind = true,
        icon = '󱓻',
      },
    },
    statusline = {
      enabled = true,
      theme = 'minimal', -- default/vscode/vscode_colored/minimal
      -- default/round/block/arrow separators work only for default statusline theme
      -- round and block will work for minimal theme only
      separator_style = 'round',
      order = { 'mode', 'file', 'git', '%=', '%=', 'diagnostics', 'dap', 'lint', 'lsp', 'cwd', 'cursor' },
      modules = {
        dap = function()
          if require('dap').status() ~= '' then
            return '  ' .. require('dap').status()
          end
        end,
        lint = function()
          local linters = require('lint').get_running()
          if #linters == 0 then
            return '󰦕'
          end
          return '󱉶 ' .. table.concat(linters, ', ')
        end,
      },
    },
    tabufline = {
      enabled = true,
      lazyload = true,
      order = { 'treeOffset', 'buffers', 'tabs', 'btns' },
      modules = nil,
      bufwidth = 25,
    },
  },
  lsp = { signature = true },
  colorify = {
    enabled = true,
    mode = 'virtual', -- fg, bg, virtual
    virt_text = '󱓻 ',
    highlight = { hex = true, lspvars = true },
  },
}
