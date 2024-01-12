return {

  -- snippets

  -- [friendly-snippets] - Set of useful snippets in vscode format
  -- see: `:h friendly-snippets`
  {
    'rafamadriz/friendly-snippets',
    dependencies = {
      'L3MON4D3/LuaSnip',
    },
    config = function()
      require('luasnip.loaders.from_vscode').lazy_load { paths = './snippets' }
    end,
  },

  -- [luasnip] - Snippets engine. Loads snippets from various sources like vscode
  -- see: `h: luasnip`
  {
    'L3MON4D3/LuaSnip',
    event = 'VimEnter',
    build = (not jit.os:find 'Windows') and "echo 'NOTE: jsregexp is optional, so not a big deal if it fails to build'; make install_jsregexp" or nil,
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
    },
    init = function()
      local ls = require 'luasnip'
      ls.setup {
        -- Required to automatically include base snippets, like "c" snippets for "cpp"
        load_ft_func = require('luasnip_snippets.common.snip_utils').load_ft_func,
        ft_func = require('luasnip_snippets.common.snip_utils').ft_func,
        -- To enable auto expansin
        enable_autosnippets = true,
        -- Uncomment to enable visual snippets triggered using <c-x>
        -- store_selection_keys = '<c-x>',
        history = true,
        delete_check_events = 'TextChanged',
      }
      -- LuaSnip key bindings
      vim.keymap.set({ 'i', 's' }, '<C-E>', function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, { silent = true })
    end,
  },

  -- [luasnip_snippets] - Library of snippets ported from vim-snippets
  {
    'mireq/luasnip-snippets',
    dependencies = { 'L3MON4D3/LuaSnip' },
    init = function()
      -- Mandatory setup function
      require('luasnip_snippets.common.snip_utils').setup()
    end,
  },

  -- [nvim-scissors] - Allows to add and edit snippets
  -- see: `:h nvim-scissors`
  {
    'chrisgrieser/nvim-scissors',
    event = 'VeryLazy',
    dependencies = 'nvim-telescope/telescope.nvim', -- optional
    opts = {
      snippetDir = vim.fn.stdpath 'config' .. '/snippets',
      editSnippetPopup = {
        height = 0.4, -- relative to the window, number between 0 and 1
        width = 0.6,
        border = 'rounded',
        keymaps = {
          cancel = 'q',
          saveChanges = '<CR>',
          goBackToSearch = '<BS>',
          delete = '<C-BS>',
          openInFile = '<C-o>',
          insertNextToken = '<C-t>', -- works in insert & normal mode
        },
      },
      -- `none` writes as a minified json file using `vim.encode.json`.
      -- `yq`/`jq` ensure formatted & sorted json files, which is relevant when
      -- you version control your snippets.
      jsonFormatter = 'jq', -- "yq"|"jq"|"none"
    },
    keys = {
      {
        '<leader>fs',
        function()
          require('scissors').addNewSnippet()
        end,
        mode = { 'n', 'v' },
        desc = 'Add New Snippet',
      },
      {
        '<leader>fS',
        function()
          require('scissors').editSnippet()
        end,
        desc = 'Edit Snippet',
      },
    },
  },

  -- auto completion

  -- [nvim-cmp] - Autocompletion engine. Suggests LSP, Buffer text, Paths, Snippets, Emojis
  -- see: `:h nvim-cmp`
  {
    'hrsh7th/nvim-cmp',
    version = false, -- last release is way too old
    event = 'InsertEnter',
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',

      -- Adds LSP completion capabilities
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',

      -- Adds a number of user-friendly snippets
      'rafamadriz/friendly-snippets',

      -- Emoji support
      'hrsh7th/cmp-emoji',
    },
    opts = function()
      vim.api.nvim_set_hl(0, 'CmpGhostText', { link = 'Comment', default = true })
      local cmp = require 'cmp'
      local defaults = require 'cmp.config.default'()

      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match '%s' == nil
      end

      local luasnip = require 'luasnip'

      local kind_icons = {
        Text = '󰉿',
        Method = '󰆧',
        Function = '󰊕',
        Constructor = '',
        Field = ' ',
        Variable = '󰀫',
        Class = '󰠱',
        Interface = '',
        Module = '',
        Property = '󰜢',
        Unit = '󰑭',
        Value = '󰎠',
        Enum = '',
        Keyword = '󰌋',
        Snippet = '',
        Color = '󰏘',
        File = '󰈙',
        Reference = '',
        Folder = '󰉋',
        EnumMember = '',
        Constant = '󰏿',
        Struct = '',
        Event = '',
        Operator = '󰆕',
        TypeParameter = ' ',
        Misc = ' ',
      }
      -- find more here: https://www.nerdfonts.com/cheat-sheet

      return {
        completion = {
          completeopt = 'menu,menuone,noinsert',
        },
        snippet = {
          expand = function(args)
            require('luasnip').lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert {
          ['<C-n>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
          ['<C-p>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
          ['<C-b>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
          ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
          ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
          ['<C-e>'] = cmp.mapping {
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
          },
          ['<CR>'] = cmp.mapping.confirm { select = true }, -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          ['<S-CR>'] = cmp.mapping.confirm {
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }, -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
          ['<C-CR>'] = function(fallback)
            cmp.abort()
            fallback()
          end,
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              -- You could replace select_next_item() with confirm({ select = true }) to get VS Code autocompletion behavior
              cmp.select_next_item()
              -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
              -- this way you will only jump inside the snippet region
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif has_words_before() then
              cmp.complete()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        },
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'path' },
          { name = 'friendly-snippets' },
          { name = 'emoji' },
        }, {
          { name = 'buffer' },
        }),
        formatting = {
          fields = { 'kind', 'abbr', 'menu' },
          format = function(entry, vim_item)
            -- Kind icons
            -- vim_item.kind = string.format('%s', kind_icons[vim_item.kind])
            vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatonates the icons with the name of the item kind
            vim_item.menu = ({
              nvim_lsp = '[LSP]',
              luasnip = '[Snippet]',
              buffer = '[Buffer]',
              path = '[Path]',
              emoji = '[Emoji]',
            })[entry.source.name]
            return vim_item
          end,
        },
        confirm_opts = {
          behavior = cmp.ConfirmBehavior.Replace,
          select = false,
        },
        window = {
          documentation = {
            border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
          },
        },
        experimental = {
          ghost_text = {
            hl_group = 'CmpGhostText',
          },
        },
        sorting = defaults.sorting,
      }
    end,
    ---@param opts cmp.ConfigSchema
    config = function(_, opts)
      for _, source in ipairs(opts.sources) do
        source.group_index = source.group_index or 1
      end
      require('cmp').setup(opts)
    end,
  },

  -- auto pairs
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup {
        disable_filetype = { 'TelescopePrompt', 'vim' },
        disable_in_macro = true, -- disable when recording or executing a macro
        disable_in_visualblock = false, -- disable when insert after visual block mode
        disable_in_replace_mode = true,
        ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],
        enable_moveright = true,
        enable_afterquote = true, -- add bracket pairs after quote
        enable_check_bracket_line = true, --- check bracket in same line
        enable_bracket_in_quote = true, --
        enable_abbr = false, -- trigger abbreviation
        break_undo = true, -- switch for basic rule break undo sequence
        check_ts = false,
        map_cr = true,
        map_bs = true, -- map the <BS> key
        map_c_h = true, -- Map the <C-h> key to delete a pair
        map_c_w = true, -- map <c-w> to delete a pair if possible
      }
      local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
      local cmp = require 'cmp'
      cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
    end,
  },

  -- Fast and feature-rich surround actions. For text that includes
  -- surrounding characters like brackets or quotes, this allows you
  -- to select the text inside, change or modify the surrounding characters,
  -- and more.
  {
    'echasnovski/mini.surround',
    event = 'VeryLazy',
    version = false,
    keys = function(_, keys)
      -- Populate the keys based on the user's options
      local plugin = require('lazy.core.config').spec.plugins['mini.surround']
      local opts = require('lazy.core.plugin').values(plugin, 'opts', false)
      local mappings = {
        { opts.mappings.add, desc = 'Add surrounding', mode = { 'n', 'v' } },
        { opts.mappings.delete, desc = 'Delete surrounding' },
        { opts.mappings.find, desc = 'Find right surrounding' },
        { opts.mappings.find_left, desc = 'Find left surrounding' },
        { opts.mappings.highlight, desc = 'Highlight surrounding' },
        { opts.mappings.replace, desc = 'Replace surrounding' },
        { opts.mappings.update_n_lines, desc = 'Update `MiniSurround.config.n_lines`' },
      }
      mappings = vim.tbl_filter(function(m)
        return m[1] and #m[1] > 0
      end, mappings)
      return vim.list_extend(mappings, keys)
    end,
    opts = {
      mappings = {
        add = 'gsa', -- Add surrounding in Normal and Visual modes
        delete = 'gsd', -- Delete surrounding
        find = 'gsf', -- Find surrounding (to the right)
        find_left = 'gsF', -- Find surrounding (to the left)
        highlight = 'gsh', -- Highlight surrounding
        replace = 'gsr', -- Replace surrounding
        update_n_lines = 'gsn', -- Update `n_lines`
      },
    },
  },

  -- comments
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    opts = {
      enable_autocmd = false,
    },
  },
  {
    'echasnovski/mini.comment',
    event = 'VeryLazy',
    opts = {
      options = {
        custom_commentstring = function()
          return require('ts_context_commentstring.internal').calculate_commentstring() or vim.bo.commentstring
        end,
      },
    },
  },

  -- Better text-objects
  {
    'echasnovski/mini.ai',
    -- keys = {
    --   { "a", mode = { "x", "o" } },
    --   { "i", mode = { "x", "o" } },
    -- },
    event = 'VeryLazy',
    opts = function()
      local ai = require 'mini.ai'
      local nn = require 'notebook-navigator'

      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { '@block.outer', '@conditional.outer', '@loop.outer' },
            i = { '@block.inner', '@conditional.inner', '@loop.inner' },
          }, {}),
          f = ai.gen_spec.treesitter({ a = '@function.outer', i = '@function.inner' }, {}),
          c = ai.gen_spec.treesitter({ a = '@class.outer', i = '@class.inner' }, {}),
          t = { '<([%p%w]-)%f[^<%w][^<>]->.-</%1>', '^<.->().*()</[^/]->$' },
          h = nn.miniai_spec,
        },
      }
    end,
    config = function(_, opts)
      require('mini.ai').setup(opts)
      -- register all text objects with which-key
      require('util').on_load('which-key.nvim', function()
        ---@type table<string, string|table>
        local i = {
          [' '] = 'Whitespace',
          ['"'] = 'Balanced "',
          ["'"] = "Balanced '",
          ['`'] = 'Balanced `',
          ['('] = 'Balanced (',
          [')'] = 'Balanced ) including white-space',
          ['>'] = 'Balanced > including white-space',
          ['<lt>'] = 'Balanced <',
          [']'] = 'Balanced ] including white-space',
          ['['] = 'Balanced [',
          ['}'] = 'Balanced } including white-space',
          ['{'] = 'Balanced {',
          ['?'] = 'User Prompt',
          _ = 'Underscore',
          a = 'Argument',
          b = 'Balanced ), ], }',
          c = 'Class',
          f = 'Function',
          o = 'Block, conditional, loop',
          q = 'Quote `, ", \'',
          t = 'Tag',
        }
        local a = vim.deepcopy(i)
        for k, v in pairs(a) do
          a[k] = v:gsub(' including.*', '')
        end

        local ic = vim.deepcopy(i)
        local ac = vim.deepcopy(a)
        for key, name in pairs { n = 'Next', l = 'Last' } do
          i[key] = vim.tbl_extend('force', { name = 'Inside ' .. name .. ' textobject' }, ic)
          a[key] = vim.tbl_extend('force', { name = 'Around ' .. name .. ' textobject' }, ac)
        end
        require('which-key').register {
          mode = { 'o', 'x' },
          i = i,
          a = a,
        }
      end)
    end,
  },

  -- Increment values like numbers, dates, hours, letters
  {
    'nat-418/boole.nvim',
    opts = {
      mappings = {
        increment = '<C-a>',
        decrement = '<C-x>',
      },
      -- User defined loops
      additions = {
        { 'Foo', 'Bar' },
        { 'tic', 'tac', 'toe' },
      },
      allow_caps_additions = {
        { 'enable', 'disable' },
        -- enable → disable
        -- Enable → Disable
        -- ENABLE → DISABLE
      },
    },
    config = function(_, opts)
      require('boole').setup(opts)
    end,
  },

  -- Preview code actions before applying
  {
    'aznhe21/actions-preview.nvim',
    event = 'VeryLazy',
    config = function()
      require('actions-preview').setup()
      -- vim.keymap.set({ "v", "n" }, "gf", require("actions-preview").code_actions)
    end,
    keys = {
      {
        'gF',
        function()
          require('actions-preview').code_actions()
        end,
        desc = 'Actions Preview',
      },
    },
  },

  -- VSCode like preview of code.
  {
    'dnlhc/glance.nvim',
    config = function()
      require('glance').setup()
    end,
    keys = {
      {
        'gpd',
        '<cmd>Glance definitions<CR>',
        desc = 'Preview Definition',
      },
      {
        'gpt',
        '<cmd>Glance type_definitions<CR>',
        desc = 'Preview Type Definition',
      },
      {
        'gpi',
        '<cmd>Glance implementations<CR>',
        desc = 'Preview Implementation',
      },
      {
        'gpr',
        '<cmd>Glance references<CR>',
        desc = 'Preview References',
      },
    },
  },

  -- Auto move cursor to match indentation
  {
    'vidocqh/auto-indent.nvim',
    event = 'VeryLazy',
    opts = {},
  },

  -- Highlight method arguments
  {
    'm-demare/hlargs.nvim',
    event = 'VeryLazy',
    config = function()
      require('hlargs').setup()
    end,
  },

  -- Regex explainer
  {
    'tomiis4/Hypersonic.nvim',
    event = 'CmdlineEnter',
    cmd = 'Hypersonic',
    config = function()
      require('hypersonic').setup {
        ---@type 'none'|'single'|'double'|'rounded'|'solid'|'shadow'|table
        border = 'rounded',
        ---@type number 0-100
        winblend = 0,
        ---@type boolean
        add_padding = true,
        ---@type string
        hl_group = 'Keyword',
        ---@type string
        wrapping = '"',
        ---@type boolean
        enable_cmdline = true,
      }
    end,
    keys = {
      {
        '<leader>cR',
        '<cmd>Hypersonic<cr>',
        desc = 'Regex explain',
      },
    },
  },

  -- Surround text
  {
    'kylechui/nvim-surround',
    version = '*', -- Use for stability; omit to use `main` branch for the latest features
    event = 'VeryLazy',
    config = function()
      require('nvim-surround').setup {
        keymaps = {
          insert = '<C-g>s',
          insert_line = '<C-g>S',
          normal = 'ys',
          normal_cur = 'yss',
          normal_line = 'yS',
          normal_cur_line = 'ySS',
          visual = 'S',
          visual_line = 'gS',
          delete = 'ds',
          change = 'cs',
          change_line = 'cS',
        },
        aliases = {
          ['a'] = '>',
          ['b'] = ')',
          ['B'] = '}',
          ['r'] = ']',
          ['q'] = { '"', "'", '`' },
          ['s'] = { '}', ']', ')', '>', '"', "'", '`' },
        },
        highlight = {
          duration = 0,
        },
        move_cursor = 'begin',
        indent_lines = function(start, stop)
          local b = vim.bo
          -- Only re-indent the selection if a formatter is set up already
          if start < stop and (b.equalprg ~= '' or b.indentexpr ~= '' or b.cindent or b.smartindent or b.lisp) then
            vim.cmd(string.format('silent normal! %dG=%dG', start, stop))
          end
        end,
      }
    end,
  },
  {
    'roobert/surround-ui.nvim',
    dependencies = {
      'kylechui/nvim-surround',
      'folke/which-key.nvim',
    },
    config = function()
      require('surround-ui').setup {
        root_key = 'S',
      }
    end,
  },

  -- Various text objects
  {
    'chrisgrieser/nvim-various-textobjs',
    lazy = false,
    opts = { useDefaultKeymaps = true },
  },

  -- Additional actions for treesitter nodes
  {
    'ckolkey/ts-node-action',
    dependencies = { 'nvim-treesitter' },
    opts = {},
    keys = {
      {
        '<leader>cn',
        function()
          require('ts-node-action').node_action()
        end,
        desc = 'Trigger Node Action',
      },
    },
  },
}
