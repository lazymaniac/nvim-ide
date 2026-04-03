return {

  -- [[ SYNTAX HIGHLIGHTING ]] ---------------------------------------------------------------
  -- [nvim-treesitter] - Syntax highlighting.
  -- see: `:h nvim-treesitter`
  -- link: https://github.com/nvim-treesitter/nvim-treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    cmd = { 'TSUpdateSync', 'TSUpdate', 'TSInstall' },
    ---@diagnostic disable-next-line: missing-fields
    opts = {
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
    },
    config = function(_, opts)
      require('nvim-dap-repl-highlights').setup()
      require('nvim-treesitter').install(opts.ensure_installed)
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter.setup', {}),
        callback = function(args)
          local buf = args.buf
          local filetype = args.match

          -- you need some mechanism to avoid running on buffers that do not
          -- correspond to a language (like oil.nvim buffers), this implementation
          -- checks if a parser exists for the current language
          local language = vim.treesitter.language.get_lang(filetype) or filetype
          if not vim.treesitter.language.add(language) then
            return
          end

          -- replicate `fold = { enable = true }`
          vim.wo.foldmethod = 'expr'
          vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

          -- replicate `highlight = { enable = true }`
          vim.treesitter.start(buf, language)

          -- replicate `indent = { enable = true }`
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

          -- `incremental_selection = { enable = true }` covered by 0.12.0
        end,
      })
    end,
  },

  -- [nvim-treesitter-textobjects] - Treesitter textobjects
  -- see: `:h nvim-treesitter-textobjects`
  -- https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    lazy = false,
    init = function()
      vim.g.no_plugin_maps = true
    end,
    keys = {
      {
        ';',
        function()
          require('nvim-treesitter-textobjects.repeatable_move').repeat_last_move_next()
        end,
        desc = 'Repeat last move next',
        mode = { 'n', 'x', 'o' },
      },
      {
        ',',
        function()
          require('nvim-treesitter-textobjects.repeatable_move').repeat_last_move_previous()
        end,
        desc = 'Repeat last move previous',
        mode = { 'n', 'x', 'o' },
      },
      {
        'am',
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@function.outer', 'textobjects')
        end,
        desc = 'Select function outer',
        mode = { 'x', 'o' },
      },
      {
        'im',
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@function.inner', 'textobjects')
        end,
        desc = 'Select function inner',
        mode = { 'x', 'o' },
      },
      {
        'ac',
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects')
        end,
        desc = 'Select class outer',
        mode = { 'x', 'o' },
      },
      {
        'ic',
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects')
        end,
        desc = 'Select class inner',
        mode = { 'x', 'o' },
      },
      {
        'as',
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@local.scope', 'locals')
        end,
        desc = 'Select local scope',
        mode = { 'x', 'o' },
      },
      {
        ']m',
        function()
          require('nvim-treesitter-textobjects.move').goto_next_start('@function.outer', 'textobjects')
        end,
        desc = 'Goto next function',
        mode = { 'n', 'x', 'o' },
      },
      {
        '[m',
        function()
          require('nvim-treesitter-textobjects.move').goto_previous_start('@function.outer', 'textobjects')
        end,
        desc = 'Goto previous function',
        mode = { 'n', 'x', 'o' },
      },
      {
        ']M',
        function()
          require('nvim-treesitter-textobjects.move').goto_next_end('@function.outer', 'textobjects')
        end,
        desc = 'Goto next function end',
        mode = { 'n', 'x', 'o' },
      },
      {
        '[M',
        function()
          require('nvim-treesitter-textobjects.move').goto_previous_end('@function.outer', 'textobjects')
        end,
        desc = 'Goto previous function end',
        mode = { 'n', 'x', 'o' },
      },
      {
        ']o',
        function()
          require('nvim-treesitter-textobjects.move').goto_next_start({ '@loop.inner', '@loop.outer' }, 'textobjects')
        end,
        desc = 'Goto next loop',
        mode = { 'n', 'x', 'o' },
      },
      {
        '[o',
        function()
          require('nvim-treesitter-textobjects.move').goto_previous_start({ '@loop.inner', '@loop.outer' }, 'textobjects')
        end,
        desc = 'Goto previous loop',
        mode = { 'n', 'x', 'o' },
      },
      {
        ']s',
        function()
          require('nvim-treesitter-textobjects.move').goto_next_start('@local.scope', 'locals')
        end,
        desc = 'Goto next scope',
        mode = { 'n', 'x', 'o' },
      },
      {
        '[s',
        function()
          require('nvim-treesitter-textobjects.move').goto_previous_start('@local.scope', 'locals')
        end,
        desc = 'Goto previous scope',
        mode = { 'n', 'x', 'o' },
      },
      {
        ']z',
        function()
          require('nvim-treesitter-textobjects.move').goto_next_start('@fold', 'folds')
        end,
        desc = 'Goto next fold',
        mode = { 'n', 'x', 'o' },
      },
      {
        '[z',
        function()
          require('nvim-treesitter-textobjects.move').goto_previous_start('@fold', 'folds')
        end,
        desc = 'Goto previous fold',
        mode = { 'n', 'x', 'o' },
      },
      {
        ']d',
        function()
          require('nvim-treesitter-textobjects.move').goto_next('@conditional.outer', 'textobjects')
        end,
        desc = 'Goto next conditional',
        mode = { 'n', 'x', 'o' },
      },
      {
        '[d',
        function()
          require('nvim-treesitter-textobjects.move').goto_previous('@conditional.outer', 'textobjects')
        end,
        desc = 'Goto previous conditional',
        mode = { 'n', 'x', 'o' },
      },
    },
    opts = {
      select = {
        lookahead = true,
        selection_modes = {
          ['@parameter.outer'] = 'v',
          ['@function.outer'] = 'V',
        },
        include_surrounding_whitespace = false,
      },
    },
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
}
