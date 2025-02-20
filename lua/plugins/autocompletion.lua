local cmp_actions = {
  -- Native Snippets
  snippet_forward = function()
    if vim.snippet.active { direction = 1 } then
      vim.schedule(function()
        vim.snippet.jump(1)
      end)
      return true
    end
  end,
  snippet_stop = function()
    if vim.snippet then
      vim.snippet.stop()
    end
  end,
}

local function map(actions, fallback)
  return function()
    for _, name in ipairs(actions) do
      if cmp_actions[name] then
        local ret = cmp_actions[name]()
        if ret then
          return true
        end
      end
    end
    return type(fallback) == 'function' and fallback() or fallback
  end
end

return {

  -- [[ AUTOCOMPLETION ]] ---------------------------------------------------------------
  {
    'saghen/blink.cmp',
    -- optional: provides snippets for the snippet source
    dependencies = {
      'rafamadriz/friendly-snippets',
      {
        'saghen/blink.compat',
        opts = {},
        dependencies = {
          { 'petertriho/cmp-git', opts = {} },
        },
      },
    },
    version = '*',
    event = 'InsertEnter',
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' for mappings similar to built-in completion
      -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
      -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
      -- See the full "keymap" documentation for information on defining your own keymap.
      keymap = { preset = 'enter' },
      appearance = {
        -- Sets the fallback highlight groups to nvim-cmp's highlight groups
        -- Useful for when your theme doesn't support blink.cmp
        -- Will be removed in a future release
        use_nvim_cmp_as_default = false,
        -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono',
      },
      completion = {
        -- 'prefix' will fuzzy match on the text before the cursor
        -- 'full' will fuzzy match on the text before *and* after the cursor
        -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
        keyword = { range = 'full' },
        -- Disable auto brackets
        -- NOTE: some LSPs may add auto brackets themselves anyway
        accept = { auto_brackets = { enabled = false } },
        -- Don't select by default, auto insert on selection
        list = { selection = { preselect = true, auto_insert = true } },
        -- or set either per mode via a function
        menu = {
          -- Don't automatically show the completion menu
          auto_show = true,
          -- nvim-cmp style menu
          draw = {
            columns = {
              { 'label', 'label_description', gap = 1 },
              { 'kind_icon', 'kind' },
            },
            treesitter = { 'lsp' },
          },
          border = 'rounded',
        },
        -- Show documentation when selecting a completion item
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = {
            border = 'rounded',
          },
        },
        -- Display a preview of the selected item on the current line
        ghost_text = { enabled = false },
      },
      -- Show documentation when selecting a completion item
      -- documentation = { auto_show = true, auto_show_delay_ms = 100 },
      -- Display a preview of the selected item on the current line
      -- ghost_text = { enabled = false },
      signature = { enabled = true },
      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        compat = {},
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },
    },
    opts_extend = { 'sources.default' },
    config = function(_, opts)
      -- setup compat sources
      local enabled = opts.sources.default
      for _, source in ipairs(opts.sources.compat or {}) do
        opts.sources.providers[source] = vim.tbl_deep_extend('force', { name = source, module = 'blink.compat.source' }, opts.sources.providers[source] or {})
        if type(enabled) == 'table' and not vim.tbl_contains(enabled, source) then
          table.insert(enabled, source)
        end
      end

      -- add ai_accept to <Tab> key
      if not opts.keymap['<Tab>'] then
        if opts.keymap.preset == 'super-tab' then -- super-tab
          opts.keymap['<Tab>'] = {
            require('blink.cmp.keymap.presets')['super-tab']['<Tab>'][1],
            map { 'snippet_forward', 'ai_accept' },
            'fallback',
          }
        else -- other presets
          opts.keymap['<Tab>'] = {
            map { 'snippet_forward', 'ai_accept' },
            'fallback',
          }
        end
      end

      -- Unset custom prop to pass blink.cmp validation
      opts.sources.compat = nil

      -- check if we need to override symbol kinds
      for _, provider in pairs(opts.sources.providers or {}) do
        ---@cast provider blink.cmp.SourceProviderConfig|{kind?:string}
        if provider.kind then
          local CompletionItemKind = require('blink.cmp.types').CompletionItemKind
          local kind_idx = #CompletionItemKind + 1

          CompletionItemKind[kind_idx] = provider.kind
          ---@diagnostic disable-next-line: no-unknown
          CompletionItemKind[provider.kind] = kind_idx

          ---@type fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[]
          local transform_items = provider.transform_items
          ---@param ctx blink.cmp.Context
          ---@param items blink.cmp.CompletionItem[]
          provider.transform_items = function(ctx, items)
            items = transform_items and transform_items(ctx, items) or items
            for _, item in ipairs(items) do
              item.kind = kind_idx or item.kind
            end
            return items
          end

          -- Unset custom prop to pass blink.cmp validation
          provider.kind = nil
        end
      end

      require('blink.cmp').setup(opts)
    end,
  },
}
