-- Window options for the preview window. Can be a split, floating window,
-- or `main` to show the preview in the main editor window.
---@type trouble.Window.opts
local split_preview = {
  type = 'split',
  position = 'right',
  size = 0.5,
  relative = 'win',
  border = 'rounded',
}
return {

  -- [[ DIAGNOSTICS & LSP ]] ---------------------------------------------------------------

  -- [trouble.nvim] - Better diagnostics, loclist, quickfix etc.
  -- see: `:h trouble.nvim`
  -- link: https://github.com/folke/trouble.nvim
  {
    'folke/trouble.nvim',
    branch = 'main',
    event = 'VeryLazy',
    cmd = { 'Trouble' },
    keys = {
      { '<leader>xx', '<cmd>Trouble diagnostics_prev toggle<cr>', desc = 'Diagnostics [xx]' },
      { '<leader>xX', '<cmd>Trouble diagnostics_prev toggle filter.buf=0<cr>', desc = 'Buffer Diagnostics [xX]' },
      { '<leader>xL', '<cmd>Trouble loclist toggle<cr>', desc = 'Location List [xL]' },
      { '<leader>xQ', '<cmd>Trouble qflist toggle<cr>', desc = 'Quickfix List [xQ]' },
      { '<leader>o', '<cmd>Trouble lsp_document_symbols_prev toggle win.position=right win.size=0.3<cr>', desc = 'Toggle symbols [xs]' },
      { '<leader>xl', '<cmd>Trouble lsp_prev toggle<cr>', desc = 'Toggle LSP [xl]' },
      {
        '[q',
        function()
          if require('trouble').is_open() then
            require('trouble').prev { skip_groups = true, jump = true }
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
    opts = {
      auto_close = true, -- auto close when there are no items
      auto_open = false, -- auto open when there are items
      auto_preview = true, -- automatically open preview when on an item
      auto_refresh = false, -- auto refresh when open
      auto_jump = true, -- auto jump to the item when there's only one
      focus = true, -- Focus the window when opened
      restore = true, -- restores the last location in the list when opening
      follow = false, -- Follow the current item
      indent_guides = true, -- show indent guides
      max_items = 200, -- limit number of items that can be displayed per section
      multiline = true, -- render multi-line messages
      pinned = true, -- When pinned, the opened trouble window will be bound to the current buffer
      warn_no_results = false, -- show a warning when there are no results
      open_no_results = false, -- open the trouble window when there are no results
      ---@type trouble.Window.opts
      win = {}, -- window options for the results window. Can be a split or a floating window.
      -- Window options for the preview window. Can be a split, floating window,
      -- or `main` to show the preview in the main editor window.
      ---@type trouble.Window.opts
      preview = {
        type = 'main',
        -- when a buffer is not yet loaded, the preview window will be created
        -- in a scratch buffer with only syntax highlighting enabled.
        -- Set to false, if you want the preview to always be a real loaded buffer.
        scratch = true,
      },
      -- Throttle/Debounce settings. Should usually not be changed.
      ---@type table<string, number|{ms:number, debounce?:boolean}>
      throttle = {
        refresh = 20, -- fetches new data when needed
        update = 10, -- updates the window
        render = 10, -- renders the window
        follow = 100, -- follows the current item
        preview = { ms = 100, debounce = true }, -- shows the preview for the current item
      },
      -- Key mappings can be set to the name of a builtin action,
      -- or you can define your own custom action.
      ---@type table<string, trouble.Action.spec|false>
      keys = {
        ['?'] = 'help',
        r = 'refresh',
        R = 'toggle_refresh',
        q = 'close',
        o = 'jump_close',
        ['<esc>'] = 'cancel',
        ['<cr>'] = 'jump',
        ['<2-leftmouse>'] = 'jump',
        ['<c-s>'] = 'jump_split',
        ['<c-v>'] = 'jump_vsplit',
        -- go down to next item (accepts count)
        -- j = "next",
        ['}'] = 'next',
        [']]'] = 'next',
        -- go up to prev item (accepts count)
        -- k = "prev",
        ['{'] = 'prev',
        ['[['] = 'prev',
        dd = 'delete',
        d = { action = 'delete', mode = 'v' },
        i = 'inspect',
        p = 'preview',
        P = 'toggle_preview',
        zo = 'fold_open',
        zO = 'fold_open_recursive',
        zc = 'fold_close',
        zC = 'fold_close_recursive',
        za = 'fold_toggle',
        zA = 'fold_toggle_recursive',
        zm = 'fold_more',
        zM = 'fold_close_all',
        zr = 'fold_reduce',
        zR = 'fold_open_all',
        zx = 'fold_update',
        zX = 'fold_update_all',
        zn = 'fold_disable',
        zN = 'fold_enable',
        zi = 'fold_toggle_enable',
        gb = { -- example of a custom action that toggles the active view filter
          action = function(view)
            view:filter({ buf = 0 }, { toggle = true })
          end,
          desc = 'Toggle Current Buffer Filter',
        },
        s = { -- example of a custom action that toggles the severity
          action = function(view)
            local f = view:get_filter 'severity'
            local severity = ((f and f.filter.severity or 0) + 1) % 5
            view:filter({ severity = severity }, {
              id = 'severity',
              template = '{hl:Title}Filter:{hl} {severity}',
              del = severity == 0,
            })
          end,
          desc = 'Toggle Severity Filter',
        },
      },
      ---@type table<string, trouble.Mode>
      modes = {
        diagnostics_prev = {
          focus = true,
          mode = 'diagnostics',
          preview = split_preview,
        },
        references_prev = {
          mode = 'lsp_references',
          focus = true,
          preview = split_preview,
        },
        definition_prev = {
          mode = 'lsp_definitions',
          focus = true,
          preview = split_preview,
        },
        declaration_prev = {
          mode = 'lsp_declarations',
          focus = true,
          preview = split_preview,
        },
        type_definition_prev = {
          mode = 'lsp_type_definitions',
          focus = true,
          preview = split_preview,
        },
        implementations_prev = {
          mode = 'lsp_implementations',
          focus = true,
          preview = split_preview,
        },
        command_prev = {
          mode = 'lsp_command',
          focus = true,
          preview = split_preview,
        },
        incoming_calls_prev = {
          mode = 'lsp_incoming_calls',
          focus = true,
          preview = split_preview,
        },
        outgoing_calls_prev = {
          mode = 'lsp_outgoing_calls',
          focus = true,
          preview = split_preview,
        },
        lsp_document_symbols_prev = {
          mode = 'lsp_document_symbols',
          focus = true,
        },
        lsp_prev = {
          mode = 'lsp',
          focus = true,
          preview = split_preview,
        },
        -- sources define their own modes, which you can use directly,
        -- or override like in the example below
        lsp_references = {
          -- some modes are configurable, see the source code for more details
          params = {
            include_declaration = true,
          },
        },
        -- The LSP base mode for:
        -- * lsp_definitions, lsp_references, lsp_implementations
        -- * lsp_type_definitions, lsp_declarations, lsp_command
        lsp_base = {
          params = {
            -- don't include the current location in the results
            include_current = false,
          },
        },
        -- more advanced example that extends the lsp_document_symbols
        symbols = {
          desc = 'document symbols',
          mode = 'lsp_document_symbols',
          focus = true,
          win = { position = 'right', size = 0.25 },
          filter = {
            -- remove Package since luals uses it for control flow structures
            ['not'] = { ft = 'lua', kind = 'Package' },
            any = {
              -- all symbol kinds for help / markdown files
              ft = { 'help', 'markdown' },
              -- default set of symbol kinds
              kind = {
                'Class',
                'Constructor',
                'Enum',
                'Field',
                'Function',
                'Interface',
                'Method',
                'Module',
                'Namespace',
                'Package',
                'Property',
                'Struct',
                'Trait',
              },
            },
          },
        },
      },
    },
  },

}
