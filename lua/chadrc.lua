 return {
   base46 = {
     theme = "kanagawa",
     hl_add = {},
     hl_override = {},
     integrations = {'dap'},
     changed_themes = {},
     transparency = false,
     theme_toggle = { "kanagawa", "everforest" },
   },

   ui = {
     cmp = {
       lspkind_text = true,
       style = "flat_dark", -- default/flat_light/flat_dark/atom/atom_colored
       format_colors = {
         tailwind = false,
       },
     },
     telescope = { style = "bordered" }, -- borderless / bordered
     statusline = {
       theme = "vscode_colored", -- default/vscode/vscode_colored/minimal
       -- default/round/block/arrow separators work only for default statusline theme
       -- round and block will work for minimal theme only
       separator_style = "default",
       order = nil,
       modules = nil,
     },
     -- lazyload it when there are 1+ buffers
     tabufline = {
       enabled = true,
       lazyload = false,
       order = { "treeOffset", "buffers", "tabs", "btns" },
       modules = nil,
     },
   },
   nvdash = {
     load_on_startup = false,
   },
   term = {
     winopts = { number = false },
     sizes = { sp = 0.3, vsp = 0.2, ["bo sp"] = 0.3, ["bo vsp"] = 0.2 },
     float = {
       relative = "editor",
       row = 0.05,
       col = 0.05,
       width = 0.9,
       height = 0.8,
       border = "rounded",
     },
   },
   lsp = { signature = true },
   cheatsheet = {
     theme = "grid", -- simple/grid
     excluded_groups = { "terminal (t)", "autopairs", "Nvim", "Opens" }, -- can add group name or with mode
   },
   mason = { pkgs = {} },
   colorify = {
     enabled = true,
     mode = "virtual", -- fg, bg, virtual
     virt_text = "󱓻 ",
     highlight = { hex = true, lspvars = true },
   },
 }
