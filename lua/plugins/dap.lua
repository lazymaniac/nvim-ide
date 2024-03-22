---@param config {args?:string[]|fun():string[]?}
local function get_args(config)
  local args = type(config.args) == 'function' and (config.args() or {}) or config.args or {}
  config = vim.deepcopy(config)
  ---@cast args string[]
  config.args = function()
    local new_args = vim.fn.input('Run with args: ', table.concat(args, ' ')) --[[@as string]]
    return vim.split(vim.fn.expand(new_args) --[[@as string]], ' ')
  end
  return config
end

return {

  -- [[ DEBUG ]] ---------------------------------------------------------------

  -- [nvim-dap] - Debug in neovim
  -- see: `:h nvim-dap`
  {
    'mfussenegger/nvim-dap',
    event = 'VeryLazy',
    dependencies = {
      'rcarriga/nvim-dap-ui',
      'theHamsta/nvim-dap-virtual-text',
      'jay-babu/mason-nvim-dap.nvim',
      'stevearc/overseer.nvim',
      'LiadOz/nvim-dap-repl-highlights',
    },
    -- stylua: ignore
    keys = {
      { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'Breakpoint Condition [dB]' },
      { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = 'Toggle Breakpoint [db]' },
      { '<leader>dc', function() require('dap').continue() end, desc = 'Continue [dc]' },
      { '<leader>da', function() require('dap').continue { before = get_args } end, desc = 'Run with Args [da]' },
      { '<leader>dC', function() require('dap').run_to_cursor() end, desc = 'Run to Cursor [dC]' },
      { '<leader>dg', function() require('dap').goto_() end, desc = 'Go to line (no execute) [dg]' },
      { '<leader>di', function() require('dap').step_into() end, desc = 'Step Into [di]' },
      { '<leader>dj', function() require('dap').down() end, desc = 'Down [dj]' },
      { '<leader>dk', function() require('dap').up() end, desc = 'Up [dk]' },
      { '<leader>dl', function() require('dap').run_last() end, desc = 'Run Last [dl]' },
      { '<leader>dO', function() require('dap').step_out() end, desc = 'Step Out [do]' },
      { '<leader>do', function() require('dap').step_over() end, desc = 'Step Over [dO]' },
      { '<leader>dp', function() require('dap').pause() end, desc = 'Pause [dp]' },
      { '<leader>dr', function() require('dap').repl.toggle() end, desc = 'Toggle REPL [dr]' },
      { '<leader>ds', function() require('dap').session() end, desc = 'Session [ds]' },
      { '<leader>dt', function() require('dap').terminate() end, desc = 'Terminate [dt]' },
      { '<leader>dw', function() require('dap.ui.widgets').hover() end, desc = 'Widgets [dw]' },
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
      local Config = require 'config'
      vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, link = 'Visual' })
      for name, sign in pairs(Config.icons.dap) do
        sign = type(sign) == 'table' and sign or { sign }
        vim.fn.sign_define('Dap' .. name, { text = sign[1], texthl = sign[2] or 'DiagnosticInfo', linehl = sign[3], numhl = sign[3] })
      end
    end,
  },

  -- [nvim-dap-ui] - Creates UI setup for debug sessions
  -- see: `:h nvim-dap-ui`
  {
    'rcarriga/nvim-dap-ui',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      { '<leader>du', function() require('dapui').toggle {} end, desc = 'Dap UI [du]' },
      { '<leader>de', function() require('dapui').eval() end, desc = 'Eval [de]', mode = { 'n', 'v' } },
      { '<leader>df', function() require('dapui').float_element(nil, { width = 184, height = 44, enter = true, position = 'center' }) end, desc = 'Open floating DAP [df]' },
    },
    config = function()
      -- setup dap config by VsCode launch.json file
      -- require("dap.ext.vscode").load_launchjs()
      local dap = require 'dap'
      local dapui = require 'dapui'
      dapui.setup {
        controls = {
          element = 'repl',
          enabled = true,
          icons = {
            disconnect = '',
            pause = '',
            play = '',
            run_last = '',
            step_back = '',
            step_into = '',
            step_out = '',
            step_over = '',
            terminate = '',
          },
        },
        element_mappings = {},
        expand_lines = true,
        floating = {
          border = 'single',
          mappings = {
            close = { 'q', '<Esc>' },
          },
        },
        force_buffers = true,
        icons = {
          collapsed = '',
          current_frame = '',
          expanded = '',
        },
        layouts = {
          {
            elements = {
              { id = 'console', size = 0.65 },
              { id = 'repl', size = 0.35 },
            },
            position = 'bottom',
            size = 12,
          },
          {
            elements = {
              { id = 'scopes', size = 0.4 },
              { id = 'breakpoints', size = 0.2 },
              { id = 'stacks', size = 0.2 },
              { id = 'watches', size = 0.2 },
            },
            position = 'right',
            size = 40,
          },
        },
        mappings = {
          edit = 'e',
          expand = { '<CR>', '<2-LeftMouse>' },
          open = 'o',
          remove = 'd',
          repl = 'r',
          toggle = 't',
        },
        render = {
          indent = 2,
          max_value_lines = 100,
        },
      }
      dap.listeners.after.event_initialized['dapui_config'] = function()
        dapui.open {}
      end
    end,
  },

  -- [nvim-dap-virtual-text] - Virtual text for debbug session
  -- see: `:h nvim-dap-virtual-text`
  {
    'theHamsta/nvim-dap-virtual-text',
    event = 'VeryLazy',
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
  {
    'jay-babu/mason-nvim-dap.nvim',
    event = 'VeryLazy',
    dependencies = { 'williamboman/mason.nvim' },
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

  -- [nvim-dap-repl-highlights] - Highlights for repl window
  -- see: `:h nvim-dap-repl-highlights`
  {
    'LiadOz/nvim-dap-repl-highlights',
    event = 'VeryLazy',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      require('nvim-dap-repl-highlights').setup()
    end,
  },
}
