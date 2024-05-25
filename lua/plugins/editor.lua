return {

  -- [[ KEYMAPS ]] ---------------------------------------------------------------

  -- [which-key.nvim] - Autocompletion for keymaps
  -- see: `:h which-key`
  -- link: https://github.com/folke/which-key.nvim
  {
    'folke/which-key.nvim',
    branch = 'main',
    event = 'VeryLazy',
    opts = {
      plugins = {
        spelling = {
          enabled = true,   -- Enabling this will show WhichKey when pressing z= to select spelling suggestion
          suggestions = 20, -- How many suggestions should be shown in the list?
        },
        marks = true,       -- Show a list of marks on ' and `
        registers = true,   -- Shows registers on " in NORMAL or <C-r> in INSERT mode
      },
      -- The presets plugin, adds help for bunch of default keybindings in Neovim
      -- No actual keybindings are created
      presets = {
        oprators = true,     -- Adds help for operators like d, y, ... and registers them for motion / text completion
        motions = true,      -- Adds help for motions
        text_objects = true, -- Adds help for text objects triggered after entering an operator
        windows = true,      -- Help for windows. Default bindings on <C-w>
        nav = true,          -- Misc bindings to work with windows
        z = true,            -- Bindings for folds, spelling and other prefixed with z
        g = true,            -- Bindings for prefixed with g
      },
      -- Add operators that will trigger motion and text objects completion.
      -- To enable all native operators, set the preset / operators plugin
      -- above
      operators = { gc = 'Comments' },
      key_labels = {
        -- Override the label used to display some keys. It doesn't effect
        -- WK in any other way
        -- For example:
        ['<space>'] = 'SPC',
        -- ["<CR>"] = "RET",
        ['<TAB>'] = 'TAB',
        ['<tab>'] = 'TAB',
      },
      icons = {
        breadcrumb = '»', -- symbol used in the command line area that shows your active key combo
        separator = '➜', -- symbol used between a key and it's label
        group = '+', -- symbol prepended to a group
      },
      popup_mappings = {
        scroll_down = '<c-d>', -- binding to scroll down inside the popup
        scroll_up = '<c-u>',   -- binding to scroll up inside the popup
      },
      window = {
        border = 'rounded',       -- none, single, double, shadow, rounded
        position = 'bottom',      -- bottom, top
        margin = { 1, 0, 1, 0 },  -- extra window margin [top, right, bottom, left]
        padding = { 1, 1, 1, 1 }, -- extra window padding [top, right, bottom, left]
        winblend = 0,
      },
      layout = {
        height = { min = 4, max = 25 }, -- min and max height of the columns
        width = { min = 20, max = 50 }, -- min and max width of the columns
        spacing = 2,                    -- spacing between columns
        align = 'left',                 -- align columns left, center or right
      },
      ignore_missing = false,
      hidden = { '<silent>', '<cmd>', '<Cmd>', '<CR>', 'call', 'lua', '^:', '^ ' }, -- hide mapping boilerplate
      show_help = true,                                                             -- show help message on the command line when the popup is visible
      triggers = 'auto',                                                            -- automatically setup triggers
      -- triggers = {"<leader>"} -- or specify a list manually
      triggers_blacklist = {
        -- list of mode / prefixes that should never be hooked by WhichKey
        -- this is mostly relevant for key maps that start with a native binding
        -- most people should not need to change this
        i = { 'j', 'k' },
        v = { 'j', 'k' },
      },
      defaults = {
        mode = { 'n', 'v' },
        ['g'] = { name = '+[goto]' },
        ['gs'] = { name = '+[surround]' },
        [']'] = { name = '+[next]' },
        ['['] = { name = '+[prev]' },
        ['<leader><tab>'] = { name = '+[tabs]' },
        ['<leader>b'] = { name = '+[buffer]' },
        ['<leader>c'] = { name = '+[code]' },
        ['<leader>d'] = { name = '+[debug]' },
        ['<leader>f'] = { name = '+[file/find]' },
        ['<leader>g'] = { name = '+[git]' },
        ['<leader>q'] = { name = '+[quit/session]' },
        ['<leader>s'] = { name = '+[search]' },
        ['<leader>S'] = { name = '+[surround]' },
        ['<leader>a'] = { name = '+[terminal]' },
        ['<leader>u'] = { name = '+[ui]' },
        ['<leader>w'] = { name = '+[windows]' },
        ['<leader>x'] = { name = '+[diagnostics/quickfix]' },
      },
    },
    config = function(_, opts)
      local wk = require 'which-key'
      wk.setup(opts)
      wk.register(opts.defaults)
    end,
  },

  -- [[ TEXT HIGHLIGHT ]] ---------------------------------------------------------------

  -- [vim-illuminate] - Automatically highlights other instances of the word under your cursor.
  -- see: `:h vim-illuminate`
  -- link: https://github.com/RRethy/vim-illuminate
  {
    'RRethy/vim-illuminate',
    branch = 'master',
    event = 'VeryLazy',
    keys = {
      { ']]', desc = 'Next Reference <]]>' },
      { '[[', desc = 'Prev Reference <[[>' },
    },
    config = function(_, opts)
      require('illuminate').configure {
        delay = 200,
        large_file_cutoff = 2000,
        large_file_overrides = {
          providers = { 'lsp' },
        },
      }
      local function map(key, dir, buffer)
        vim.keymap.set('n', key, function()
          require('illuminate')['goto_' .. dir .. '_reference'](false)
        end, { desc = dir:sub(1, 1):upper() .. dir:sub(2) .. ' Reference', buffer = buffer })
      end
      map(']]', 'next')
      map('[[', 'prev')
      -- also set it after loading ftplugins, since a lot overwrite [[ and ]]
      vim.api.nvim_create_autocmd('FileType', {
        callback = function()
          local buffer = vim.api.nvim_get_current_buf()
          map(']]', 'next', buffer)
          map('[[', 'prev', buffer)
        end,
      })
    end,
  },

  -- [mini.bufremove] - Batter buffer remove
  -- see: `:h mini.bufremove`
  -- link: https://github.com/echasnovski/mini.bufremove
  {
    'echasnovski/mini.bufremove',
    branch = 'main',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      {
        '<leader>bd',
        function()
          local bd = require('mini.bufremove').delete
          if vim.bo.modified then
            local choice = vim.fn.confirm(('Save changes to %q?'):format(vim.fn.bufname()), '&Yes\n&No\n&Cancel')
            if choice == 1 then -- Yes
              vim.cmd.write()
              bd(0)
            elseif choice == 2 then -- No
              bd(0, true)
            end
          else
            bd(0)
          end
        end,
        desc = 'Delete Buffer [bd]',
      },
      { '<leader>bD', function() require('mini.bufremove').delete(0, true) end, desc = 'Delete Buffer (Force) [bD]' },
    },
  },

  -- [[ DIAGNOSTICS ]] ---------------------------------------------------------------

  -- [trouble.nvim] - Better diagnostics, loclist, quickfix etc.
  -- see: `:h trouble.nvim`
  -- link: https://github.com/folke/trouble.nvim
  {
    'folke/trouble.nvim',
    branch = 'main',
    event = 'VeryLazy',
    cmd = { 'TroubleToggle', 'Trouble' },
    opts = {
      position = 'bottom', -- position of the list can be: bottom, top, left, right
      height = 10, -- height of the trouble list when position is top or bottom
      width = 50, -- width of the list when position is left or right
      icons = true, -- use devicons for filenames
      mode = 'document_diagnostics', -- "workspace_diagnostics", "document_diagnostics", "quickfix", "lsp_references", "loclist"
      severity = nil, -- nil (ALL) or vim.diagnostic.severity.ERROR | WARN | INFO | HINT
      fold_open = '', -- icon used for open folds
      fold_closed = '', -- icon used for closed folds
      group = true, -- group results by file
      padding = false, -- add an extra new line on top of the list
      cycle_results = true, -- cycle item list when reaching beginning or end of list
      action_keys = { -- key mappings for actions in the trouble list
        -- map to {} to remove a mapping, for example:
        -- close = {},
        close = 'q',                                                                        -- close the list
        cancel = '<esc>',                                                                   -- cancel the preview and get back to your last window / buffer / cursor
        refresh = 'r',                                                                      -- manually refresh
        jump = { '<cr>', '<tab>', '<2-leftmouse>' },                                        -- jump to the diagnostic or open / close folds
        open_split = { '<c-x>' },                                                           -- open buffer in new split
        open_vsplit = { '<c-v>' },                                                          -- open buffer in new vsplit
        open_tab = { '<c-t>' },                                                             -- open buffer in new tab
        jump_close = { 'o' },                                                               -- jump to the diagnostic and close the list
        toggle_mode = 'm',                                                                  -- toggle between "workspace" and "document" diagnostics mode
        switch_severity = 's',                                                              -- switch "diagnostics" severity filter level to HINT / INFO / WARN / ERROR
        toggle_preview = 'P',                                                               -- toggle auto_preview
        hover = 'K',                                                                        -- opens a small popup with the full multiline message
        preview = 'p',                                                                      -- preview the diagnostic location
        open_code_href = 'c',                                                               -- if present, open a URI with more information about the diagnostic error
        close_folds = { 'zM', 'zm' },                                                       -- close all folds
        open_folds = { 'zR', 'zr' },                                                        -- open all folds
        toggle_fold = { 'zA', 'za' },                                                       -- toggle fold of current file
        previous = 'k',                                                                     -- previous item
        next = 'j',                                                                         -- next item
        help = '?',                                                                         -- help menu
      },
      multiline = true,                                                                     -- render multi-line messages
      indent_lines = true,                                                                  -- add an indent guide below the fold icons
      win_config = { border = 'rounded' },                                                  -- window configuration for floating windows. See |nvim_open_win()|.
      auto_open = false,                                                                    -- automatically open the list when you have diagnostics
      auto_close = true,                                                                    -- automatically close the list when you have no diagnostics
      auto_preview = true,                                                                  -- automatically preview the location of the diagnostic. <esc> to close preview and go back to last window
      auto_fold = true,                                                                     -- automatically fold a file trouble list at creation
      auto_jump = { 'lsp_definitions' },                                                    -- for the given modes, automatically jump if there is only a single result
      include_declaration = { 'lsp_references', 'lsp_implementations', 'lsp_definitions' }, -- for the given modes, include the declaration of the current symbol in the results
      signs = {
        -- icons / text used for a diagnostic
        error = '',
        warning = '',
        hint = '',
        information = '',
        other = '',
      },
      use_diagnostic_signs = true, -- enabling this will use the signs defined in your lsp client
    },
    keys = {
      { '<leader>xx', '<cmd>TroubleToggle document_diagnostics<cr>',  desc = 'Document Diagnostics [xx]' },
      { '<leader>xX', '<cmd>TroubleToggle workspace_diagnostics<cr>', desc = 'Workspace Diagnostics [xX]' },
      { '<leader>xL', '<cmd>TroubleToggle loclist<cr>',               desc = 'Location List [xL]' },
      { '<leader>xQ', '<cmd>TroubleToggle quickfix<cr>',              desc = 'Quickfix List [xQ]' },
      {
        '[q',
        function()
          if require('trouble').is_open() then
            require('trouble').previous { skip_groups = true, jump = true }
          else
            local ok, err = pcall(vim.cmd.cprev)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = 'Previous trouble/quickfix item <[q>',
      },
      {
        ']q',
        function()
          if require('trouble').is_open() then
            require('trouble').next { skip_groups = true, jump = true }
          else
            local ok, err = pcall(vim.cmd.cnext)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = 'Next trouble/quickfix item <]q>',
      },
    },
  },

  -- [todo-comments.nvim] - Finds and lists all of the TODO, HACK, BUG, etc comment
  -- in your project and loads them into a browsable list.
  -- see: `:h todo-comments`
  -- link: https://github.com/folke/todo-comments.nvim
  {
    'folke/todo-comments.nvim',
    branch = 'main',
    cmd = { 'TodoTrouble', 'TodoTelescope' },
    event = 'VeryLazy',
    config = true,
    -- stylua: ignore
    keys = {
      { ']t',         function() require('todo-comments').jump_next() end, desc = 'Next todo comment <]t>' },
      { '[t',         function() require('todo-comments').jump_prev() end, desc = 'Previous [t]odo comment <[t>' },
      { '<leader>xt', '<cmd>TodoTrouble<cr>',                              desc = 'List Todo [xt]' },
      { '<leader>xT', '<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>',      desc = 'List Todo/Fix/Fixme [xT]' },
      { '<leader>st', '<cmd>TodoTelescope<cr>',                            desc = 'Search Todo [sT]' },
      { '<leader>sT', '<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>',    desc = 'Search Todo/Fix/Fixme [sT]' },
    },
  },

  -- [[ BUFFER OUTLINE ]] ---------------------------------------------------------------

  -- [outline.nvim] - Show symbols outline for current buffer
  -- see: `:h outline.nvim`
  -- link: https://github.com/hedyhli/outline.nvim
  {
    'hedyhli/outline.nvim',
    branch = 'main',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      { '<leader>o', '<cmd>Outline<cr>', mode = { 'n' }, desc = 'Code Outline [o]' },
    },
    opts = {
      outline_window = {
        -- Where to open the split window: right/left
        position = 'right',
        -- The default split commands used are 'topleft vs' and 'botright vs'
        -- depending on `position`. You can change this by providing your own
        -- `split_command`.
        -- `position` will not be considered if `split_command` is non-nil.
        -- This should be a valid vim command used for opening the split for the
        -- outline window. Eg, 'rightbelow vsplit'.
        split_command = 'botright vs',
        -- Percentage or integer of columns
        width = 40,
        -- Whether width is relative to the total width of nvim
        -- When relative_width = true, this means take 25% of the total
        -- screen width for outline window.
        relative_width = false,
        -- Auto close the outline window if goto_location is triggered and not for
        -- peek_location
        auto_close = false,
        -- Automatically scroll to the location in code when navigating outline window.
        auto_jump = false,
        -- boolean or integer for milliseconds duration to apply a temporary highlight
        -- when jumping. false to disable.
        jump_highlight_duration = 300,
        -- Whether to center the cursor line vertically in the screen when
        -- jumping/focusing. Executes zz.
        center_on_jump = true,
        -- Vim options for the outline window
        show_numbers = false,
        show_relative_numbers = false,
        wrap = false,
        -- true/false/'focus_in_outline'/'focus_in_code'.
        -- The last two means only show cursorline when the focus is in outline/code.
        -- 'focus_in_outline' can be used if the outline_items.auto_set_cursor
        -- operations are too distracting due to visual contrast caused by cursorline.
        show_cursorline = true,
        -- Enable this only if you enabled cursorline so your cursor color can
        -- blend with the cursorline, in effect, as if your cursor is hidden
        -- in the outline window.
        -- This makes your line of cursor have the same color as if the cursor
        -- wasn't focused on the outline window.
        -- This feature is experimental.
        hide_cursor = false,
        -- Whether to auto-focus on the outline window when it is opened.
        -- Set to false to *always* retain focus on your previous buffer when opening
        -- outline.
        -- If you enable this you can still use bangs in :Outline! or :OutlineOpen! to
        -- retain focus on your code. If this is false, retaining focus will be
        -- enforced for :Outline/:OutlineOpen and you will not be able to have the
        -- other behaviour.
        focus_on_open = true,
        -- Winhighlight option for outline window.
        -- See :help 'winhl'
        -- To change background color to "CustomHl" for example, use "Normal:CustomHl".
        winhl = '',
      },
      outline_items = {
        -- Show extra details with the symbols (lsp dependent) as virtual next
        show_symbol_details = true,
        -- Show corresponding line numbers of each symbol on the left column as
        -- virtual text, for quick navigation when not focused on outline.
        -- Why? See this comment:
        -- https://github.com/simrat39/symbols-outline.nvim/issues/212#issuecomment-1793503563
        show_symbol_lineno = true,
        -- Whether to highlight the currently hovered symbol and all direct parents
        highlight_hovered_item = true,
        -- Whether to automatically set cursor location in outline to match
        -- location in code when focus is in code. If disabled you can use
        -- `:OutlineFollow[!]` from any window or `<C-g>` from outline window to
        -- trigger this manually.
        auto_set_cursor = true,
        -- Autocmd events to automatically trigger these operations.
        auto_update_events = {
          -- Includes both setting of cursor and highlighting of hovered item.
          -- The above two options are respected.
          -- This can be triggered manually through `follow_cursor` lua API,
          -- :OutlineFollow command, or <C-g>.
          follow = { 'CursorMoved' },
          -- Re-request symbols from the provider.
          -- This can be triggered manually through `refresh_outline` lua API, or
          -- :OutlineRefresh command.
          items = { 'InsertLeave', 'WinEnter', 'BufEnter', 'BufWinEnter', 'TabEnter', 'BufWritePost' },
        },
      },
      -- Options for outline guides which help show tree hierarchy of symbols
      guides = {
        enabled = true,
        markers = {
          -- It is recommended for bottom and middle markers to use the same number
          -- of characters to align all child nodes vertically.
          bottom = '└',
          middle = '├',
          vertical = '│',
        },
      },
      symbol_folding = {
        -- Depth past which nodes will be folded by default. Set to false to unfold all on open.
        autofold_depth = 2,
        -- When to auto unfold nodes
        auto_unfold = {
          -- Auto unfold currently hovered symbol
          hovered = true,
          -- Auto fold when the root level only has this many nodes.
          -- Set true for 1 node, false for 0.
          only = true,
        },
        markers = { '', '' },
      },
      preview_window = {
        -- Automatically open preview of code location when navigating outline window
        auto_preview = true,
        -- Automatically open hover_symbol when opening preview (see keymaps for
        -- hover_symbol).
        -- If you disable this you can still open hover_symbol using your keymap
        -- below.
        open_hover_on_preview = true,
        width = 120,    -- Percentage or integer of columns
        min_width = 80, -- This is the number of columns
        -- Whether width is relative to the total width of nvim.
        -- When relative_width = true, this means take 50% of the total
        -- screen width for preview window, ensure the result width is at least 50
        -- characters wide.
        relative_width = false,
        -- Border option for floating preview window.
        -- Options include: single/double/rounded/solid/shadow or an array of border
        -- characters.
        -- See :help nvim_open_win() and search for "border" option.
        border = 'rounded',
        -- winhl options for the preview window, see ':h winhl'
        winhl = 'NormalFloat:',
        -- Pseudo-transparency of the preview window, see ':h winblend'
        winblend = 0,
        -- Experimental feature that let's you edit the source content live
        -- in the preview window. Like VS Code's "peek editor".
        live = true,
      },
      -- These keymaps can be a string or a table for multiple keys.
      -- Set to `{}` to disable. (Using 'nil' will fallback to default keys)
      keymaps = {
        show_help = '?',
        close = { '<Esc>', 'q' },
        -- Jump to symbol under cursor.
        -- It can auto close the outline window when triggered, see
        -- 'auto_close' option above.
        goto_location = '<Cr>',
        -- Jump to symbol under cursor but keep focus on outline window.
        peek_location = 'o',
        -- Visit location in code and close outline immediately
        goto_and_close = '<S-Cr>',
        -- Change cursor position of outline window to match current location in code.
        -- 'Opposite' of goto/peek_location.
        restore_location = '<C-g>',
        -- Open LSP/provider-dependent symbol hover information
        hover_symbol = '<C-space>',
        -- Preview location code of the symbol under cursor
        toggle_preview = 'K',
        rename_symbol = 'r',
        code_actions = 'a',
        -- These fold actions are collapsing tree nodes, not code folding
        fold = 'h',
        unfold = 'l',
        fold_toggle = '<Tab>',
        -- Toggle folds for all nodes.
        -- If at least one node is folded, this action will fold all nodes.
        -- If all nodes are folded, this action will unfold all nodes.
        fold_toggle_all = '<S-Tab>',
        fold_all = 'W',
        unfold_all = 'E',
        fold_reset = 'R',
        -- Move down/up by one line and peek_location immediately.
        -- You can also use outline_window.auto_jump=true to do this for any
        -- j/k/<down>/<up>.
        down_and_jump = '<C-j>',
        up_and_jump = '<C-k>',
      },
      providers = {
        priority = { 'lsp', 'markdown', 'norg' },
        lsp = {
          -- Lsp client names to ignore
          blacklist_clients = {},
        },
      },
      symbols = {
        -- Filter by kinds (string) for symbols in the outline.
        -- Possible kinds are the Keys in the icons table below.
        -- A filter list is a string[] with an optional exclude (boolean) field.
        -- The symbols.filter option takes either a filter list or ft:filterList
        -- key-value pairs.
        -- Put  exclude=true  in the string list to filter by excluding the list of
        -- kinds instead.
        -- Include all except String and Constant:
        --   filter = { 'String', 'Constant', exclude = true }
        -- Only include Package, Module, and Function:
        --   filter = { 'Package', 'Module', 'Function' }
        -- See more examples below.
        filter = nil,
        -- You can use a custom function that returns the icon for each symbol kind.
        -- This function takes a kind (string) as parameter and should return an
        -- icon as string.
        icon_fetcher = nil,
        -- 3rd party source for fetching icons. Fallback if icon_fetcher returned
        -- empty string. Currently supported values: 'lspkind'
        icon_source = nil,
        -- The next fallback if both icon_fetcher and icon_source has failed, is
        -- the custom mapping of icons specified below. The icons table is also
        -- needed for specifying hl group.
        icons = {
          File = { icon = '󰈔', hl = 'Identifier' },
          Module = { icon = '󰆧', hl = 'Include' },
          Namespace = { icon = '󰅪', hl = 'Include' },
          Package = { icon = '󰏗', hl = 'Include' },
          Class = { icon = '𝓒', hl = 'Type' },
          Method = { icon = 'ƒ', hl = 'Function' },
          Property = { icon = '', hl = 'Identifier' },
          Field = { icon = '󰆨', hl = 'Identifier' },
          Constructor = { icon = '', hl = 'Special' },
          Enum = { icon = 'ℰ', hl = 'Type' },
          Interface = { icon = '󰜰', hl = 'Type' },
          Function = { icon = '', hl = 'Function' },
          Variable = { icon = '', hl = 'Constant' },
          Constant = { icon = '', hl = 'Constant' },
          String = { icon = '𝓐', hl = 'String' },
          Number = { icon = '#', hl = 'Number' },
          Boolean = { icon = '⊨', hl = 'Boolean' },
          Array = { icon = '󰅪', hl = 'Constant' },
          Object = { icon = '⦿', hl = 'Type' },
          Key = { icon = '🔐', hl = 'Type' },
          Null = { icon = 'NULL', hl = 'Type' },
          EnumMember = { icon = '', hl = 'Identifier' },
          Struct = { icon = '𝓢', hl = 'Structure' },
          Event = { icon = '🗲', hl = 'Type' },
          Operator = { icon = '+', hl = 'Identifier' },
          TypeParameter = { icon = '𝙏', hl = 'Identifier' },
          Component = { icon = '󰅴', hl = 'Function' },
          Fragment = { icon = '󰅴', hl = 'Constant' },
          TypeAlias = { icon = ' ', hl = 'Type' },
          Parameter = { icon = ' ', hl = 'Identifier' },
          StaticMethod = { icon = ' ', hl = 'Function' },
          Macro = { icon = ' ', hl = 'Function' },
        },
      },
    },
  },

  -- [[ YANK/PASTE ]] ---------------------------------------------------------------

  -- [yanky.nvim] - Better yank/paste
  -- see: `h: yanky`
  -- link: https://github.com/gbprod/yanky.nvim
  {
    'gbprod/yanky.nvim',
    branch = 'main',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      ---@diagnostic disable-next-line: undefined-field
      { "<leader>p", function() require("telescope").extensions.yank_history.yank_history({}) end,  desc = "Search Yank History [p]" },
      { 'y',         '<Plug>(YankyYank)',                                                           mode = { 'n', 'x' },                                desc = 'Yank text <y>' },
      { 'p',         '<Plug>(YankyPutAfter)',                                                       mode = { 'n', 'x' },                                desc = 'Put yanked text after cursor <p>' },
      { 'P',         '<Plug>(YankyPutBefore)',                                                      mode = { 'n', 'x' },                                desc = 'Put yanked text before cursor <P>' },
      { 'gp',        '<Plug>(YankyGPutAfter)',                                                      mode = { 'n', 'x' },                                desc = 'Put yanked text after selection <gp>' },
      { 'gP',        '<Plug>(YankyGPutBefore)',                                                     mode = { 'n', 'x' },                                desc = 'Put yanked text before selection <gP>' },
      { '[y',        '<Plug>(YankyCycleForward)',                                                   desc = 'Cycle forward through yank history <[y>' },
      { ']y',        '<Plug>(YankyCycleBackward)',                                                  desc = 'Cycle backward through yank history <]y>' },
      { ']p',        '<Plug>(YankyPutIndentAfterLinewise)',                                         desc = 'Put indented after cursor (linewise) <]p>' },
      { '[p',        '<Plug>(YankyPutIndentBeforeLinewise)',                                        desc = 'Put indented before cursor (linewise) <[p>' },
      { ']P',        '<Plug>(YankyPutIndentAfterLinewise)',                                         desc = 'Put indented after cursor (linewise) <]P>' },
      { '[P',        '<Plug>(YankyPutIndentBeforeLinewise)',                                        desc = 'Put indented before cursor (linewise) <[P>' },
      { '>p',        '<Plug>(YankyPutIndentAfterShiftRight)',                                       desc = 'Put and indent right <>p>' },
      { '<p',        '<Plug>(YankyPutIndentAfterShiftLeft)',                                        desc = 'Put and indent left <<p>' },
      { '>P',        '<Plug>(YankyPutIndentBeforeShiftRight)',                                      desc = 'Put before and indent right <>P>' },
      { '<P',        '<Plug>(YankyPutIndentBeforeShiftLeft)',                                       desc = 'Put before and indent left <<P>' },
      { '=p',        '<Plug>(YankyPutAfterFilter)',                                                 desc = 'Put after applying a filter <=p>' },
      { '=P',        '<Plug>(YankyPutBeforeFilter)',                                                desc = 'Put before applying a filter <=P>' },
    },
    opts = {
      ring = {
        history_length = 100,
        storage = 'shada',
        storage_path = vim.fn.stdpath 'data' .. '/databases/yanky.db', -- Only for sqlite storage
        sync_with_numbered_registers = true,
        cancel_event = 'update',
        ignore_registers = { '_' },
        update_register_on_cycle = false,
      },
      picker = {
        select = {
          action = nil, -- nil to use default put action
        },
        telescope = {
          use_default_mappings = true, -- if default mappings should be used
          mappings = nil,              -- nil to use default mappings or no mappings (see `use_default_mappings`)
        },
      },
      system_clipboard = {
        sync_with_ring = true,
      },
      highlight = {
        on_put = true,
        on_yank = true,
        timer = 200,
      },
      preserve_cursor_position = {
        enabled = true,
      },
      textobj = {
        enabled = true,
      },
    },
  },

  -- [[ BUFFER UTILS ]] ---------------------------------------------------------------

  -- [arrow.nvim] - Pin buffers for quick access
  -- see: `:h arrow.nvim`
  -- link: https://github.com/otavioschwanck/arrow.nvim
  {
    'otavioschwanck/arrow.nvim',
    branch = 'master',
    event = 'VeryLazy',
    opts = {
      show_icons = true,
      leader_key = '`', -- Recommended to be a single key
    },
  },

  -- [detour.nvim] - Open current buffer in popup
  -- see: `:h detour.nvim`
  -- link: https://github.com/carbon-steel/detour.nvim
  {
    'carbon-steel/detour.nvim',
    branch = 'main',
    event = 'VeryLazy',
  },

  -- [guess-indent.nvim] - Plugin to guess proper indentation level.
  -- see: `:h guess-indent.nvim`
  -- link: https://github.com/NMAC427/guess-indent.nvim
  {
    'nmac427/guess-indent.nvim',
    branch = 'main',
    config = function()
      require('guess-indent').setup {}
    end,
  },

  -- [windows.nvim] - Plugin for maximizing windows
  -- see: `:h windows.nvim`
  -- link: https://github.com/anuvyklack/windows.nvim
  {
    'anuvyklack/windows.nvim',
    branch = 'main',
    dependencies = {
      { 'anuvyklack/middleclass',    branch = 'master' },
      { 'anuvyklack/animation.nvim', branch = 'main' },
    },
    -- stylua: ignore
    keys = {
      { '<leader>wm', '<cmd>WindowsMaximize<cr>',        mode = { 'n', 'v' }, desc = 'Maximize Window [wm]', },
      { '<leader>we', '<cmd>WindowsEqualize<cr>',        mode = { 'n', 'v' }, desc = 'Equalize Window [we]', },
      { '<leader>wt', '<cmd>WindowsToggleAutowidth<cr>', mode = { 'n', 'v' }, desc = 'Toggle Autowidth [wt]', },
    },
    config = function()
      vim.o.winwidth = 10
      vim.o.winminwidth = 10
      vim.o.equalalways = false
      require('windows').setup()
    end,
  },

  -- [better_escape.nvim] - Escpe from insert mode with jj or jk
  -- see: `:h better_escape.nvim`
  -- link: https://github.com/max397574/better-escape.nvim
  {
    'max397574/better-escape.nvim',
    branch = 'master',
    config = function()
      require('better_escape').setup {
        mapping = { 'jk', 'jj' },   -- a table with mappings to use
        timeout = vim.o.timeoutlen, -- the time in which the keys must be hit in ms. Use option timeoutlen by default
        clear_empty_lines = false,  -- clear line after escaping if there is only whitespace
        keys = '<Esc>',             -- keys used for escaping, if it is a function will use the result everytime
        -- example(recommended)
        -- keys = function()
        --   return vim.api.nvim_win_get_cursor(0)[2] > 1 and '<esc>l' or '<esc>'
        -- end,
      }
    end,
  },

  -- [nvim-scrollbar] - Scorllbar with git and lsp integration
  -- see: `:h nvim-scrollbar`
  -- link: https://github.com/petertriho/nvim-scrollbar
  {
    'petertriho/nvim-scrollbar',
    branch = 'main',
    config = function()
      require('scrollbar').setup {
        show = true,
        show_in_active_only = false,
        set_highlights = true,
        folds = 1000,                -- handle folds, set to number to disable folds if no. of lines in buffer exceeds this
        max_lines = false,           -- disables if no. of lines in buffer exceeds this
        hide_if_all_visible = false, -- Hides everything if all lines are visible
        throttle_ms = 100,
        handle = {
          text = ' ',
          blend = 30,                 -- Integer between 0 and 100. 0 for fully opaque and 100 to full transparent. Defaults to 30.
          color = nil,
          color_nr = nil,             -- cterm
          highlight = 'CursorColumn',
          hide_if_all_visible = true, -- Hides handle if all lines are visible
        },
        excluded_buftypes = {
          'terminal',
        },
        excluded_filetypes = {
          'cmp_docs',
          'cmp_menu',
          'noice',
          'prompt',
          'TelescopePrompt',
        },
        autocmd = {
          render = {
            'BufWinEnter',
            'TabEnter',
            'TermEnter',
            'WinEnter',
            'CmdwinLeave',
            'TextChanged',
            'VimResized',
            'WinScrolled',
          },
          clear = {
            'BufWinLeave',
            'TabLeave',
            'TermLeave',
            'WinLeave',
          },
        },
        handlers = {
          cursor = true,
          diagnostic = true,
          gitsigns = true, -- Requires gitsigns
          handle = true,
          search = true,   -- Requires hlslens
          ale = false,     -- Requires ALE
        },
      }
    end,
  },

  -- [bigfile.nvim] - Disable editor functions like lsp, treesitter when big file is loaded
  -- see: `:h bigfile.nvim`
  -- link: https://github.com/LunarVim/bigfile.nvim
  {
    'LunarVim/bigfile.nvim',
    branch = 'main',
    init = function()
      require('bigfile').setup {
        filesize = 2,      -- size of the file in MiB, the plugin round file sizes to the closest MiB
        pattern = { '*' }, -- autocmd pattern
        features = {       -- features to disable
          'indent_blankline',
          'illuminate',
          'lsp',
          'treesitter',
          'syntax',
          'matchparen',
          'vimopts',
          'filetype',
        },
      }
    end,
  },

  -- [vim-repeat] - Support `.` repeat in plugins.
  -- see: `:h vim-repeat`
  -- link: https://github.com/tpope/vim-repeat
  { 'tpope/vim-repeat', branch = 'master' },

  -- [gx.nvim] - Open link in browser
  -- see: `:h gx.nvim`
  -- link: https://github.com/chrishrb/gx.nvim
  {
    'chrishrb/gx.nvim',
    branch = 'main',
    event = { 'BufEnter' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = {
      handler_options = {
        search_engine = 'google',
      },
    },
  },

  -- [modes.nvim] - Highlights current line accordingly to mode
  -- see: `:h modes.nvim`
  -- link: https://github.com/mvllow/modes.nvim
  {
    'mvllow/modes.nvim',
    branch = 'main',
    config = function()
      require('modes').setup {
        colors = {
          copy = '#f5c359',
          delete = '#c75c6a',
          insert = '#78ccc5',
          visual = '#9745be',
        },
        -- Set opacity for cursorline and number background
        line_opacity = 0.3,
        -- Enable cursor highlights
        set_cursor = true,
        -- Enable cursorline initially, and disable cursorline for inactive windows
        -- or ignored filetypes
        set_cursorline = true,
        -- Enable line number highlights to match cursorline
        set_number = true,
        -- Disable modes highlights in specified filetypes
        -- Please PR commonly ignored filetypes
        ignore_filetypes = { 'NvimTree', 'TelescopePrompt' },
      }
    end,
  },

  -- [wilder.nvim] - cmdline improving plugin
  -- see: `:h wilder.nvim`
  -- link: https://github.com/gelguy/wilder.nvim
  {
    'gelguy/wilder.nvim',
    branch = 'master',
    config = function()
      local wilder = require 'wilder'
      wilder.setup { modes = { ':', '/', '?' } }
      wilder.set_option('pipeline', {
        wilder.branch(
          wilder.cmdline_pipeline {
            -- sets the language to use, 'vim' and 'python' are supported
            language = 'python',
            -- 0 turns off fuzzy matching
            -- 1 turns on fuzzy matching
            -- 2 partial fuzzy matching (match does not have to begin with the same first letter)
            fuzzy = 1,
          },
          wilder.python_search_pipeline {
            -- can be set to wilder#python_fuzzy_delimiter_pattern() for stricter fuzzy matching
            pattern = wilder.python_fuzzy_pattern(),
            -- omit to get results in the order they appear in the buffer
            sorter = wilder.python_difflib_sorter(),
            -- can be set to 're2' for performance, requires pyre2 to be installed
            -- see :h wilder#python_search() for more details
            engine = 're',
          }
        ),
      })
      local gradient = {
        '#f4468f',
        '#fd4a85',
        '#ff507a',
        '#ff566f',
        '#ff5e63',
        '#ff6658',
        '#ff704e',
        '#ff7a45',
        '#ff843d',
        '#ff9036',
        '#f89b31',
        '#efa72f',
        '#e6b32e',
        '#dcbe30',
        '#d2c934',
        '#c8d43a',
        '#bfde43',
        '#b6e84e',
        '#aff05b',
      }
      for i, fg in ipairs(gradient) do
        gradient[i] = wilder.make_hl('WilderGradient' .. i, 'Pmenu', { { a = 1 }, { a = 1 }, { foreground = fg } })
      end
      wilder.set_option(
        'renderer',
        wilder.popupmenu_renderer {
          highlights = {
            gradient = gradient, -- must be set
            -- selected_gradient key can be set to apply gradient highlighting for the selected candidate.
          },
          highlighter = wilder.highlighter_with_gradient {
            wilder.basic_highlighter(), -- or wilder.lua_fzy_highlighter(),
          },
        }
      )
    end,
  },
}
