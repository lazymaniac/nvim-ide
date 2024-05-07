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
    'mfussenegger/nvim-lint',
    opts = {
      linters_by_ft = {
        rust = { 'trivy' },
      },
    },
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
              ['<leader>ca'] = { function() require('actions-preview').code_actions() end, 'Code Action [ca]' },
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
            vim.lsp.inlay_hint.enable(bufnr, true)
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
    dependencies = { 'rouge8/neotest-rust' },
  },

  {
    'hrsh7th/nvim-cmp',
    dependencies = { 'Saecki/crates.nvim' },
    opts = function(_, opts)
      local cmp = require 'cmp'
      opts.sources = vim.list_extend(
        opts.sources or {},
        cmp.config.sources {
          { name = 'crates' },
        }
      )
    end,
  },

  {
    'Saecki/crates.nvim',
    branch = 'main',
    event = { 'BufRead Cargo.toml' },
    opts = {
      smart_insert = true,
      insert_closing_quote = true,
      avoid_prerelease = true,
      autoload = true,
      autoupdate = true,
      autoupdate_throttle = 250,
      loading_indicator = true,
      date_format = '%Y-%m-%d',
      thousands_separator = '.',
      notification_title = 'Crates',
      curl_args = { '-sL', '--retry', '1' },
      max_parallel_requests = 80,
      open_programs = { 'xdg-open', 'open' },
      disable_invalid_feature_diagnostic = false,
      popup = {
        autofocus = false,
        hide_on_select = false,
        copy_register = '"',
        style = 'minimal',
        border = 'none',
        show_version_date = true,
        show_dependency_version = true,
        max_height = 30,
        min_width = 20,
        padding = 1,
        keys = {
          hide = { 'q', '<esc>' },
          open_url = { '<cr>' },
          select = { '<cr>' },
          select_alt = { 's' },
          toggle_feature = { '<cr>' },
          copy_value = { 'yy' },
          goto_item = { 'gd', 'K', '<C-LeftMouse>' },
          jump_forward = { '<c-i>' },
          jump_back = { '<c-o>', '<C-RightMouse>' },
        },
      },
      src = {
        insert_closing_quote = true,
        text = {
          prerelease = '  pre-release ',
          yanked = '  yanked ',
        },
        coq = {
          enabled = false,
          name = 'Crates',
        },
      },
    },
  },

  {
    'ryo33/nvim-cmp-rust',
    config = function()
      local compare = require 'cmp.config.compare'
      local cmp = require 'cmp'
      cmp.setup.filetype({ 'rust' }, {
        sorting = {
          priority_weight = 2,
          comparators = {
            -- deprioritize `.box`, `.mut`, etc.
            require('cmp-rust').deprioritize_postfix,
            -- deprioritize `Borrow::borrow` and `BorrowMut::borrow_mut`
            require('cmp-rust').deprioritize_borrow,
            -- deprioritize `Deref::deref` and `DerefMut::deref_mut`
            require('cmp-rust').deprioritize_deref,
            -- deprioritize `Into::into`, `Clone::clone`, etc.
            require('cmp-rust').deprioritize_common_traits,
            compare.offset,
            compare.exact,
            compare.score,
            compare.recently_used,
            compare.locality,
            compare.sort_text,
            compare.length,
            compare.order,
          },
        },
      })
    end,
  },
}
