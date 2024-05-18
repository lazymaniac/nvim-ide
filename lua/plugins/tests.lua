return {

  -- [[ TEST RUNNERS ]] ---------------------------------------------------------------
  -- Default test tree for which-key
  {
    'folke/which-key.nvim',
    optional = true,
    opts = {
      defaults = {
        ['<leader>t'] = { name = '+[test]' },
      },
    },
  },

  -- [neotest] - Test runner. List tests available in project
  -- see: `:h neotest`
  -- link: https://github.com/nvim-neotest/neotest
  {
    'nvim-neotest/neotest',
    branch = 'master',
    event = 'VeryLazy',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter', 'stevearc/overseer.nvim', 'nvim-neotest/nvim-nio' },
    -- stylua: ignore
    keys = {
      { '<leader>tt', function() require('neotest').run.run(vim.fn.expand '%') end, desc = 'Run File [tt]', },
      { '<leader>tT', function() require('neotest').run.run(vim.loop.cwd()) end, desc = 'Run All Test Files [tT]', },
      { '<leader>tr', function() require('neotest').run.run() end, desc = 'Run Nearest [tr]', },
      { '<leader>ts', function() require('neotest').summary.toggle() end, desc = 'Toggle Summary [ts]', },
      { '<leader>to', function() require('neotest').output.open { enter = true, auto_close = true } end, desc = 'Show Output [to]', },
      { '<leader>tO', function() require('neotest').output_panel.toggle() end, desc = 'Toggle Output Panel [tO]', },
      { '<leader>tS', function() require('neotest').run.stop() end, desc = 'Stop [ts]', },
    },
    config = function()
      local opts = {
        adapters = {
          ['neotest-java'] = { ignore_wrapper = false },
          require 'rustaceanvim.neotest',
          ['neotest-go'] = {},
          ['neotest-python'] = {},
        },
        benchmark = {
          enabled = true,
        },
        consumers = {
          overseer = require 'neotest.consumers.overseer',
        },
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
          max_height = 0.6,
          max_width = 0.6,
          options = {},
        },
        icons = {
          expanded = '',
          child_prefix = '',
          child_indent = '',
          final_child_prefix = '',
          non_collapsible = '',
          collapsed = '',
          passed = '',
          running = '',
          failed = '',
          unknown = '',
        },
        jump = {
          enabled = true,
        },
        log_level = 3,
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
          open = function()
            if require('util').has 'trouble.nvim' then
              require('trouble').open { mode = 'quickfix', focus = false }
            else
              vim.cmd 'copen'
            end
          end,
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
          enabled = true,
          expand_errors = true,
          follow = true,
          mappings = {
            attach = 'a',
            clear_marked = 'M',
            clear_target = 'T',
            debug = 'd',
            debug_marked = 'D',
            expand = { '<CR>', '<2-LeftMouse>' },
            expand_all = 'e',
            jumpto = 'i',
            mark = 'm',
            next_failed = 'J',
            output = 'o',
            prev_failed = 'K',
            run = 'r',
            run_marked = 'R',
            short = 'O',
            stop = 'u',
            target = 't',
            watch = 'w',
          },
          open = 'botright vsplit | vertical resize 50',
        },
        watch = {
          enabled = true,
          symbol_queries = {
            elixir = '<function 1>',
            go = '        ;query\n        ;Captures imported types\n        (qualified_type name: (type_identifier) @symbol)\n        ;Captures package-local and built-in types\n        (type_identifier)@symbol\n        ;Captures imported function calls and variables/constants\n        (selector_expression field: (field_identifier) @symbol)\n        ;Captures package-local functions calls\n        (call_expression function: (identifier) @symbol)\n      ',
            lua = '        ;query\n        ;Captures module names in require calls\n        (function_call\n          name: ((identifier) @function (#eq? @function "require"))\n          arguments: (arguments (string) @symbol))\n      ',
            python = "        ;query\n        ;Captures imports and modules they're imported from\n        (import_from_statement (_ (identifier) @symbol))\n        (import_statement (_ (identifier) @symbol))\n      ",
          },
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
      if require('util').has 'trouble.nvim' then
        opts.consumers = opts.consumers or {}
        -- Refresh and auto close trouble after running tests
        opts.consumers.trouble = function(client)
          client.listeners.results = function(adapter_id, results, partial)
            if partial then
              return
            end
            local tree = assert(client:get_position(nil, { adapter = adapter_id }))
            local failed = 0
            for pos_id, result in pairs(results) do
              if result.status == 'failed' and tree:get_key(pos_id) then
                failed = failed + 1
              end
            end
            vim.schedule(function()
              local trouble = require 'trouble'
              if trouble.is_open() then
                trouble.refresh()
                if failed == 0 then
                  trouble.close()
                end
              end
            end)
            return {}
          end
        end
      end
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
              elseif meta and meta.__call then
                adapter(config)
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
