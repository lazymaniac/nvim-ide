return {
  {
    'nvim-neotest/neotest',
    dependencies = {
      { 'nvim-neotest/neotest-python' },
      { 'thenbe/neotest-playwright' },
    },
    opts = {
      adapters = {
        ['neotest-python'] = {
          runner = 'pytest',
          python = '.venv/bin/python',
        },
        ['neotest-playwright'] = {
          options = {
            persist_project_selection = true,
            enable_dynamic_test_discovery = true,
          },
        },
      },
    },
  },

  {
    'mfussenegger/nvim-dap',
    dependencies = {
      'mfussenegger/nvim-dap-python',
      -- stylua: ignore
      keys = {
        { "<leader>dM", function() require('dap-python').test_method() end, desc = "Debug Method [dM]", ft = "python" },
        { "<leader>dS", function() require('dap-python').test_class() end,  desc = "Debug Class [dS]",  ft = "python" },
      },
      config = function()
        require('dap-python').setup '.venv/bin/python'
      end,
    },
  },

  -- [venv-selector.nvim] - Python Virtual Env selector.
  -- see: `:h venv-selector.nvim`
  -- link: https://github.com/linux-cultist/venv-selector.nvim
  {
    'linux-cultist/venv-selector.nvim',
    branch = 'regexp',
    cmd = 'VenvSelect',
    ft = { "python" },
    keys = { { '<leader>cv', '<cmd>:VenvSelect<cr>', desc = 'Select VirtualEnv [cv]' } },
    opts = {
      settings = {
        options = {
          notify_user_on_venv_activation = true,
        },
      },
    },
  },

}
