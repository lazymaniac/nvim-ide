return {

  -- Extend auto completion
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      {
        'Saecki/crates.nvim',
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
          text = {
            loading = '   Loading',
            version = '   %s',
            prerelease = '   %s',
            yanked = '   %s',
            nomatch = '   No match',
            upgrade = '   %s',
            error = '   Error fetching crate',
          },
          highlight = {
            loading = 'CratesNvimLoading',
            version = 'CratesNvimVersion',
            prerelease = 'CratesNvimPreRelease',
            yanked = 'CratesNvimYanked',
            nomatch = 'CratesNvimNoMatch',
            upgrade = 'CratesNvimUpgrade',
            error = 'CratesNvimError',
          },
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
            text = {
              title = ' %s',
              pill_left = '',
              pill_right = '',
              description = '%s',
              created_label = ' created        ',
              created = '%s',
              updated_label = ' updated        ',
              updated = '%s',
              downloads_label = ' downloads      ',
              downloads = '%s',
              homepage_label = ' homepage       ',
              homepage = '%s',
              repository_label = ' repository     ',
              repository = '%s',
              documentation_label = ' documentation  ',
              documentation = '%s',
              crates_io_label = ' crates.io      ',
              crates_io = '%s',
              categories_label = ' categories     ',
              keywords_label = ' keywords       ',
              version = '  %s',
              prerelease = ' %s',
              yanked = ' %s',
              version_date = '  %s',
              feature = '  %s',
              enabled = ' %s',
              transitive = ' %s',
              normal_dependencies_title = ' Dependencies',
              build_dependencies_title = ' Build dependencies',
              dev_dependencies_title = ' Dev dependencies',
              dependency = '  %s',
              optional = ' %s',
              dependency_version = '  %s',
              loading = '  ',
            },
            highlight = {
              title = 'CratesNvimPopupTitle',
              pill_text = 'CratesNvimPopupPillText',
              pill_border = 'CratesNvimPopupPillBorder',
              description = 'CratesNvimPopupDescription',
              created_label = 'CratesNvimPopupLabel',
              created = 'CratesNvimPopupValue',
              updated_label = 'CratesNvimPopupLabel',
              updated = 'CratesNvimPopupValue',
              downloads_label = 'CratesNvimPopupLabel',
              downloads = 'CratesNvimPopupValue',
              homepage_label = 'CratesNvimPopupLabel',
              homepage = 'CratesNvimPopupUrl',
              repository_label = 'CratesNvimPopupLabel',
              repository = 'CratesNvimPopupUrl',
              documentation_label = 'CratesNvimPopupLabel',
              documentation = 'CratesNvimPopupUrl',
              crates_io_label = 'CratesNvimPopupLabel',
              crates_io = 'CratesNvimPopupUrl',
              categories_label = 'CratesNvimPopupLabel',
              keywords_label = 'CratesNvimPopupLabel',
              version = 'CratesNvimPopupVersion',
              prerelease = 'CratesNvimPopupPreRelease',
              yanked = 'CratesNvimPopupYanked',
              version_date = 'CratesNvimPopupVersionDate',
              feature = 'CratesNvimPopupFeature',
              enabled = 'CratesNvimPopupEnabled',
              transitive = 'CratesNvimPopupTransitive',
              normal_dependencies_title = 'CratesNvimPopupNormalDependenciesTitle',
              build_dependencies_title = 'CratesNvimPopupBuildDependenciesTitle',
              dev_dependencies_title = 'CratesNvimPopupDevDependenciesTitle',
              dependency = 'CratesNvimPopupDependency',
              optional = 'CratesNvimPopupOptional',
              dependency_version = 'CratesNvimPopupDependencyVersion',
              loading = 'CratesNvimPopupLoading',
            },
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
          null_ls = {
            enabled = true,
            name = 'Crates',
          },
        },
      },
    },
    opts = function(_, opts)
      local cmp = require 'cmp'
      opts.sources = cmp.config.sources(vim.list_extend(opts.sources, {
        { name = 'crates' },
      }))
    end,
  },

  -- Add Rust & related to treesitter
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'ron', 'rust', 'toml' })
      end
    end,
  },

  -- Ensure Rust debugger is installed
  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'codelldb' })
      end
    end,
  },

  {
    'simrat39/rust-tools.nvim',
    ft = 'rs',
    opts = function()
      local ok, mason_registry = pcall(require, 'mason-registry')
      local adapter ---@type any
      if ok then
        -- rust tools configuration for debugging support
        local codelldb = mason_registry.get_package 'codelldb'
        local extension_path = codelldb:get_install_path() .. '/extension/'
        local codelldb_path = extension_path .. 'adapter/codelldb'
        local liblldb_path = ''
        if vim.loop.os_uname().sysname:find 'Windows' then
          liblldb_path = extension_path .. 'lldb\\bin\\liblldb.dll'
        elseif vim.fn.has 'mac' == 1 then
          liblldb_path = extension_path .. 'lldb/lib/liblldb.dylib'
        else
          liblldb_path = extension_path .. 'lldb/lib/liblldb.so'
        end
        adapter = require('rust-tools.dap').get_codelldb_adapter(codelldb_path, liblldb_path)
      end
      return {
        dap = {
          adapter = adapter,
        },
        tools = {
          on_initialized = function()
            vim.cmd [[
                  augroup RustLSP
                    autocmd CursorHold                      *.rs silent! lua vim.lsp.buf.document_highlight()
                    autocmd CursorMoved,InsertEnter         *.rs silent! lua vim.lsp.buf.clear_references()
                    autocmd BufEnter,CursorHold,InsertLeave *.rs silent! lua vim.lsp.codelens.refresh()
                  augroup END
                ]]
          end,
        },
      }
    end,
    config = function() end,
  },

  -- Correctly setup lspconfig for Rust 🚀
  {
    'neovim/nvim-lspconfig',
    opts = {
      servers = {
        -- Ensure mason installs the server
        rust_analyzer = {
          keys = {
            { 'K', '<cmd>RustHoverActions<cr>', desc = 'Hover Actions (Rust)' },
            { '<leader>cR', '<cmd>RustCodeAction<cr>', desc = 'Code Action (Rust)' },
            { '<leader>dr', '<cmd>RustDebuggables<cr>', desc = 'Run Debuggables (Rust)' },
          },
          settings = {
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
        },
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
              desc = 'Show Crate Documentation',
            },
          },
        },
      },
      setup = {
        rust_analyzer = function(_, opts)
          local rust_tools_opts = require('util').opts 'rust-tools.nvim'
          require('rust-tools').setup(vim.tbl_deep_extend('force', rust_tools_opts or {}, { server = opts }))
          return true
        end,
      },
    },
  },

  {
    'nvim-neotest/neotest',
    dependencies = {
      'rouge8/neotest-rust',
    },
    opts = {
      adapters = {
        ['neotest-rust'] = {},
      },
    },
  },
}
