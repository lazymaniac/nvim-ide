return {

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'prettierd', 'markdown-toc', 'markdownlint', 'write-good' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'markdown', 'markdown_inline' })
      end
    end,
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        markdown = { { 'prettierd' }, 'markdownlint', 'markdown-toc' },
      },
    },
  },

  {
    'mfussenegger/nvim-lint',
    opts = {
      linters_by_ft = {
        markdown = { 'markdownlint', 'write_good' },
      },
    },
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        marksman = {},
      },
    },
  },

  -- Markdown preview
  {
    'iamcco/markdown-preview.nvim',
    branch = 'master',
    cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
    build = function()
      vim.fn['mkdp#util#install']()
    end,
    -- stylua: ignore
    keys = {
      { '<leader>cp', ft = 'markdown', '<cmd>MarkdownPreviewToggle<cr>', desc = 'Markdown Preview (Browser) [cp]' },
    },
    config = function()
      vim.cmd [[do FileType]]
    end,
  },

  {
    'tadmccorkle/markdown.nvim',
    branch = 'master',
    event = 'VeryLazy',
    opts = {
      -- Disable all keymaps by setting mappings field to 'false'.
      -- Selectively disable keymaps by setting corresponding field to 'false'.
      mappings = {
        inline_surround_toggle = 'gs', -- (string|boolean) toggle inline style
        inline_surround_toggle_line = 'gss', -- (string|boolean) line-wise toggle inline style
        inline_surround_delete = 'ds', -- (string|boolean) delete emphasis surrounding cursor
        inline_surround_change = 'cs', -- (string|boolean) change emphasis surrounding cursor
        link_add = 'gl', -- (string|boolean) add link
        link_follow = 'gx', -- (string|boolean) follow link
        go_curr_heading = ']c', -- (string|boolean) set cursor to current section heading
        go_parent_heading = ']p', -- (string|boolean) set cursor to parent section heading
        go_next_heading = ']]', -- (string|boolean) set cursor to next section heading
        go_prev_heading = '[[', -- (string|boolean) set cursor to previous section heading
      },
      inline_surround = {
        -- For the emphasis, strong, strikethrough, and code fields:
        -- * 'key': used to specify an inline style in toggle, delete, and change operations
        -- * 'txt': text inserted when toggling or changing to the corresponding inline style
        emphasis = {
          key = 'i',
          txt = '*',
        },
        strong = {
          key = 'b',
          txt = '**',
        },
        strikethrough = {
          key = 's',
          txt = '~~',
        },
        code = {
          key = 'c',
          txt = '`',
        },
      },
      link = {
        paste = {
          enable = true, -- whether to convert URLs to links on paste
        },
      },
      toc = {
        -- Comment text to flag headings/sections for omission in table of contents.
        omit_heading = 'toc omit heading',
        omit_section = 'toc omit section',
        -- Cycling list markers to use in table of contents.
        -- Use '.' and ')' for ordered lists.
        markers = { '-' },
      },
      -- Hook functions allow for overriding or extending default behavior.
      -- Called with a table of options and a fallback function with default behavior.
      -- Signature: fun(opts: table, fallback: fun())
      hooks = {
        -- Called when following links. Provided the following options:
        -- * 'dest' (string): the link destination
        -- * 'use_default_app' (boolean|nil): whether to open the destination with default application
        --   (refer to documentation on <Plug> mappings for explanation of when this option is used)
        follow_link = nil,
      },
      on_attach = nil, -- (fun(bufnr: integer)) callback when plugin attaches to a buffer
    },
  },

  {
    'lukas-reineke/headlines.nvim',
    branch = 'main',
    optional = true,
    opts = function()
      local opts = {}
      for _, ft in ipairs { 'markdown', 'norg', 'rmd', 'org' } do
        opts[ft] = {
          headline_highlights = {},
        }
        for i = 1, 6 do
          local hl = 'Headline' .. i
          vim.api.nvim_set_hl(0, hl, { link = 'Headline', default = true })
          table.insert(opts[ft].headline_highlights, hl)
        end
      end
      return opts
    end,
    ft = { 'markdown', 'norg', 'rmd', 'org' },
    config = function(_, opts)
      -- PERF: schedule to prevent headlines slowing down opening a file
      vim.schedule(function()
        require('headlines').setup(opts)
        require('headlines').refresh()
      end)
    end,
  },

  -- [glow.nvim] - Markdown preview in terminal
  -- see: `:h glow.nvim`
  {
    'ellisonleao/glow.nvim',
    branch = 'main',
    -- stylua: ignore
    keys = {
      { '<leader>cP', ft = 'markdown', '<cmd>Glow<cr>', desc = 'Markdown Preview (TUI) [cP]' },
    },
    cmd = 'Glow',
    config = function()
      require('glow').setup {
        border = 'rounded', -- floating window border config
        width = 150,
        height = 100,
        width_ratio = 0.8, -- maximum width of the Glow window compared to the nvim window size (overrides `width`)
        height_ratio = 0.8,
      }
    end,
  },
}
