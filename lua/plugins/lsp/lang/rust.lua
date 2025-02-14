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
    branch = 'master',
    ft = { 'rust' },
    config = function()
      vim.g.rustaceanvim = {
        -- Plugin configuration
        -- tools = {},
        -- LSP configuration
        server = {
          ---@diagnostic disable-next-line: unused-local
          on_attach = function(client, bufnr)
            local wk = require 'which-key'
            wk.register({
              -- stylua: ignore
              ['<leader>ca'] = { '<cmd>RustLsp codeAction<cr>', 'Code Action [ca]' },
              ['<leader>ce'] = { '<cmd>RustLsp externalDocs<cr>', 'External Docs [ce]' },
              ['<leader>cp'] = { '<cmd>RustLsp rebuildProcMacros<cr>', 'Rebuild Proc Macros [cp]' },
              ['<leader>cx'] = { '<cmd>RustLsp explainError<cr>', 'Explain Error [cx]' },
              ['<leader>cM'] = { '<cmd>RustLsp expandMacro<cr>', 'Expand Macro [cM]' },
              ['<leader>cg'] = { '<cmd>RustLsp crateGraph<cr>', 'Crates Graph [cg]' },
              ['<leader>cS'] = { '<cmd>RustLsp ssr<cr>', 'SSR [cS]' },
              ['<leader>cj'] = { '<cmd>RustLsp moveItem down<cr>', 'Move Item Down [cj]' },
              ['<leader>ck'] = { '<cmd>RustLsp moveItem up<cr>', 'Move Item Up [ck]' },
              ['<leader>cK'] = { '<cmd>RustLsp hover actions<cr>', 'Hover Actions [cK]' },
              ['<leader>cO'] = { '<cmd>RustLsp openCargo<cr>', 'Open Cargo.toml [co]' },
              ['<leader>cP'] = { '<cmd>RustLsp parentModule<cr>', 'Parent Module [cP]' },
              ['<leader>cJ'] = { '<cmd>RustLsp joinLines<cr>', 'Join Lines [cJ]' },
              ['<leader>ct'] = { '<cmd>RustLsp syntaxTree<cr>', 'Syntax Tree [ct]' },
              ['<leader>dm'] = { '<cmd>RustLsp view mir<cr>', 'View MIR [dm]' },
              ['<leader>dh'] = { '<cmd>RustLsp view hir<cr>', 'View HIR [dh]' },
              ['<leader>dd'] = { '<cmd>RustLsp debuggables<cr>', 'Debuggables [dd]' },
              ['<leader>dl'] = { '<cmd>RustLsp debuggables last<cr>', 'Debuggables last [dl]' },
              ['<leader>ru'] = { '<cmd>RustLsp runnables<cr>', 'Runnables [ru]' },
              ['<leader>rl'] = { '<cmd>RustLsp runnables last<cr>', 'Runnables last [rl]' },
            }, { mode = 'n', buffer = bufnr })
            wk.register({
              ['<leader>cK'] = { '<cmd>RustLsp hover range<cr>', 'Hover Ranger [cK]' },
            }, { mode = 'v', buffer = bufnr })
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
        ["rustaceanvim.neotest"] = {},
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
