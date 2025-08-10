return {

  -- [[ SYNTAX HIGHLIGHTING ]] ---------------------------------------------------------------
  -- [nvim-treesitter] - Syntax highlighting.
  -- see: `:h nvim-treesitter`
  -- link: https://github.com/nvim-treesitter/nvim-treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'master',
    lazy = false,
    build = ':TSUpdate',
    keys = {
      { '<c-space>', desc = 'Increment selection <C-SPC>' },
      { '<bs>', desc = 'Decrement selection <BS>', mode = 'x' },
    },
    init = function(plugin)
      require('lazy.core.loader').add_to_rtp(plugin)
      require 'nvim-treesitter.query_predicates'
    end,
    dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects', 'LiadOz/nvim-dap-repl-highlights' },
    cmd = { 'TSUpdateSync', 'TSUpdate', 'TSInstall' },
    ---@diagnostic disable-next-line: missing-fields
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
      ensure_installed = {
        'angular',
        'bash',
        'diff',
        'dot',
        'html',
        'java',
        'xml',
        'properties',
        'jsdoc',
        'json',
        'jsonc',
        'latex',
        'lua',
        'luadoc',
        'luap',
        'markdown',
        'markdown_inline',
        'mermaid',
        'python',
        'query',
        'r',
        'regex',
        'sql',
        'lua_patterns',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
        'dap_repl',
        'http',
        'vue',
        'terraform',
        'hcl',
        'svelte',
        'scala',
        'ron',
        'rust',
        'toml',
        'ruby',
        'ninja',
        'rst',
        'json5',
        'css',
        'scss',
        'javascript',
        'helm',
        'haskell',
        'groovy',
        'kotlin',
        'go',
        'gomod',
        'gowork',
        'gosum',
        'git_config',
        'gitcommit',
        'git_rebase',
        'gitignore',
        'gitattributes',
        'dockerfile',
        'cmake',
        'clojure',
        'c',
        'cpp',
      },
      auto_install = true,
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<C-space>',
          node_incremental = '<C-space>',
          scope_incremental = false,
          node_decremental = '<bs>',
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
          keymaps = {
            -- You can use the capture groups defined in textobjects.scm
            ['aa'] = '@parameter.outer',
            ['ia'] = '@parameter.inner',
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ac'] = '@class.outer',
            ['ic'] = '@class.inner',
            ['il'] = '@loop.inner',
            ['al'] = '@loop.outer',
            ['ii'] = '@conditional.inner',
            ['ai'] = '@conditional.outer',
            ['am'] = '@comment.outer',
            ['im'] = '@comment.inner',
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = {
            [']f'] = '@function.outer',
            [']c'] = '@class.outer',
            [']B'] = { query = '@code_cell.inner', desc = 'next code block' },
          },
          goto_next_end = { [']F'] = '@function.outer', [']C'] = '@class.outer' },
          goto_previous_start = {
            ['[f'] = '@function.outer',
            ['[c'] = '@class.outer',
            ['[B'] = { query = '@code_cell.inner', desc = 'previous code block' },
          },
          goto_previous_end = { ['[F'] = '@function.outer', ['[C'] = '@class.outer' },
        },
        swap = {
          enable = true,
          swap_next = {
            ['<F2>'] = '@parameter.inner',
            ['<F4>'] = '@code_cell.outer',
          },
          swap_previous = {
            ['<F3>'] = '@parameter.inner',
            ['<F5>'] = '@code_cell.outer',
          },
        },
      },
    },
    config = function(_, opts)
      local parser_configs = require('nvim-treesitter.parsers').get_parser_configs()
      parser_configs.lua_patterns = {
        install_info = {
          url = 'https://github.com/OXY2DEV/tree-sitter-lua_patterns',
          files = { 'src/parser.c' },
          branch = 'main',
        },
      }
      if type(opts.ensure_installed) == 'table' then
        ---@type table<string, boolean>
        local added = {}
        opts.ensure_installed = vim.tbl_filter(function(lang)
          if added[lang] then
            return false
          end
          added[lang] = true
          return true
          ---@diagnostic disable-next-line: param-type-mismatch
        end, opts.ensure_installed)
      end
      require('nvim-dap-repl-highlights').setup()
      require('nvim-treesitter.configs').setup(opts)
      -- angular files
      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
        pattern = { '*.component.html', '*.container.html' },
        callback = function()
          vim.treesitter.start(nil, 'angular')
        end,
      })
    end,
  },

  -- [nvim-treesitter-textobjects] - Treesitter textobjects
  -- see: `:h nvim-treesitter-textobjects`
  -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'master',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      -- When in diff mode, we want to use the default
      -- vim text objects c & C instead of the treesitter ones.
      local move = require 'nvim-treesitter.textobjects.move' ---@type table<string,fun(...)>
      local configs = require 'nvim-treesitter.configs'
      for name, fn in pairs(move) do
        if name:find 'goto' == 1 then
          move[name] = function(q, ...)
            if vim.wo.diff then
              local config = configs.get_module('textobjects.move')[name] ---@type table<string,string>
              for key, query in pairs(config or {}) do
                if q == query and key:find '[%]%[][cC]' then
                  vim.cmd('normal! ' .. key)
                  return
                end
              end
            end
            return fn(q, ...)
          end
        end
      end
    end,
  },

  -- [nvim-ts-autotags] - Automatically add closing tags for HTML and JSX
  -- see: `:h nvim-ts-autotags`
  -- link: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  {
    'windwp/nvim-ts-autotag',
    branch = 'main',
    event = 'InsertEnter',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {},
  },

  {
    'nvim-treesitter/nvim-treesitter-context',
    event = 'BufReadPost',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {},
  },
}
