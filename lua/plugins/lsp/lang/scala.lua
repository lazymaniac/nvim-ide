return {
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { 'scala' })
    end,
  },

  -- [nvim-metals] - Scala metals tools.
  -- see: `:h nvim-metals`
  -- link: https://github.com/scalameta/nvim-metals
  {
    'scalameta/nvim-metals',
    branch = 'main',
    dependencies = { 'nvim-lua/plenary.nvim', 'mfussenegger/nvim-dap' },
    ft = { 'scala', 'sbt' },
    init = function()
      local metals_config = require('metals').bare_config()
      metals_config.init_options.statusBarProvider = 'on'
      metals_config.settings = {
        showImplicitArguments = true,
        excludedPackages = { 'akka.actor.typed.javadsl', 'com.github.swagger.akka.javadsl' },
      }
      metals_config.capabilities = require('blink.cmp').get_lsp_capabilities(metals_config.capabilities)
      metals_config.on_attach = function(client, bufnr)
        require('metals').setup_dap()
      end
      local nvim_metals_group = vim.api.nvim_create_augroup('nvim-metals', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        -- NOTE: You may or may not want java included here. You will need it if you
        -- want basic Java support but it may also conflict if you are using
        -- something like nvim-jdtls which also works on a java filetype autocmd.
        pattern = { 'scala', 'sbt' },
        callback = function()
          require('metals').initialize_or_attach(metals_config)
        end,
        group = nvim_metals_group,
      })
      -- Debug settings
      local dap = require 'dap'
      dap.configurations.scala = {
        {
          type = 'scala',
          request = 'launch',
          name = 'RunOrTest',
          metals = {
            runType = 'runOrTestFile',
            --args = { "firstArg", "secondArg", "thirdArg" }, -- here just as an example
          },
        },
        {
          type = 'scala',
          request = 'launch',
          name = 'Test Target',
          metals = {
            runType = 'testTarget',
          },
        },
      }
    end,
  },
}
