return {

  -- [[ AUTOCOMPLETION ]] ---------------------------------------------------------------

  -- [nvim-cmp] - Autocompletion engine. Suggests LSP, Buffer text, Paths, Snippets, Emojis
  -- see: `:h nvim-cmp`
  -- link: https://github.com/hrsh7th/nvim-cmp
  {
    'hrsh7th/nvim-cmp',
    branch = 'main',
    event = 'InsertEnter',
    dependencies = {
      -- [cmp-nvim-lsp] - Add lsp completion to cmp-nvim.
      -- see: `:h cmp-nvim-lsp`
      -- link: https://github.com/hrsh7th/cmp-nvim-lsp
      { 'hrsh7th/cmp-nvim-lsp',                branch = 'main' },
      -- [cmp-nvim-lsp-signature-help] - Displays functions signature.
      -- see: `:h cmp-nvim-lsp-signature-help`
      -- link: https://github.com/hrsh7th/cmp-nvim-lsp-signature-help
      { 'hrsh7th/cmp-nvim-lsp-signature-help', branch = 'main' },
      -- [cmp-buffer] - Adds buffer content to autocompletion.
      -- see: `:h cmp-buffer`
      -- link: https://github.com/hrsh7th/cmp-buffer
      { 'hrsh7th/cmp-buffer',                  branch = 'main' },
      -- [cmp-path] - Add system file tree autocompletion.
      -- see: `:h cmp-path`
      -- link: https://github.com/hrsh7th/cmp-path
      { 'hrsh7th/cmp-path',                    branch = 'main' },
      -- [cmp-calc] - Add result of calculations to autocompletion.
      -- see: `:h cmp-calc`
      -- link: https://github.com/hrsh7th/cmp-calc
      { 'hrsh7th/cmp-calc',                    branch = 'main' },
      -- [cmp-spell] - Add correct spelling to autocompletion.
      -- see: `:h cmp-spell`
      -- link: https://github.com/f3fora/cmp-spell
      { 'f3fora/cmp-spell',                    branch = 'master' },
      { 'L3MON4D3/LuaSnip',                    branch = 'master' },
      -- [cmp_luasnip] - Connect luasnip with nvim-cmp.
      -- see: `:h cmp_luasnip`
      -- link: https://github.com/saadparwaiz1/cmp_luasnip
      { 'saadparwaiz1/cmp_luasnip',            branch = 'master' },
      { 'rafamadriz/friendly-snippets',        branch = 'main' },
      { 'rcarriga/cmp-dap',                    branch = 'master' },
      -- [cmp-npm] - Add npm packages and versions to autocompletion.
      -- see: `:h cmp-npm`
      -- link: https://github.com/David-Kunz/cmp-npm
      {
        'David-Kunz/cmp-npm',
        branch = 'main',
        dependencies = { 'nvim-lua/plenary.nvim' },
        ft = 'json',
        config = function()
          require('cmp-npm').setup {}
        end,
      },
    },
    opts = function()
      vim.api.nvim_set_hl(0, 'CmpGhostText', { link = 'Comment', default = true })
      local cmp = require 'cmp'
      local defaults = require 'cmp.config.default' ()
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
          keyword_length = 1,
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
        sources = cmp.config.sources {
          { name = 'otter',                   keyword_length = 1, group_index = 1 },
          { name = 'nvim_lsp',                keyword_length = 0, group_index = 1 },
          { name = 'nvim_lsp_signature_help', keyword_length = 0, group_index = 1 },
          { name = 'pandoc_references',       keyword_length = 1, group_index = 1 },
          { name = 'luasnip',                 keyword_length = 1, group_index = 2 },
          { name = 'friendly-snippets',       keyword_length = 1, group_index = 2 },
          { name = 'path',                    keyword_length = 1, group_index = 3 },
          { name = 'emoji',                   keyword_length = 1, group_index = 6 },
          { name = 'calc',                    keyword_length = 1, group_index = 6 },
          { name = 'npm',                     keyword_length = 1, group_index = 6 },
          {
            name = 'spell',
            keyword_length = 2,
            group_index = 1,
            option = {
              keep_all_entries = false,
              enable_in_context = function()
                return false
              end,
            },
          },
          { name = 'latex_symbols', keyword_length = 2, group_index = 3 },
          { name = 'buffer',        keyword_length = 2, group_index = 2 },
        },
        formatting = {
          fields = { 'kind', 'abbr', 'menu' },
          expandable_indicator = true,
          format = function(entry, vim_item)
            -- Kind icons
            vim_item.kind = string.format('%s', kind_icons[vim_item.kind])
            -- vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind) -- This concatenates the icons with the name of the item kind
            vim_item.menu = ({
              otter = '[Ottr]',
              nvim_lsp = '[LSP]',
              luasnip = '[Snippet]',
              buffer = '[Buffer]',
              path = '[Path]',
              spell = '[Spell]',
              pandoc_references = '[Pandoc]',
              tags = '[Tag]',
              latex_symbols = '[Tex]',
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
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        experimental = {
          --[[ ghost_text = {
            hl_group = 'CmpGhostText',
          }, ]]
        },
        sorting = defaults.sorting,
      }
    end,
    config = function(_, opts)
      local cmp = require 'cmp'
      local luasnip = require 'luasnip'
      for _, source in ipairs(opts.sources) do
        source.group_index = source.group_index or 1
      end
      cmp.setup(opts)
      -- link quarto and rmarkdown to markdown snippets
      luasnip.filetype_extend('quarto', { 'markdown' })
      luasnip.filetype_extend('rmarkdown', { 'markdown' })
    end,
  },

  -- [nvim-autopairs] - Automatically adds closing pair for chars like: (, [, {, ", ' etc.
  -- see: `:h nvim-autopairs`
  -- link: https://github.com/windwp/nvim-autopairs
  {
    'windwp/nvim-autopairs',
    branch = 'master',
    event = 'InsertEnter',
    config = function()
      require('nvim-autopairs').setup {
        disable_filetype = { 'TelescopePrompt', 'vim' },
        disable_in_macro = true,        -- disable when recording or executing a macro
        disable_in_visualblock = false, -- disable when insert after visual block mode
        disable_in_replace_mode = true,
        ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],
        enable_moveright = true,
        enable_afterquote = true,         -- add bracket pairs after quote
        enable_check_bracket_line = true, --- check bracket in same line
        enable_bracket_in_quote = true,   --
        enable_abbr = false,              -- trigger abbreviation
        break_undo = true,                -- switch for basic rule break undo sequence
        check_ts = false,
        map_cr = true,
        map_bs = true,  -- map the <BS> key
        map_c_h = true, -- Map the <C-h> key to delete a pair
        map_c_w = true, -- map <c-w> to delete a pair if possible
      }
      local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
      local cmp = require 'cmp'
      cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
    end,
  },

  -- [cmp-dap] - Autocompletion for DAP Repl and watchers.
  -- see: `:h cmp-dap`
  -- link: https://github.com/rcarriga/cmp-dap
  {
    'rcarriga/cmp-dap',
    branch = 'master',
    event = 'VeryLazy',
    config = function()
      require('cmp').setup {
        enabled = function()
          return vim.api.nvim_buf_get_option(0, 'buftype') ~= 'prompt' or require('cmp_dap').is_dap_buffer()
        end,
      }
      require('cmp').setup.filetype({ 'dap-repl', 'dapui_watches', 'dapui_hover' }, {
        sources = {
          { name = 'dap' },
        },
      })
    end,
  },
}
