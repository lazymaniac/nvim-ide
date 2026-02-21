local function get_args(config)
  local args = type(config.args) == 'function' and (config.args() or {}) or config.args or {}
  config = vim.deepcopy(config)
  config.args = function()
    local new_args = vim.fn.input('Run with args: ', table.concat(args, ' '))
    return vim.split(vim.fn.expand(new_args))
  end
  return config
end

return {

  -- [[ DEBUG ]] ---------------------------------------------------------------

  -- [nvim-dap] - Debug in neovim
  -- see: `:h nvim-dap`
  -- link: https://github.com/mfussenegger/nvim-dap
  {
    'mfussenegger/nvim-dap',
    branch = 'master',
    event = 'LspAttach',
    dependencies = {
      -- [nvim-dap-view] - Visualize nvim-dap sessions
      -- see: `:h nvim-dap-view`
      -- link: https://github.com/igorlfs/nvim-dap-view
      {
        'igorlfs/nvim-dap-view',
        keys = {
          { '<leader>dw', '<cmd>DapViewWatch<cr>', mode = { 'n', 'v' }, desc = 'Watch expression' },
        },
        opts = {
          winbar = {
            show = true,
            -- You can add a "console" section to merge the terminal with the other views
            sections = { 'watches', 'scopes', 'exceptions', 'breakpoints', 'threads', 'repl' },
            -- Must be one of the sections declared above (except for "console")
            default_section = 'watcher',
            show_keymap_hints = true,
            base_sections = {
              -- Labels can be set dynamically with functions
              -- Each function receives the window's width and the current section as arguments
              breakpoints = { label = 'Breakpoints', keymap = 'B' },
              scopes = { label = 'Scopes', keymap = 'S' },
              exceptions = { label = 'Exceptions', keymap = 'E' },
              watches = { label = 'Watches', keymap = 'W' },
              threads = { label = 'Threads', keymap = 'T' },
              repl = { label = 'REPL', keymap = 'R' },
              sessions = { label = 'Sessions', keymap = 'K' },
              console = { label = 'Console', keymap = 'C' },
            },
            -- Add your own sections
            custom_sections = {},
            controls = {
              enabled = true,
              position = 'right',
              buttons = {
                'play',
                'step_into',
                'step_over',
                'step_out',
                'step_back',
                'run_last',
                'terminate',
                'disconnect',
              },
              custom_buttons = {},
            },
          },
          windows = {
            -- `prev` is the last used position, might be nil
            position = function(prev)
              local wins = vim.api.nvim_tabpage_list_wins(0)

              -- Restores previous position if terminal is visible
              if vim.iter(wins):find(function(win)
                return vim.w[win].dapview_win_term
              end) then
                return prev
              end

              return vim.tbl_count(vim
                .iter(wins)
                :filter(function(win)
                  local buf = vim.api.nvim_win_get_buf(win)
                  local valid_buftype = vim.tbl_contains({ '', 'help', 'prompt', 'quickfix', 'terminal' }, vim.bo[buf].buftype)
                  local dapview_win = vim.w[win].dapview_win or vim.w[win].dapview_win_term
                  return valid_buftype and not dapview_win
                end)
                :totable()) > 1 and 'below' or 'right'
            end,
            size = function(pos)
              return pos == 'below' and 0.25 or 0.5
            end,
            terminal = {
              -- `pos` is the position for the regular window
              position = function(pos)
                return pos == 'below' and 'right' or 'below'
              end,
              size = 0.5,
            },
          },
          help = {
            border = nil,
          },
          render = {
            -- Optionally a function that takes two `dap.Variable`'s as arguments
            -- and is forwarded to a `table.sort` when rendering variables in the scopes view
            sort_variables = nil,
            -- Full control of how frames are rendered, see the "Custom Formatting" page
            threads = {
              -- Choose which items to display and how
              format = function(name, lnum, path)
                return {
                  { part = name, separator = ' ' },
                  { part = path, hl = 'FileName', separator = ':' },
                  { part = lnum, hl = 'LineNumber' },
                }
              end,
              -- Align columns
              align = false,
            },
            -- Full control of how breakpoints are rendered, see the "Custom Formatting" page
            breakpoints = {
              -- Choose which items to display and how
              format = function(line, lnum, path)
                return {
                  { part = path, hl = 'FileName' },
                  { part = lnum, hl = 'LineNumber' },
                  { part = line, hl = true },
                }
              end,
              -- Align columns
              align = false,
            },
          },
          -- Controls how to jump when selecting a breakpoint or navigating the stack
          -- Comma separated list, like the built-in 'switchbuf'. See :help 'switchbuf'
          -- Only a subset of the options is available: newtab, useopen, usetab and uselast
          -- Can also be a function that takes the current winnr and the bufnr that will jumped to
          -- If a function, should return the winnr of the destination window
          switchbuf = 'usetab,uselast',
          -- Auto open when a session is started and auto close when all sessions finish
          -- Alternatively, can be a string:
          -- - "keep_terminal": as above, but keeps the terminal when the session finishes
          -- - "open_term": open the terminal when starting a new session, nothing else
          auto_toggle = false,
          -- Reopen dapview when switching to a different tab
          -- Can also be a function to dynamically choose when to follow, by returning a boolean
          -- If a function, receives the name of the adapter for the current session as an argument
          follow_tab = false,
          -- Controls how to jump when selecting a breakpoint or navigating the stack
        },
      },
      -- [nvim-dap-virtual-text] - Virtual text for debbug session
      -- see: `:h nvim-dap-virtual-text`
      -- link: https://github.com/theHamsta/nvim-dap-virtual-text
      {
        'theHamsta/nvim-dap-virtual-text',
        branch = 'master',
        -- stylua: ignore
        keys = {
          { '<leader>dv', '<cmd>DapVirtualTextToggle<cr>', desc = 'Toggle DAP Virtual Text [dv]', mode = { 'n', 'v' } },
        },
        opts = {
          enabled = true, -- enable this plugin (the default)
          enabled_commands = true, -- create commands DapVirtualTextEnable, DapVirtualTextDisable, DapVirtualTextToggle, (DapVirtualTextForceRefresh for refreshing when debug adapter did not notify its termination)
          highlight_changed_variables = true, -- highlight changed values with NvimDapVirtualTextChanged, else always NvimDapVirtualText
          highlight_new_as_changed = false, -- highlight new variables in the same way as changed variables (if highlight_changed_variables)
          show_stop_reason = true, -- show stop reason when stopped for exceptions
          commented = false, -- prefix virtual text with comment string
          only_first_definition = false, -- only show virtual text at first definition (if there are multiple)
          all_references = true, -- show virtual text on all all references of the variable (not only definitions)
          clear_on_continue = false, -- clear virtual text on "continue" (might cause flickering when stepping)
          ---@diagnostic disable-next-line: unused-local
          display_callback = function(variable, buf, stackframe, node, options)
            if options.virt_text_pos == 'inline' then
              return ' = ' .. variable.value
            else
              return variable.name .. ' = ' .. variable.value
            end
          end,
          -- position of virtual text, see `:h nvim_buf_set_extmark()`, default tries to inline the virtual text. Use 'eol' to set to end of line
          virt_text_pos = vim.fn.has 'nvim-0.10' == 1 and 'inline' or 'eol',
          -- experimental features:
          all_frames = false, -- show virtual text for all stack frames not only current. Only works for debugpy on my machine.
          virt_lines = false, -- show virtual lines instead of virtual text (will flicker!)
          virt_text_win_col = nil, -- position the virtual text at a fixed window column (starting from the first text column) ,
          -- e.g. 80 to position at column 80, see `:h nvim_buf_set_extmark()`
        },
      },
      -- [mason-nvim-dap] - Couple Mason with nvim dap for automatic installation of debug servers
      -- see: `:h mason-nvim-dap`
      -- link: https://github.com/theHamsta/nvim-dap-virtual-text
      {
        'jay-babu/mason-nvim-dap.nvim',
        branch = 'main',
        event = 'LspAttach',
        dependencies = { 'mason-org/mason.nvim' },
        cmd = { 'DapInstall', 'DapUninstall' },
        opts = {
          -- Makes a best effort to setup the various debuggers with
          -- reasonable debug configurations
          automatic_installation = true,
          -- You can provide additional configuration to the handlers,
          -- see mason-nvim-dap README for more information
          handlers = {},
          -- You'll need to check that you have the required things installed
          -- online, please don't ask me how to install them :)
          ensure_installed = {
            -- Update this to ensure that you have the debuggers for the langs you want
          },
        },
      },
      { 'stevearc/overseer.nvim', branch = 'master' },
      { 'LiadOz/nvim-dap-repl-highlights', branch = 'master' },
      {
        'leoluz/nvim-dap-go',
        config = true,
      },
    },
    -- stylua: ignore
    keys = {
      { '<F1>', function() require('dap').continue() end, desc = 'Continue [dc]' },
      { '<F2>', function() require('dap').step_into() end, desc = 'Step Into [di]' },
      { '<F3>', function() require('dap').step_over() end, desc = 'Step Over [do]' },
      { '<F4>', function() require('dap').step_out() end, desc = 'Step Out [dO]' },
      { '<F5>', function() require('dap').run_last() end, desc = 'Run Last [dl]' },
      { '<F6>', function() require('dap').terminate() end, desc = 'Terminate [dq]' },
      { '<F7>', function() require('dap').pause() end, desc = 'Pause [dp]' },
      { '<leader>da', function() require('dap').continue { before = get_args } end, desc = 'Run with Args [da]' },
      { '<leader>dC', function() require('dap').run_to_cursor() end, desc = 'Run to Cursor [dC]' },
    },
    config = function()
      local dap = require 'dap'
      dap.configurations.java = {
        {
          type = 'java',
          request = 'attach',
          name = 'Debug (Attach) - Remote',
          hostName = '127.0.0.1',
          port = 5005,
        },
      }
      -- set up listneres to open dap view
      local dv = require 'dap-view'
      dap.listeners.before.attach['dap-view-config'] = function()
        dv.open()
      end
      dap.listeners.before.launch['dap-view-config'] = function()
        dv.open()
      end
      dap.listeners.before.event_terminated['dap-view-config'] = function()
        dv.close()
      end
      dap.listeners.before.event_exited['dap-view-config'] = function()
        dv.close()
      end
      local Config = require 'config'
      vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, link = 'Visual' })
      for name, sign in pairs(Config.icons.dap) do
        sign = type(sign) == 'table' and sign or { sign }
        vim.fn.sign_define('Dap' .. name, { text = sign[1], texthl = sign[2] or 'DiagnosticInfo', linehl = sign[3], numhl = sign[3] })
      end
    end,
  },

  -- [persistent-breakpoints.nvim] - Store breakpoints location on disk and load them on buffer open event.
  -- see: `:h persistent-breakpoints.nvim`
  -- link: https://github.com/Weissle/persistent-breakpoints.nvim
  {
    'Weissle/persistent-breakpoints.nvim',
    branch = 'main',
    keys = {
      { '<leader>dB', '<cmd>PBSetConditionalBreakpoint<cr>', desc = 'Conditional Breakpoint [dB]' },
      { '<leader>db', '<cmd>PBToggleBreakpoint<cr>', desc = 'Toggle Breakpoint [db]' },
      { '<leader>dx', '<cmd>PBClearAllBreakpoints<cr>', desc = 'Clear all Breakpoints [dx]' },
    },
    opts = {
      save_dir = vim.fn.stdpath 'cache' .. '/nvim_breakpoints',
      load_breakpoints_event = { 'BufReadPost' },
      perf_record = false,
      on_load_breakpoint = nil,
      always_reload = true,
    },
  },

  -- [nvim-dap-exception-breakpoints] - Breakpoints for exceptions in nvim-dap.
  -- see: `:h nvim-dap-exception-breakpoints`
  -- link: https://github.com/lucaSartore/nvim-dap-exception-breakpoints
  {
    'lucaSartore/nvim-dap-exception-breakpoints',
    dependencies = { 'mfussenegger/nvim-dap' },
    event = 'LspAttach',
    config = function()
      local set_exception_breakpoints = require 'nvim-dap-exception-breakpoints'
      vim.api.nvim_set_keymap('n', '<leader>dE', '', { desc = '[D]ebug [C]ondition breakpoints', callback = set_exception_breakpoints })
    end,
  },
}
