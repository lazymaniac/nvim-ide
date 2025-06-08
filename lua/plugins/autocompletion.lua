return {

  -- [[ AUTOCOMPLETION ]] ---------------------------------------------------------------
  {
    'saghen/blink.cmp',
    build = 'cargo build --release',
    -- optional: provides snippets for the snippet source
    dependencies = {
      dependencies = { 'L3MON4D3/LuaSnip', version = 'v2.*' },
      {
        'saghen/blink.compat',
        opts = {},
        dependencies = {
          { 'petertriho/cmp-git', opts = {} },
        },
      },
      {
        'folke/lazydev.nvim',
        ft = 'lua', -- only load on lua files
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
          },
        },
      },
      {
        'fang2hou/blink-copilot',
        opts = {
          max_completions = 5,
          max_attempts = 6,
          kind_name = 'copilot', ---@type string | false
          kind_icon = ' ', ---@type string | false
          kind_hl = true, ---@type string | false
          debounce = 200, ---@type integer | false
          auto_refresh = {
            backward = true,
            forward = true,
          },
        },
      },
    },
    event = 'InsertEnter',
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' for mappings similar to built-in completion
      -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
      -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
      -- See the full "keymap" documentation for information on defining your own keymap.
      keymap = {
        preset = 'enter',
        ['<CR>'] = { 'accept', 'fallback' },
        ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
        ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
        ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
      },
      appearance = {
        -- Sets the fallback highlight groups to nvim-cmp's highlight groups
        -- Useful for when your theme doesn't support blink.cmp
        -- Will be removed in a future release
        use_nvim_cmp_as_default = false,
        -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },
      snippets = { preset = 'luasnip' },
      completion = {
        trigger = {
          -- When true, will prefetch the completion items when entering insert mode
          prefetch_on_insert = true,
          -- When false, will not show the completion window automatically when in a snippet
          show_in_snippet = true,
          -- When true, will show the completion window after typing any of alphanumerics, `-` or `_`
          show_on_keyword = true,
          -- When true, will show the completion window after typing a trigger character
          show_on_trigger_character = true,
          -- LSPs can indicate when to show the completion window via trigger characters
          -- however, some LSPs (i.e. tsserver) return characters that would essentially
          -- always show the window. We block these by default.
          show_on_blocked_trigger_characters = { ' ', '\n', '\t' },
          -- You can also block per filetype with a function:
          -- show_on_blocked_trigger_characters = function(ctx)
          --   if vim.bo.filetype == 'markdown' then return { ' ', '\n', '\t', '.', '/', '(', '[' } end
          --   return { ' ', '\n', '\t' }
          -- end,
          -- When both this and show_on_trigger_character are true, will show the completion window
          -- when the cursor comes after a trigger character after accepting an item
          show_on_accept_on_trigger_character = true,
          -- When both this and show_on_trigger_character are true, will show the completion window
          -- when the cursor comes after a trigger character when entering insert mode
          show_on_insert_on_trigger_character = true,
          -- List of trigger characters (on top of `show_on_blocked_trigger_characters`) that won't trigger
          -- the completion window when the cursor comes after a trigger character when
          -- entering insert mode/accepting an item
          show_on_x_blocked_trigger_characters = { "'", '"', '(' },
          -- or a function, similar to show_on_blocked_trigger_character
        },
        list = {
          -- Maximum number of items to display
          max_items = 200,
          selection = {
            -- When `true`, will automatically select the first item in the completion list
            preselect = true,
            -- preselect = function(ctx) return vim.bo.filetype ~= 'markdown' end,
            -- When `true`, inserts the completion item automatically when selecting it
            -- You may want to bind a key to the `cancel` command (default <C-e>) when using this option,
            -- which will both undo the selection and hide the completion menu
            auto_insert = false,
            -- auto_insert = function(ctx) return vim.bo.filetype ~= 'markdown' end
          },
          cycle = {
            -- When `true`, calling `select_next` at the _bottom_ of the completion list
            -- will select the _first_ completion item.
            from_bottom = true,
            -- When `true`, calling `select_prev` at the _top_ of the completion list
            -- will select the _last_ completion item.
            from_top = true,
          },
        },
        accept = {
          -- Write completions to the `.` register
          dot_repeat = true,
          -- Create an undo point when accepting a completion item
          create_undo_point = true,
          -- How long to wait for the LSP to resolve the item with additional information before continuing as-is
          resolve_timeout_ms = 100,
          -- Experimental auto-brackets support
          auto_brackets = {
            -- Whether to auto-insert brackets for functions
            enabled = true,
            -- Default brackets to use for unknown languages
            default_brackets = { '(', ')' },
            -- Overrides the default blocked filetypes
            -- See: https://github.com/Saghen/blink.cmp/blob/main/lua/blink/cmp/completion/brackets/config.lua#L5-L9
            override_brackets_for_filetypes = {},
            -- Synchronously use the kind of the item to determine if brackets should be added
            kind_resolution = {
              enabled = true,
              blocked_filetypes = { 'typescriptreact', 'javascriptreact', 'vue' },
            },
            -- Asynchronously use semantic token to determine if brackets should be added
            semantic_token_resolution = {
              enabled = true,
              blocked_filetypes = { 'java' },
              -- How long to wait for semantic tokens to return before assuming no brackets should be added
              timeout_ms = 400,
            },
          },
        },
        menu = {
          enabled = true,
          min_width = 15,
          max_height = 12,
          border = 'rounded', -- Defaults to `vim.o.winborder` on nvim 0.11+
          winblend = 10,
          winhighlight = 'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None',
          -- Keep the cursor X lines away from the top/bottom of the window
          scrolloff = 2,
          -- Note that the gutter will be disabled when border ~= 'none'
          scrollbar = true,
          -- Which directions to show the window,
          -- falling back to the next direction when there's not enough space
          direction_priority = { 'n', 's' },
          -- Whether to automatically show the window when new completion items are available
          auto_show = true,
          -- Screen coordinates of the command line
          cmdline_position = function()
            if vim.g.ui_cmdline_pos ~= nil then
              local pos = vim.g.ui_cmdline_pos -- (1, 0)-indexed
              return { pos[1] - 1, pos[2] }
            end
            local height = (vim.o.cmdheight == 0) and 1 or vim.o.cmdheight
            return { vim.o.lines - height, 0 }
          end,
          draw = {
            -- Aligns the keyword you've typed to a component in the menu
            align_to = 'label', -- or 'none' to disable, or 'cursor' to align to the cursor
            -- Left and right padding, optionally { left, right } for different padding on each side
            padding = 2,
            -- Gap between columns
            gap = 2,
            -- Priority of the cursorline highlight, setting this to 0 will render it below other highlights
            cursorline_priority = 10000,
            -- Use treesitter to highlight the label text for the given list of sources
            treesitter = { 'lsp' },
            -- Components to render, grouped by column
            columns = { { 'kind_icon' }, { 'label', 'label_description', gap = 1, 'source_name' } },
            -- Definitions for possible components to render. Each defines:
            --   ellipsis: whether to add an ellipsis when truncating the text
            --   width: control the min, max and fill behavior of the component
            --   text function: will be called for each item
            --   highlight function: will be called only when the line appears on screen
            components = {
              kind_icon = {
                ellipsis = false,
                text = function(ctx)
                  local kind_icon, _, _ = require('mini.icons').get('lsp', ctx.kind)
                  return kind_icon
                end,
                -- (optional) use highlights from mini.icons
                highlight = function(ctx)
                  local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                  return hl
                end,
                -- text = function(ctx)
                --   return ctx.kind_icon .. ctx.icon_gap
                -- end,
                -- -- Set the highlight priority to 20000 to beat the cursorline's default priority of 10000
                -- highlight = function(ctx)
                --   return { { group = ctx.kind_hl, priority = 20000 } }
                -- end,
              },
              kind = {
                ellipsis = false,
                width = { fill = true },
                text = function(ctx)
                  return ctx.kind
                end,
                highlight = function(ctx)
                  local _, hl, _ = require('mini.icons').get('lsp', ctx.kind)
                  return hl
                end,
                -- highlight = function(ctx)
                --   return ctx.kind_hl
                -- end,
              },
              label = {
                width = { fill = true, max = 60 },
                text = function(ctx)
                  return ctx.label .. ctx.label_detail
                end,
                highlight = function(ctx)
                  -- label and label details
                  local highlights = {
                    { 0, #ctx.label, group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel' },
                  }
                  if ctx.label_detail then
                    table.insert(highlights, { #ctx.label, #ctx.label + #ctx.label_detail, group = 'BlinkCmpLabelDetail' })
                  end
                  -- characters matched on the label by the fuzzy matcher
                  for _, idx in ipairs(ctx.label_matched_indices) do
                    table.insert(highlights, { idx, idx + 1, group = 'BlinkCmpLabelMatch' })
                  end

                  return highlights
                end,
              },
              label_description = {
                width = { max = 30 },
                text = function(ctx)
                  return ctx.label_description
                end,
                highlight = 'BlinkCmpLabelDescription',
              },
              source_name = {
                width = { max = 30 },
                text = function(ctx)
                  return ctx.source_name
                end,
                highlight = 'BlinkCmpSource',
              },
              source_id = {
                width = { max = 30 },
                text = function(ctx)
                  return ctx.source_id
                end,
                highlight = 'BlinkCmpSource',
              },
            },
          },
        },
        documentation = {
          -- Controls whether the documentation window will automatically show when selecting a completion item
          auto_show = true,
          -- Delay before showing the documentation window
          auto_show_delay_ms = 500,
          -- Delay before updating the documentation window when selecting a new item,
          -- while an existing item is still visible
          update_delay_ms = 50,
          -- Whether to use treesitter highlighting, disable if you run into performance issues
          treesitter_highlighting = true,
          -- Draws the item in the documentation window, by default using an internal treesitter based implementation
          draw = function(opts)
            opts.default_implementation()
          end,
          window = {
            min_width = 10,
            max_width = 80,
            max_height = 40,
            border = 'rounded', -- Defaults to `vim.o.winborder` on nvim 0.11+ or 'padded' when not defined/<=0.10
            winblend = 10,
            winhighlight = 'Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc',
            -- Note that the gutter will be disabled when border ~= 'none'
            scrollbar = true,
            -- Which directions to show the documentation window,
            -- for each of the possible menu window directions,
            -- falling back to the next direction when there's not enough space
            direction_priority = {
              menu_north = { 'e', 'w', 'n', 's' },
              menu_south = { 'e', 'w', 's', 'n' },
            },
          },
        },
        ghost_text = {
          enabled = true,
          -- Show the ghost text when an item has been selected
          show_with_selection = true,
          -- Show the ghost text when no item has been selected, defaulting to the first item
          show_without_selection = false,
          -- Show the ghost text when the menu is open
          show_with_menu = true,
          -- Show the ghost text when the menu is closed
          show_without_menu = true,
        },
      },
      signature = {
        enabled = true,
        trigger = {
          -- Show the signature help automatically
          enabled = true,
          -- Show the signature help window after typing any of alphanumerics, `-` or `_`
          show_on_keyword = true,
          blocked_trigger_characters = {},
          blocked_retrigger_characters = {},
          -- Show the signature help window after typing a trigger character
          show_on_trigger_character = true,
          -- Show the signature help window when entering insert mode
          show_on_insert = false,
          -- Show the signature help window when the cursor comes after a trigger character when entering insert mode
          show_on_insert_on_trigger_character = true,
        },
        window = {
          min_width = 1,
          max_width = 100,
          max_height = 10,
          border = 'rounded', -- Defaults to `vim.o.winborder` on nvim 0.11+ or 'padded' when not defined/<=0.10
          winblend = 10,
          winhighlight = 'Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder',
          scrollbar = true, -- Note that the gutter will be disabled when border ~= 'none'
          -- Which directions to show the window,
          -- falling back to the next direction when there's not enough space,
          -- or another window is in the way
          direction_priority = { 'n', 's' },
          -- Disable if you run into performance issues
          treesitter_highlighting = true,
          show_documentation = true,
        },
      },
      cmdline = {
        enabled = true,
        -- use 'inherit' to inherit mappings from top level `keymap` config
        keymap = { preset = 'cmdline' },
        sources = function()
          local type = vim.fn.getcmdtype()
          -- Search forward and backward
          if type == '/' or type == '?' then
            return { 'buffer' }
          end
          -- Commands
          if type == ':' or type == '@' then
            return { 'cmdline' }
          end
          return {}
        end,
        completion = {
          trigger = {
            show_on_blocked_trigger_characters = {},
            show_on_x_blocked_trigger_characters = {},
          },
          list = {
            selection = {
              -- When `true`, will automatically select the first item in the completion list
              preselect = true,
              -- When `true`, inserts the completion item automatically when selecting it
              auto_insert = true,
            },
          },
          -- Whether to automatically show the window when new completion items are available
          menu = { auto_show = true },
          -- Displays a preview of the selected item on the current line
          ghost_text = { enabled = true },
        },
      },
      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        compat = {},
        default = { 'copilot', 'lazydev', 'lsp', 'path', 'snippets', 'buffer', 'omni', 'cmdline' },
        providers = {
          copilot = {
            name = 'copilot',
            module = 'blink-copilot',
            score_offset = 100,
            async = true,
          },
          lazydev = {
            name = 'LazyDev',
            module = 'lazydev.integrations.blink',
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },
    },
    opts_extend = { 'sources.default' },
    config = function(_, opts)
      vim.api.nvim_create_autocmd('User', {
        pattern = 'BlinkCmpMenuOpen',
        callback = function()
          require('copilot.suggestion').dismiss()
          vim.b.copilot_suggestion_hidden = true
        end,
      })

      vim.api.nvim_create_autocmd('User', {
        pattern = 'BlinkCmpMenuClose',
        callback = function()
          vim.b.copilot_suggestion_hidden = false
        end,
      })
      require('blink.cmp').setup(opts)
    end,
  },
}
