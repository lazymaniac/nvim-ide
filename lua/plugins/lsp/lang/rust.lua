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

  -- Configure nvim-lspconfig to install the server automatically via mason, but
  -- defer actually starting it to our configuration of rustacean below.
  {
    'neovim/nvim-lspconfig',
    opts = {
      -- make sure mason installs the server
      servers = {
        rust_analyzer = {},
      },
      setup = {
        rust_analyzer = function()
          return true -- avoid duplicate servers
        end,
      },
    },
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
    'mrcjkb/rustaceanvim',
    version = '^3', -- Recommended
    ft = { 'rust' },
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
