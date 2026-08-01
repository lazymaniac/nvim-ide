return {

  {
    'mfussenegger/nvim-dap',
    opts = {
      setup = {
        kotlin_debug_adapter = function()
          local dap = require 'dap'
          local markers = {
            'settings.gradle', 'settings.gradle.kts', 'build.gradle', 'build.gradle.kts',
            'gradlew', 'mvnw', 'pom.xml', '.git',
          }
          local function project_root()
            return require('nv_ide.project').root(0, markers)
          end

          dap.adapters.kotlin = {
            type = 'executable',
            command = 'kotlin-debug-adapter',
            args = { '--interpreter=vscode' },
          }

          -- Configuration
          dap.configurations.kotlin = {
            {
              type = 'kotlin',
              name = 'launch - kotlin',
              request = 'launch',
              projectRoot = project_root,
              mainClass = function()
                return vim.fn.input('Path to main class > ', '', 'file')
              end,
            },
            {
              type = 'kotlin',
              name = 'attach - kotlin',
              request = 'attach',
              projectRoot = project_root,
              hostName = function() return vim.fn.input('Kotlin debug host: ', 'localhost') end,
              port = function() return tonumber(vim.fn.input('Kotlin debug port: ', '5005')) end,
              timeout = 1000,
            },
          }
        end,
      },
    },
  },
}
