local Util = require 'util'

-- This is the same as in lspconfig.server_configurations.jdtls, but avoids
-- needing to require that when this module loads.
local java_filetypes = { 'java' }
local root_markers = { 'gradlew', '.git', 'mvnw' }

-- Utility function to extend or override a config table, similar to the way
-- that Plugin.opts works.
---@param config table
---@param custom function | table | nil
local function extend_or_override(config, custom, ...)
  if type(custom) == 'function' then
    config = custom(config, ...) or config
  elseif custom then
    config = vim.tbl_deep_extend('force', config, custom) --[[@as table]]
  end
  return config
end

return {

  -- [[ JAVA ]] - LSP, DAP, TEST SETUP
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      {
        'williamboman/mason.nvim',
        opts = function(_, opts)
          opts.registries = {
            'github:nvim-java/mason-registry',
            'github:mason-org/mason-registry',
          }
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { 'java-test', 'java-debug-adapter' })
        end,
      },
    },
  },

  -- Configure nvim-lspconfig to install the server automatically via mason, but
  -- defer actually starting it to our configuration of nvim-jtdls below.
  {
    'neovim/nvim-lspconfig',
    opts = {
      -- make sure mason installs the server
      servers = {
        jdtls = {},
      },
      setup = {
        jdtls = function()
          return true -- avoid duplicate servers
        end,
      },
    },
  },
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'java' })
    end,
  },
  {
    'mfussenegger/nvim-jdtls',
    opts = function()
      return {
        -- How to find the root dir for a given filename. The default comes from
        -- lspconfig which provides a function specifically for java projects.
        root_dir = require('jdtls.setup').find_root,

        -- How to find the project name for a given root dir.
        project_name = function(root_dir)
          return root_dir and vim.fs.basename(root_dir)
        end,

        -- Where are the config and workspace dirs for a project?
        jdtls_config_dir = function(project_name)
          return vim.fn.stdpath 'cache' .. '/jdtls/' .. project_name .. '/config'
        end,
        jdtls_workspace_dir = function(project_name)
          return vim.fn.stdpath 'cache' .. '/jdtls/' .. project_name .. '/workspace'
        end,

        -- How to run jdtls. This can be overridden to a full java command-line
        -- if the Python wrapper script doesn't suffice.
        cmd = { 'jdtls' },
        full_cmd = function(opts)
          local root_dir = opts.root_dir(root_markers)
          local mason_registry = require 'mason-registry'
          local jdtls_dir = mason_registry.get_package('jdtls'):get_install_path()
          local lombok_path = jdtls_dir .. '/lombok.jar'
          local lombok_agent_param = '--jvm-arg=-javaagent:' .. lombok_path
          local xmx_param = '--jvm-arg=-Xmx6g'
          local project_name = opts.project_name(root_dir)
          local cmd = vim.deepcopy(opts.cmd)
          if project_name then
            vim.list_extend(cmd, {
              xmx_param,
              lombok_agent_param,
              '-configuration',
              opts.jdtls_config_dir(project_name),
              '-data',
              opts.jdtls_workspace_dir(project_name),
            })
          end
          return cmd
        end,

        -- These depend on nvim-dap, but can additionally be disabled by setting false here.
        dap = { hotcodereplace = 'auto', config_overrides = {} },
        test = true,
      }
    end,
    config = function()
      local opts = Util.opts 'nvim-jdtls' or {}

      -- Find the extra bundles that should be passed on the jdtls command-line
      -- if nvim-dap is enabled with java debug/test.
      local mason_registry = require 'mason-registry'
      local bundles = {} ---@type string[]
      if opts.dap and Util.has 'nvim-dap' and mason_registry.is_installed 'java-debug-adapter' then
        local java_dbg_pkg = mason_registry.get_package 'java-debug-adapter'
        local java_dbg_path = java_dbg_pkg:get_install_path()
        local jar_patterns = {
          java_dbg_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar',
        }

        if mason_registry.is_installed 'vscode-java-decompiler' then
          local java_decompiler_pkg = mason_registry.get_package 'vscode-java-decompiler'
          local java_decompiler_path = java_decompiler_pkg:get_install_path()
          vim.list_extend(jar_patterns, {
            java_decompiler_path .. '/server/*.jar',
          })
        end

        -- java-test also depends on java-debug-adapter.
        if opts.test and mason_registry.is_installed 'java-test' then
          local java_test_pkg = mason_registry.get_package 'java-test'
          local java_test_path = java_test_pkg:get_install_path()
          vim.list_extend(jar_patterns, {
            java_test_path .. '/extension/server/*.jar',
          })
        end
        for _, jar_pattern in ipairs(jar_patterns) do
          for _, bundle in ipairs(vim.split(vim.fn.glob(jar_pattern), '\n')) do
            table.insert(bundles, bundle)
          end
        end
      end

      local function attach_jdtls()
        local extendedClientCapabilities = require('jdtls').extendedClientCapabilities
        extendedClientCapabilities.resolveAdditionalTextEditsSupport = true
        local capabilities = require('cmp_nvim_lsp').default_capabilities()
        capabilities.workspace = {
          configuration = true,
        }

        -- Configuration can be augmented and overridden by opts.jdtls
        local config = extend_or_override({
          cmd = opts.full_cmd(opts),
          root_dir = opts.root_dir(root_markers),
          init_options = {
            bundles = bundles,
            extendedClientCapabilities = extendedClientCapabilities,
          },
          flags = {
            allow_incremental_sync = true,
          },
          settings = {
            java = {
              autobuild = {
                enabled = true,
              },
              cleanup = {
                actionsOnSave = {
                  -- "qualifyMembers",
                  -- "qualifyStaticMembers",
                  'addOverride',
                  'addDeprecated',
                  'stringConcatToTextBlock',
                  'invertEquals',
                  -- "addFinalModifier",
                  'instanceofPatternMatch',
                  'lambdaExpression',
                  'switchExpression',
                },
              },
              codeGeneration = {
                generateComments = false,
                hashCodeEquals = {
                  useInstanceof = false,
                  useJava7Objects = false,
                },
                toString = {
                  codeStyle = 'STRING_FORMAT',
                  limitElements = 0,
                  listArrayContents = true,
                  skipNullValues = false,
                  template = '${object.className} [${member.name()}=${member.value}, ${otherMembers}]',
                },
                useBlocks = true,
              },
              codeAction = {
                sortMembers = {
                  avoidVolatileChanges = true,
                },
              },
              completion = {
                enabled = true,
                favoriteStaticMembers = {
                  'org.hamcrest.MatcherAssert.assertThat',
                  'org.hamcrest.Matchers.*',
                  'org.hamcrest.CoreMatchers.*',
                  'org.junit.jupiter.api.Assertions.*',
                  'java.util.Objects.requireNonNull',
                  'java.util.Objects.requireNonNullElse',
                  'org.mockito.Mockito.*',
                },
                filteredTypes = {},
                guessMethodArguments = true,
                importOrder = { 'java', 'javax', 'org', 'com' },
                matchCase = 'firstletter',
                maxResults = 50,
                overwrite = true,
                postfix = true,
              },
              configuration = {
                maven = {
                  -- userSettings = "",
                  -- globalSettings = "",
                  notCoveredPluginExecutionSeverity = 'warning',
                },
                runtimes = {
                  {
                    name = 'JavaSE-1.8',
                    path = '~/.sdkman/candidates/java/8.0.392-tem/',
                  },
                  {
                    name = 'JavaSE-11',
                    path = '~/.sdkman/candidates/java/11.0.21-tem/',
                  },
                  {
                    name = 'JavaSE-17',
                    path = '~/.sdkman/candidates/java/17.0.9-tem/',
                    default = true,
                  },
                },
                updateBuildConfiguration = 'automatic',
              },
              contentProvider = { preferred = 'fernflower' },
              eclipse = {
                downloadSources = true,
              },
              errors = {
                incompleteClasspath = {
                  severity = 'warning',
                },
              },
              executeCommand = {
                enabled = true,
              },
              foldingRange = {
                enabled = true,
              },
              format = {
                comments = {
                  enabled = true,
                },
                enabled = true,
                insertSpaces = true,
                onType = {
                  enabled = true,
                },
                settings = {
                  profile = 'Default',
                  url = '~/.config/nvim/java-formatter.xml',
                },
                tabSize = 4,
              },
              implementationsCodeLens = {
                enabled = true,
              },
              import = {
                exclusions = {
                  '**/node_modules/**',
                  '**/.metadata/**',
                  '**/archetype-resources/**',
                  '**/META-INF/maven/**',
                },
                gradle = {
                  annotationProcessing = {
                    enabled = true,
                  },
                  arguments = {},
                  enabled = true,
                  -- home = "",
                  -- java = {},
                  jvmArguments = {},
                  offline = {
                    enabled = false,
                  },
                  -- user = {},
                  -- version = "",
                  -- wrapper = {},
                },
                maven = {
                  enabled = true,
                  offline = {
                    enabled = false,
                  },
                },
              },
              inlayHints = {
                parameterNames = {
                  enabled = 'all', -- literals, all, none
                  exclusions = {},
                },
              },
              jdt = {
                ls = {
                  androidSupport = true,
                  lombokSupport = true,
                  protofBufSupport = true,
                },
              },
              maven = {
                downloadSources = true,
                updateSnapshots = false,
              },
              maxConcurrentBuilds = 1,
              -- memberSortOrder = "SF,F,",
              project = {
                encoding = 'IGNORE',
                outputPath = '',
                referencedLibraries = 'lib/**',
                resourceFilters = { 'node_modules', '\\.git' },
                sourcePaths = '',
              },
              quickfix = {
                showAt = 'line',
              },
              referencesCodeLens = {
                enabled = true,
              },
              references = {
                includeAccessors = true,
                includeDecompiledSources = true,
              },
              rename = {
                enabled = true,
              },
              saveActions = {
                organizeImports = true,
              },
              selectionRange = {
                enabled = true,
              },
              -- settings = {
              --   url = "",
              -- },
              signatureHelp = {
                enabled = true,
                description = true,
              },
              sources = {
                organizeImports = {
                  starThreshold = 9999,
                  staticStarThreshold = 9999,
                },
              },
              symbols = {
                includeSourceMethodDeclarations = true,
              },
              templates = {
                fileHeader = {},
                typeComment = {},
              },
              trace = {
                server = 'off',
              },
              edit = {
                validateAllOpenBuffersOnChanges = true,
              },
            },
            -- enable CMP capabilities
            capabilities = capabilities,
          },
        }, opts.jdtls)

        -- Existing server will be reused if the root_dir matches.
        require('jdtls').start_or_attach(config)
        -- not need to require("jdtls.setup").add_commands(), start automatically adds commands
      end

      -- Attach the jdtls for each java buffer. HOWEVER, this plugin loads
      -- depending on filetype, so this autocmd doesn't run for the first file.
      -- For that, we call directly below.
      vim.api.nvim_create_autocmd('FileType', {
        pattern = java_filetypes,
        callback = attach_jdtls,
      })

      -- Setup keymap and dap after the lsp is fully attached.
      -- https://github.com/mfussenegger/nvim-jdtls#nvim-dap-configuration
      -- https://neovim.io/doc/user/lsp.html#LspAttach
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == 'jdtls' then
            local wk = require 'which-key'
            wk.register({
              ['<leader>cx'] = { name = '+extract' },
              ['<leader>cxv'] = { require('jdtls').extract_variable_all, 'Extract Variable' },
              ['<leader>cxc'] = { require('jdtls').extract_constant, 'Extract Constant' },
              ['gs'] = { require('jdtls').super_implementation, 'Goto Super' },
              ['gS'] = { require('jdtls.tests').goto_subjects, 'Goto Subjects' },
              ['<leader>co'] = { require('jdtls').organize_imports, 'Organize Imports' },
            }, { mode = 'n', buffer = args.buf })
            wk.register({
              ['<leader>c'] = { name = '+code' },
              ['<leader>cx'] = { name = '+extract' },
              ['<leader>cxm'] = {
                [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
                'Extract Method',
              },
              ['<leader>cxv'] = {
                [[<ESC><CMD>lua require('jdtls').extract_variable_all(true)<CR>]],
                'Extract Variable',
              },
              ['<leader>cxc'] = {
                [[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]],
                'Extract Constant',
              },
            }, { mode = 'v', buffer = args.buf })

            if opts.dap and Util.has 'nvim-dap' and mason_registry.is_installed 'java-debug-adapter' then
              -- custom init for Java debugger
              require('jdtls').setup_dap(opts.dap)
              require('jdtls.dap').setup_dap_main_class_configs()

              -- Java Test require Java debugger to work
              if opts.test and mason_registry.is_installed 'java-test' then
                -- custom keymaps for Java test runner (not yet compatible with neotest)
                wk.register({
                  ['<leader>t'] = { name = '+test' },
                  ['<leader>tt'] = { require('jdtls.dap').test_class, 'Run All Test' },
                  ['<leader>tr'] = { require('jdtls.dap').test_nearest_method, 'Run Nearest Test' },
                  ['<leader>tT'] = { require('jdtls.dap').pick_test, 'Run Test' },
                }, { mode = 'n', buffer = args.buf })
              end
            end
            -- User can set additional keymaps in opts.on_attach
            if opts.on_attach then
              opts.on_attach(args)
            end
          end
        end,
      })
      -- Avoid race condition by calling attach the first time, since the autocmd won't fire.
      attach_jdtls()
    end,
  },
}
