return {

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'codelldb', 'trivy' })
      end
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'ron', 'rust', 'toml' })
      end
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
      -- make sure mason installs the server
      servers = {
        rust_analyzer = {},
        taplo = {
          keys = {
            {
              'K',
              function()
                if vim.fn.expand '%:t' == 'Cargo.toml' and require('crates').popup_available() then
                  require('crates').show_popup()
                else
                  vim.lsp.buf.hover()
                end
              end,
              desc = 'Show Crate Documentation <K>',
            },
          },
        },
      },
      setup = {
        rust_analyzer = function()
          return true -- avoid duplicate servers
        end,
      },
    },
  },

  -- [rustaceanvim] - LSP extension for Rust.
  -- see: `:h rustaceanvim`
  -- link: https://github.com/mrcjkb/rustaceanvim
  {
    'mrcjkb/rustaceanvim',
    version = '*',
    ft = { 'rust' },
    config = function()
      vim.g.rustaceanvim = {
        -- Plugin configuration
        -- tools = {},
        -- LSP configuration
        server = {
          on_attach = function(client, bufnr)
            local wk = require 'which-key'
            wk.add {
              { '<leader>ca', '<cmd>RustLsp codeAction<cr>', desc = 'Code Action [ca]', mode = 'n', buffer = bufnr },
              { '<leader>ce', '<cmd>RustLsp externalDocs<cr>', desc = 'External Docs [ce]', mode = 'n', buffer = bufnr },
              { '<leader>cp', '<cmd>RustLsp rebuildProcMacros<cr>', desc = 'Rebuild Proc Macros [cp]', mode = 'n', buffer = bufnr },
              { '<leader>cx', '<cmd>RustLsp explainError<cr>', desc = 'Explain Error [cx]', mode = 'n', buffer = bufnr },
              { '<leader>cM', '<cmd>RustLsp expandMacro<cr>', desc = 'Expand Macro [cM]', mode = 'n', buffer = bufnr },
              { '<leader>cg', '<cmd>RustLsp crateGraph<cr>', desc = 'Crates Graph [cg]', mode = 'n', buffer = bufnr },
              { '<leader>cS', '<cmd>RustLsp ssr<cr>', desc = 'SSR [cS]', mode = 'n', buffer = bufnr },
              { '<leader>cj', '<cmd>RustLsp moveItem down<cr>', desc = 'Move Item Down [cj]', mode = 'n', buffer = bufnr },
              { '<leader>ck', '<cmd>RustLsp moveItem up<cr>', desc = 'Move Item Up [ck]', mode = 'n', buffer = bufnr },
              { '<leader>cK', '<cmd>RustLsp hover actions<cr>', desc = 'Hover Actions [cK]', mode = 'n', buffer = bufnr },
              { '<leader>cO', '<cmd>RustLsp openCargo<cr>', desc = 'Open Cargo.toml [co]', mode = 'n', buffer = bufnr },
              { '<leader>cP', '<cmd>RustLsp parentModule<cr>', desc = 'Parent Module [cP]', mode = 'n', buffer = bufnr },
              { '<leader>cJ', '<cmd>RustLsp joinLines<cr>', desc = 'Join Lines [cJ]', mode = 'n', buffer = bufnr },
              { '<leader>ct', '<cmd>RustLsp syntaxTree<cr>', desc = 'Syntax Tree [ct]', mode = 'n', buffer = bufnr },
              { '<leader>dm', '<cmd>RustLsp view mir<cr>', desc = 'View MIR [dm]', mode = 'n', buffer = bufnr },
              { '<leader>dh', '<cmd>RustLsp view hir<cr>', desc = 'View HIR [dh]', mode = 'n', buffer = bufnr },
              { '<leader>dd', '<cmd>RustLsp debuggables<cr>', desc = 'Debuggables [dd]', mode = 'n', buffer = bufnr },
              { '<leader>dl', '<cmd>RustLsp debuggables last<cr>', desc = 'Debuggables last [dl]', mode = 'n', buffer = bufnr },
              { '<leader>ru', '<cmd>RustLsp runnables<cr>', desc = 'Runnables [ru]', mode = 'n', buffer = bufnr },
              { '<leader>rl', '<cmd>RustLsp runnables last<cr>', desc = 'Runnables last [rl]', mode = 'n', buffer = bufnr },
              { '<leader>cK', '<cmd>RustLsp hover range<cr>', desc = 'Hover Ranger [cK]', mode = 'v', buffer = bufnr },
            }
            -- you can also put keymaps in here
            vim.lsp.inlay_hint.enable(true)
          end,
          settings = {
            -- rust-analyzer language server configuration
            ['rust-analyzer'] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                runBuildScripts = true,
              },
              -- Add clippy lints for Rust.
              checkOnSave = {
                allFeatures = true,
                command = 'clippy',
                extraArgs = { '--no-deps' },
              },
              procMacro = {
                enable = true,
                ignored = {
                  ['async-trait'] = { 'async_trait' },
                  ['napi-derive'] = { 'napi' },
                  ['async-recursion'] = { 'async_recursion' },
                },
              },
            },
          },
          -- DAP configuration
          dap = {},
        },
      }
    end,
  },

  {
    'nvim-neotest/neotest',
    opts = {
      adapters = {
        ['rustaceanvim.neotest'] = {},
      },
    },
  },

  -- [crates.nvim] - Rust Crates support.
  -- see: `:h crates.nvim`
  -- link: https://github.com/Saecki/crates.nvim
  {
    'Saecki/crates.nvim',
    branch = 'main',
    event = { 'BufRead Cargo.toml' },
    opts = {
      completion = {
        crates = {
          enabled = true,
        },
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },
}
