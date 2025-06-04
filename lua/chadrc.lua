return {
  base46 = {
    theme = 'kanagawa',
    hl_add = {},
    hl_override = {},
    integrations = { 'dap' },
    changed_themes = {},
    transparency = false,
    theme_toggle = { 'kanagawa', 'everforest' },
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
      theme = 'default', -- default/vscode/vscode_colored/minimal
      -- default/round/block/arrow separators work only for default statusline theme
      -- round and block will work for minimal theme only
      separator_style = 'arrow',
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
    -- lazyload it when there are 1+ buffers
    tabufline = {
      enabled = false,
      lazyload = false,
      order = { 'treeOffset', 'buffers', 'tabs', 'btns' },
      modules = nil,
    },
  },
  nvdash = {
    load_on_startup = false,
  },
  term = {
    winopts = { number = false, relativenumber = false },
    sizes = { sp = 0.45, vsp = 0.45, ['bo sp'] = 0.45, ['bo vsp'] = 0.45 },
    float = {
      relative = 'editor',
      row = 0.05,
      col = 0.05,
      width = 0.9,
      height = 0.8,
      border = 'rounded',
    },
  },
  lsp = { signature = true },
  cheatsheet = {
    theme = 'grid', -- simple/grid
    excluded_groups = { 'terminal (t)', 'autopairs', 'Nvim', 'Opens' }, -- can add group name or with mode
  },
  mason = { pkgs = {} },
  colorify = {
    enabled = true,
    mode = 'virtual', -- fg, bg, virtual
    virt_text = '󱓻 ',
    highlight = { hex = true, lspvars = true },
  },
}
