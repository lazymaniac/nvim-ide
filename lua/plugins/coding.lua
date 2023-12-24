return {

  -- snippets
  {
    'L3MON4D3/LuaSnip',
    build = (not jit.os:find 'Windows') and "echo 'NOTE: jsregexp is optional, so not a big deal if it fails to build'; make install_jsregexp" or nil,
    dependencies = {
      'rafamadriz/friendly-snippets',
      config = function()
        require('luasnip.loaders.from_vscode').lazy_load()
      end,
    },
    opts = {
      history = true,
      delete_check_events = 'TextChanged',
    },
    -- stylua: ignore
    keys = {
      -- Disabled. Used cmp supertab
      -- {
      --   "<tab>",
      --   function()
      --     return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
      --   end,
      --   expr = true,
      --   silent = true,
      --   mode = "i",
      -- },
      -- { "<tab>",   function() require("luasnip").jump(1) end,  mode = "s" },
      -- { "<s-tab>", function() require("luasnip").jump(-1) end, mode = { "i", "s" } },
    },
  },

  -- auto completion
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
            vim_item.kind = string.format('%s', kind_icons[vim_item.kind])
            -- vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatonates the icons with the name of the item kind
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
    'echasnovski/mini.pairs',
    event = 'VeryLazy',
    opts = {
      -- In which modes mappings from this `config` should be created
      modes = { insert = true, command = false, terminal = false },

      -- Global mappings. Each right hand side should be a pair information, a
      -- table with at least these fields (see more in |MiniPairs.map|):
      -- - <action> - one of 'open', 'close', 'closeopen'.
      -- - <pair> - two character string for pair to be used.
      -- By default pair is not inserted after `\`, quotes are not recognized by
      -- `<CR>`, `'` does not insert pair after a letter.
      -- Only parts of tables can be tweaked (others will use these defaults).
      mappings = {
        ['('] = { action = 'open', pair = '()', neigh_pattern = '[^\\].' },
        ['['] = { action = 'open', pair = '[]', neigh_pattern = '[^\\].' },
        ['{'] = { action = 'open', pair = '{}', neigh_pattern = '[^\\].' },

        [')'] = { action = 'close', pair = '()', neigh_pattern = '[^\\].' },
        [']'] = { action = 'close', pair = '[]', neigh_pattern = '[^\\].' },
        ['}'] = { action = 'close', pair = '{}', neigh_pattern = '[^\\].' },

        ['"'] = { action = 'closeopen', pair = '""', neigh_pattern = '[^\\].', register = { cr = false } },
        ["'"] = { action = 'closeopen', pair = "''", neigh_pattern = '[^%a\\].', register = { cr = false } },
        ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\].', register = { cr = false } },
      },
    },
    keys = {
      {
        '<leader>up',
        function()
          local Util = require 'lazy.core.util'
          vim.g.minipairs_disable = not vim.g.minipairs_disable
          if vim.g.minipairs_disable then
            Util.warn('Disabled auto pairs', { title = 'Option' })
          else
            Util.info('Enabled auto pairs', { title = 'Option' })
          end
        end,
        desc = 'Toggle auto pairs',
      },
    },
  },

  -- Fast and feature-rich surround actions. For text that includes
  -- surrounding characters like brackets or quotes, this allows you
  -- to select the text inside, change or modify the surrounding characters,
  -- and more.
  {
    'echasnovski/mini.surround',
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
    lazy = true,
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
