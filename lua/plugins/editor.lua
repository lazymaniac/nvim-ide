return {

  -- [[ KEYMAPS ]] ---------------------------------------------------------------
  -- [which-key.nvim] - Autocompletion for keymaps
  -- see: `:h which-key`
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      plugins = {
        spelling = {
          enabled = true, -- Enabling this will show WhichKey when pressing z= to select spelling suggestion
          suggestions = 20, -- How many suggestions should be shown in the list?
        },
        marks = true, -- Show a list of marks on ' and `
        registers = true, -- Shows registers on " in NORMAL or <C-r> in INSERT mode
      },
      -- The presets plugin, adds help for bunch of default keybindings in Neovim
      -- No actual keybindings are created
      presets = {
        oprators = true, -- Adds help for operators like d, y, ... and registers them for motion / text completion
        motions = true, -- Adds help for motions
        text_objects = true, -- Adds help for text objects triggered after entering an operator
        windows = true, -- Help for windows. Default bindings on <C-w>
        nav = true, -- Misc bindings to work with windows
        z = true, -- Bindings for folds, spelling and other prefixed with z
        g = true, -- Bindings for prefixed with g
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
        scroll_up = '<c-u>', -- binding to scroll up inside the popup
      },
      window = {
        border = 'rounded', -- none, single, double, shadow, rounded
        position = 'bottom', -- bottom, top
        margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]
        padding = { 1, 1, 1, 1 }, -- extra window padding [top, right, bottom, left]
        winblend = 0,
      },
      layout = {
        height = { min = 4, max = 25 }, -- min and max height of the columns
        width = { min = 20, max = 50 }, -- min and max width of the columns
        spacing = 2, -- spacing between columns
        align = 'left', -- align columns left, center or right
      },
      ignore_missing = false,
      hidden = { '<silent>', '<cmd>', '<Cmd>', '<CR>', 'call', 'lua', '^:', '^ ' }, -- hide mapping boilerplate
      show_help = true, -- show help message on the command line when the popup is visible
      triggers = 'auto', -- automatically setup triggers
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
  -- This works with LSP, Treesitter, and regexp matching to find the other instances.
  -- see: `:h vim-illuminate`
  {
    'RRethy/vim-illuminate',
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
  {
    'echasnovski/mini.bufremove',
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
  {
    'folke/trouble.nvim',
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
        close = 'q', -- close the list
        cancel = '<esc>', -- cancel the preview and get back to your last window / buffer / cursor
        refresh = 'r', -- manually refresh
        jump = { '<cr>', '<tab>', '<2-leftmouse>' }, -- jump to the diagnostic or open / close folds
        open_split = { '<c-x>' }, -- open buffer in new split
        open_vsplit = { '<c-v>' }, -- open buffer in new vsplit
        open_tab = { '<c-t>' }, -- open buffer in new tab
        jump_close = { 'o' }, -- jump to the diagnostic and close the list
        toggle_mode = 'm', -- toggle between "workspace" and "document" diagnostics mode
        switch_severity = 's', -- switch "diagnostics" severity filter level to HINT / INFO / WARN / ERROR
        toggle_preview = 'P', -- toggle auto_preview
        hover = 'K', -- opens a small popup with the full multiline message
        preview = 'p', -- preview the diagnostic location
        open_code_href = 'c', -- if present, open a URI with more information about the diagnostic error
        close_folds = { 'zM', 'zm' }, -- close all folds
        open_folds = { 'zR', 'zr' }, -- open all folds
        toggle_fold = { 'zA', 'za' }, -- toggle fold of current file
        previous = 'k', -- previous item
        next = 'j', -- next item
        help = '?', -- help menu
      },
      multiline = true, -- render multi-line messages
      indent_lines = true, -- add an indent guide below the fold icons
      win_config = { border = 'rounded' }, -- window configuration for floating windows. See |nvim_open_win()|.
      auto_open = false, -- automatically open the list when you have diagnostics
      auto_close = true, -- automatically close the list when you have no diagnostics
      auto_preview = true, -- automatically preview the location of the diagnostic. <esc> to close preview and go back to last window
      auto_fold = true, -- automatically fold a file trouble list at creation
      auto_jump = { 'lsp_definitions' }, -- for the given modes, automatically jump if there is only a single result
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
      { '<leader>xx', '<cmd>TroubleToggle document_diagnostics<cr>', desc = 'Document Diagnostics [xx]' },
      { '<leader>xX', '<cmd>TroubleToggle workspace_diagnostics<cr>', desc = 'Workspace Diagnostics [xX]' },
      { '<leader>xL', '<cmd>TroubleToggle loclist<cr>', desc = 'Location List [xL]' },
      { '<leader>xQ', '<cmd>TroubleToggle quickfix<cr>', desc = 'Quickfix List [xQ]' },
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

  -- [textobj-diagnostic.nvim] - Diagnostics text objects
  -- see: `:h textobj-diagnostic`
  --
  -- keymapping | function                                            | purpose
  -- ig         | require('textobj-diagnostic').next_diag_inclusive() | finds the diagnostic under or after the cursor (including any diagnostic the cursor is sitting on)
  -- ]g         | require('textobj-diagnostic').next_diag()           | finds the diagnostic after the cursor (excluding any diagnostic the cursor is sitting on)
  -- [g         | require('textobj-diagnostic').prev_diag()           | finds the diagnostic before the cursor (excluding any diagnostic the cursor is sitting on)
  --
  {
    'andrewferrier/textobj-diagnostic.nvim',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      { '<leader>xn', function() require('textobj-diagnostic').nearest_diag() end, desc = 'Nearest Diagnostic [xn]' },
    },
    config = function()
      require('textobj-diagnostic').setup()
    end,
  },

  -- [todo-comments.nvim] - Finds and lists all of the TODO, HACK, BUG, etc comment
  -- in your project and loads them into a browsable list.
  -- see: `:h todo-comments`
  {
    'folke/todo-comments.nvim',
    cmd = { 'TodoTrouble', 'TodoTelescope' },
    event = 'VeryLazy',
    config = true,
    -- stylua: ignore
    keys = {
      { ']t', function() require('todo-comments').jump_next() end, desc = 'Next todo comment <]t>' },
      { '[t', function() require('todo-comments').jump_prev() end, desc = 'Previous [t]odo comment <[t>' },
      { '<leader>xt', '<cmd>TodoTrouble<cr>', desc = 'List Todo [xt]' },
      { '<leader>xT', '<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>', desc = 'List Todo/Fix/Fixme [xT]' },
      { '<leader>st', '<cmd>TodoTelescope<cr>', desc = 'Search Todo [sT]' },
      { '<leader>sT', '<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>', desc = 'Search Todo/Fix/Fixme [sT]' },
    },
  },

  -- [[ YANK/PASTE ]] ---------------------------------------------------------------

  -- [yanky.nvim] - Better yank/paste
  -- see: `h: yanky`
  {
    'gbprod/yanky.nvim',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
        ---@diagnostic disable-next-line: undefined-field
      { "<leader>p", function() require("telescope").extensions.yank_history.yank_history({ }) end, desc = "Search Yank History [p]" },
      { 'y', '<Plug>(YankyYank)', mode = { 'n', 'x' }, desc = 'Yank text <y>' },
      { 'p', '<Plug>(YankyPutAfter)', mode = { 'n', 'x' }, desc = 'Put yanked text after cursor <p>' },
      { 'P', '<Plug>(YankyPutBefore)', mode = { 'n', 'x' }, desc = 'Put yanked text before cursor <P>' },
      { 'gp', '<Plug>(YankyGPutAfter)', mode = { 'n', 'x' }, desc = 'Put yanked text after selection <gp>' },
      { 'gP', '<Plug>(YankyGPutBefore)', mode = { 'n', 'x' }, desc = 'Put yanked text before selection <gP>' },
      { '[y', '<Plug>(YankyCycleForward)', desc = 'Cycle forward through yank history <[y>' },
      { ']y', '<Plug>(YankyCycleBackward)', desc = 'Cycle backward through yank history <]y>' },
      { ']p', '<Plug>(YankyPutIndentAfterLinewise)', desc = 'Put indented after cursor (linewise) <]p>' },
      { '[p', '<Plug>(YankyPutIndentBeforeLinewise)', desc = 'Put indented before cursor (linewise) <[p>' },
      { ']P', '<Plug>(YankyPutIndentAfterLinewise)', desc = 'Put indented after cursor (linewise) <]P>' },
      { '[P', '<Plug>(YankyPutIndentBeforeLinewise)', desc = 'Put indented before cursor (linewise) <[P>' },
      { '>p', '<Plug>(YankyPutIndentAfterShiftRight)', desc = 'Put and indent right <>p>' },
      { '<p', '<Plug>(YankyPutIndentAfterShiftLeft)', desc = 'Put and indent left <<p>' },
      { '>P', '<Plug>(YankyPutIndentBeforeShiftRight)', desc = 'Put before and indent right <>P>' },
      { '<P', '<Plug>(YankyPutIndentBeforeShiftLeft)', desc = 'Put before and indent left <<P>' },
      { '=p', '<Plug>(YankyPutAfterFilter)', desc = 'Put after applying a filter <=p>' },
      { '=P', '<Plug>(YankyPutBeforeFilter)', desc = 'Put before applying a filter <=P>' },
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
          mappings = nil, -- nil to use default mappings or no mappings (see `use_default_mappings`)
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
  {
    'otavioschwanck/arrow.nvim',
    event = 'VeryLazy',
    opts = {
      show_icons = true,
      leader_key = ';', -- Recommended to be a single key
    },
  },

  -- [highlight-undo.nvim] - Highlights result of undo operation
  -- see: `:h highlight-undo.nvim`
  {
    'tzachar/highlight-undo.nvim',
    config = function()
      require('highlight-undo').setup {
        duration = 1000,
        undo = {
          hlgroup = 'HighlightUndo',
          mode = 'n',
          lhs = 'u',
          map = 'undo',
          opts = {},
        },
        redo = {
          hlgroup = 'HighlightUndo',
          mode = 'n',
          lhs = '<C-r>',
          map = 'redo',
          opts = {},
        },
        highlight_for_count = true,
      }
    end,
  },

  -- [guess-indent.nvim] - Plugin to set proper indentation
  -- see: `:h guess-indent.nvim`
  {
    'nmac427/guess-indent.nvim',
    config = function()
      require('guess-indent').setup {}
    end,
  },

  -- [windows.nvim] - Plugin for maximizing windows
  -- see: `:h windows.nvim`
  {
    'anuvyklack/windows.nvim',
    dependencies = {
      'anuvyklack/middleclass',
      'anuvyklack/animation.nvim',
    },
    -- stylua: ignore
    keys = {
      { '<leader>wm', '<cmd>WindowsMaximize<cr>', mode = { 'n', 'v' }, desc = 'Maximize Window [wm]', },
      { '<leader>we', '<cmd>WindowsEqualize<cr>', mode = { 'n', 'v' }, desc = 'Equalize Window [we]', },
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
  {
    'max397574/better-escape.nvim',
    config = function()
      require('better_escape').setup {
        mapping = { 'jk', 'jj' }, -- a table with mappings to use
        timeout = vim.o.timeoutlen, -- the time in which the keys must be hit in ms. Use option timeoutlen by default
        clear_empty_lines = false, -- clear line after escaping if there is only whitespace
        keys = '<Esc>', -- keys used for escaping, if it is a function will use the result everytime
        -- example(recommended)
        -- keys = function()
        --   return vim.api.nvim_win_get_cursor(0)[2] > 1 and '<esc>l' or '<esc>'
        -- end,
      }
    end,
  },

  -- [codewindow.nvim] - Code outline
  -- see: `:h codewindow.nvim`
  {
    'gorbit99/codewindow.nvim',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      { '<leader>uo', '<cmd>lua require("codewindow").toggle_minimap()<cr>', mode = { 'n', 'v' }, desc = 'desc' },
    },
    config = function()
      local codewindow = require 'codewindow'
      codewindow.setup {
        active_in_terminals = false, -- Should the minimap activate for terminal buffers
        auto_enable = true, -- Automatically open the minimap when entering a (non-excluded) buffer (accepts a table of filetypes)
        exclude_filetypes = { 'help' }, -- Choose certain filetypes to not show minimap on
        max_minimap_height = nil, -- The maximum height the minimap can take (including borders)
        max_lines = nil, -- If auto_enable is true, don't open the minimap for buffers which have more than this many lines.
        minimap_width = 16, -- The width of the text part of the minimap
        use_lsp = true, -- Use the builtin LSP to show errors and warnings
        use_treesitter = true, -- Use nvim-treesitter to highlight the code
        use_git = true, -- Show small dots to indicate git additions and deletions
        width_multiplier = 4, -- How many characters one dot represents
        z_index = 1, -- The z-index the floating window will be on
        show_cursor = true, -- Show the cursor position in the minimap
        screen_bounds = 'lines', -- How the visible area is displayed, "lines": lines above and below, "background": background color
        window_border = 'none', -- The border style of the floating window (accepts all usual options)
        relative = 'win', -- What will be the minimap be placed relative to, "win": the current window, "editor": the entire editor
        events = { 'TextChanged', 'InsertLeave', 'DiagnosticChanged', 'FileWritePost' }, -- Events that update the code window
      }
    end,
  },
}
