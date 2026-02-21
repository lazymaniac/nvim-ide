return {

  -- [[ TEST RUNNERS ]] ---------------------------------------------------------------

  -- [neotest] - Test runner. List tests available in project
  -- see: `:h neotest`
  -- link: https://github.com/nvim-neotest/neotest
  {
    'nvim-neotest/neotest',
    branch = 'master',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'stevearc/overseer.nvim',
      'nvim-neotest/nvim-nio',
      -- adapters
      {
        'nvim-neotest/neotest-go',
        branch = 'main',
      },
      {
        'mrcjkb/neotest-haskell',
        branch = 'master',
      },
      {
        'rcasia/neotest-java',
        branch = 'main',
      },
      {
        'nvim-neotest/neotest-jest',
        branch = 'main',
      },
      {
        'nvim-neotest/neotest-python',
        branch = 'master',
      },
      {
        'thenbe/neotest-playwright',
        branch = 'master',
      },
      {
        'olimorris/neotest-rspec',
        branch = 'main',
      },
      {
        'marilari88/neotest-vitest',
        branch = 'main',
      },
      {
        'zidhuss/neotest-minitest',
        branch = 'main',
      },
    },
    -- stylua: ignore
    keys = {
      { '<leader>tt', function() require('neotest').run.run(vim.fn.expand '%') end, desc = 'Run File [tt]', },
      { '<leader>tT', function() require('neotest').run.run(vim.loop.cwd()) end, desc = 'Run All Test Files [tT]', },
      { '<leader>tr', function() require('neotest').run.run() end, desc = 'Run Nearest [tr]', },
      { '<leader>tR', function() require("neotest").run.run_last() end, desc = 'Rerun last [tR]', },
      { '<leader>ta', function() require("neotest").run.attach() end, desc = 'Attach to Nearest [ta]', },
      { '<leader>ts', function() require('neotest').summary.toggle() end, desc = 'Toggle Summary [ts]', },
      { '<leader>to', function() require('neotest').output.open { enter = true, auto_close = true } end, desc = 'Show Output [to]', },
      { '<leader>tO', function() require('neotest').output_panel.toggle() end, desc = 'Toggle Output Panel [tO]', },
      { '<leader>tS', function() require('neotest').run.stop() end, desc = 'Stop [ts]', },
      { '<leader>tc', function() require('neotest').output_panel.clear() end, desc = 'Clear Output Panel [tc]', },
      { "<leader>tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle Watch [tw]" },
    },
    config = function()
      local wk = require 'which-key'
      local defaults = {
        { '<leader>t', group = '+[test]' },
      }
      wk.add(defaults)
      local opts = {
        adapters = {
          ['neotest-java'] = { ignore_wrapper = false },
          ['rustaceanvim.neotest'] = {},
          ['neotest-go'] = {},
          ['neotest-haskell'] = {},
          ['neotest-python'] = {
            dap = { justMyCode = false },
            args = { '--log-level', 'DEBUG' },
            runner = 'pytest',
            python = '.venv/bin/python',
            pytest_discover_instances = true,
          },
          ['neotest-playwright'] = {
            options = {
              persist_project_selection = true,
              enable_dynamic_test_discovery = true,
            },
          },
          ['neotest-rspec'] = {
            rspec_cmd = function()
              return vim.tbl_flatten {
                'bundle',
                'exec',
                'rspec',
              }
            end,
          },
          ['neotest-jest'] = {
            jestCommand = 'npm test --',
            jestConfigFile = 'custom.jest.config.ts',
            env = { CI = true },
            cwd = function(path)
              return vim.fn.getcwd()
            end,
          },
          ['neotest-vitest'] = {
            filter_dir = function(name, _, _)
              return name ~= 'node_modules'
            end,
          },
          ['neotest-minitest'] = {
            test_cmd = function()
              return vim.tbl_flatten {
                'bundle',
                'exec',
                'ruby',
                '-Itest',
              }
            end,
          },
        },
        benchmark = {
          enabled = true,
        },
        consumers = {},
        default_strategy = 'integrated',
        diagnostic = {
          enabled = true,
          severity = 1,
        },
        discovery = {
          concurrent = 0,
          enabled = true,
        },
        floating = {
          border = 'rounded',
          max_height = 0.8,
          max_width = 0.8,
          options = {},
        },
        icons = {
          child_indent = '│',
          child_prefix = '├',
          collapsed = '─',
          expanded = '╮',
          failed = '',
          final_child_indent = ' ',
          final_child_prefix = '╰',
          non_collapsible = '─',
          notify = '',
          passed = '',
          running = '',
          running_animated = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' },
          skipped = '',
          unknown = '',
          watching = '',
        },
        jump = {
          enabled = true,
        },
        log_level = vim.log.levels.DEBUG,
        output = {
          enabled = true,
          open_on_run = 'short',
        },
        output_panel = {
          enabled = true,
          open = 'botright split | resize 15',
        },
        projects = {},
        quickfix = {
          enabled = true,
          open = false,
        },
        run = {
          enabled = true,
        },
        running = {
          concurrent = true,
        },
        state = {
          enabled = true,
        },
        status = {
          enabled = true,
          signs = true,
          virtual_text = true,
        },
        strategies = {
          integrated = {
            height = 40,
            width = 120,
          },
        },
        summary = {
          animated = true,
          count = true,
          enabled = true,
          expand_errors = true,
          follow = true,
          open = 'botright vsplit | vertical resize 50',
        },
        watch = {
          enabled = true,
        },
      }
      local neotest_ns = vim.api.nvim_create_namespace 'neotest'
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            -- Replace newline and tab characters with space for more compact diagnostics
            local message = diagnostic.message:gsub('\n', ' '):gsub('\t', ' '):gsub('%s+', ' '):gsub('^%s+', '')
            return message
          end,
        },
      }, neotest_ns)
      if opts.adapters then
        local adapters = {}
        for name, config in pairs(opts.adapters or {}) do
          if type(name) == 'number' then
            if type(config) == 'string' then
              config = require(config)
            end
            adapters[#adapters + 1] = config
          elseif config ~= false then
            local adapter = require(name)
            if type(config) == 'table' and not vim.tbl_isempty(config) then
              local meta = getmetatable(adapter)
              if adapter.setup then
                adapter.setup(config)
              elseif adapter.adapter then
                adapter.adapter(config)
                adapter = adapter.adapter
              elseif meta and meta.__call then
                adapter = adapter(config)
              else
                error('Adapter ' .. name .. ' does not support setup')
              end
            end
            adapters[#adapters + 1] = adapter
          end
        end
        opts.adapters = adapters
      end
      require('neotest').setup(opts)
    end,
  },

  -- DAP integration
  {
    'mfussenegger/nvim-dap',
    branch = 'master',
    optional = true,
    -- stylua: ignore
    keys = {
      ---@diagnostic disable-next-line: missing-fields
      { '<leader>td', function() require('neotest').run.run { strategy = 'dap' } end, desc = 'Debug Nearest [td]', },
    },
  },
}
