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

local jdtls_settings = {
  redhat = {
    telemetry = {
      enabled = false,
    },
  },
  java = {
    server = {
      launchMode = 'Standard',
    },
    compile = {
      nullAnalysis = {
        mode = 'automatic',
        nonnull = { 'javax.annotation.Nonnull', 'org.eclipse.jdt.annotation.NonNull', 'org.springframework.lang.NonNull' },
        nullable = { 'javax.annotation.Nullable', 'org.eclipse.jdt.annotation.Nullable', 'org.springframework.lang.Nullable' },
      },
    },
    imports = {
      gradle = {
        annotationProcessing = {
          enabled = true,
        },
        enabled = true,
        offline = {
          enabled = false,
        },
        wrapper = {
          enabled = true,
        },
      },
    },
    refactoring = {
      extract = {
        interface = {
          replace = true,
        },
      },
    },
    sharedIndexes = {
      enabled = 'auto',
    },
    typeHierarchy = {
      lazyLoad = true,
    },
    progressReports = {
      enabled = true,
    },
    recommendations = {
      dependency = {
        analytics = {
          show = true,
        },
      },
    },
    showBuildStatusOnStart = {
      enabled = 'notification',
    },
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
      insertionLocation = 'afterCursor',
      generateComments = false,
      hashCodeEquals = {
        useInstanceof = true,
        useJava7Objects = true,
      },
      toString = {
        codeStyle = 'STRING_BUILDER_CHAINED', -- "STRING_CONCATENATION" | "STRING_BUILDER" | "STRING_BUILDER_CHAINED" | "STRING_FORMAT"
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
      lazyResolveTextEdit = {
        enabled = true,
      },
      favoriteStaticMembers = {
        'org.hamcrest.MatcherAssert.assertThat',
        'org.hamcrest.Matchers.*',
        'org.hamcrest.CoreMatchers.*',
        'org.junit.jupiter.api.Assertions.*',
        'java.util.Objects.requireNonNull',
        'java.util.Objects.requireNonNullElse',
        'org.mockito.Mockito.*',
      },
      filteredTypes = { 'java.awt.*', 'com.sun.*', 'sun.*', 'jdk.*', 'org.graalvm.*', 'io.micrometer.shaded.*' },
      guessMethodArguments = 'auto',
      importOrder = { '#', 'java', 'javax', 'org', 'com', '' },
      matchCase = 'firstLetter',
      maxResults = 50,
      postfix = {
        enabled = true,
      },
    },
    configuration = {
      checkProjectSettingsExclusions = true,
      workspaceCacheLimit = 90,
      maven = {
        notCoveredPluginExecutionSeverity = 'warning',
        defaultMojoExecutionAction = 'ignore',
      },
      runtimes = {
        {
          name = 'JavaSE-1.8',
          path = '~/.sdkman/candidates/java/8.0.402-tem/',
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
        {
          name = 'JavaSE-21',
          path = '~/.sdkman/candidates/java/21.0.1-tem/',
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
    foldingRange = {
      enabled = true,
    },
    format = {
      comments = {
        enabled = true,
      },
      enabled = true,
      onType = {
        enabled = true,
      },
      settings = {
        profile = 'Default',
        url = '~/.config/nvim/java-formatter.xml',
      },
    },
    implementationsCodeLens = {
      enabled = true,
    },
    import = {
      generatesMetadataFilesAtProjectRoot = false,
      exclusions = {
        '**/node_modules/**',
        '**/.metadata/**',
        '**/archetype-resources/**',
        '**/META-INF/maven/**',
      },
      gradle = {
        wrapper = {
          enabled = true,
        },
        annotationProcessing = {
          enabled = true,
        },
        enabled = true,
        offline = {
          enabled = false,
        },
      },
      maven = {
        defaultMojoExecutionAction = 'warn',
        notCoveredPluginExecutionSeverity = 'warning',
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
        vmargs = '-XX:+UseParallelGC -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Dsun.zip.disableMemoryMapping=true -Xmx3G -Xms100m -Xlog:disable',
        protobufSupport = {
          enabled = true,
        },
        androidSupport = {
          enabled = 'auto',
        },
        lombokSupport = {
          enabled = true,
        },
      },
    },
    maven = {
      downloadSources = true,
      updateSnapshots = false,
    },
    maxConcurrentBuilds = 1,
    project = {
      importHint = true,
      importOnFirstTimeStartup = 'automatic',
      encoding = 'setDefault',
      referencedLibraries = { 'lib/**/*.jar' },
      resourceFilters = { 'node_modules', '\\.git' },
      sourcePaths = {},
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
    saveActions = {
      organizeImports = false,
    },
    selectionRange = {
      enabled = true,
    },
    signatureHelp = {
      enabled = true,
      description = {
        enabled = true,
      },
    },
    sources = {
      organizeImports = {
        starThreshold = 99,
        staticStarThreshold = 99,
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
      validateAllOpenBuffersOnChanges = false,
    },
  },
}

return {

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'clang-format', 'google-java-format', 'checkstyle', 'trivy' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'java', 'xml', 'yaml', 'properties' })
    end,
  },

  {
    'mfussenegger/nvim-lint',
    opts = {
      linters_by_ft = {
        java = { 'checkstyle', 'trivy' },
      },
    },
  },

  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        java = { 'clang-format', 'google-java-format' },
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
    'mfussenegger/nvim-jdtls',
    enabled = true,
    version = false,
    branch = 'master',
    ft = java_filetypes,
    dependencies = { 'folke/which-key.nvim' },
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
          local xmx_param = '--jvm-arg=-Xmx8g'
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
          settings = jdtls_settings,
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
              ['<leader>cx'] = { name = '+[extract]' },
              ['<leader>cxv'] = { require('jdtls').extract_variable_all, 'Extract Variable (Java)' },
              ['<leader>cxc'] = { require('jdtls').extract_constant, 'Extract Constant (Java)' },
              ['<leader>cg'] = { name = '+[goto]' },
              ['<leader>cgs'] = { require('jdtls').super_implementation, 'Goto Super (Java)' },
              ['<leader>cgS'] = { require('jdtls.tests').goto_subjects, 'Goto Subjects (Java)' },
              ['<leader>ct'] = { require('jdtls.tests').generate, 'Generate Test Class (Java)' },
              ['<leader>ci'] = { require('jdtls').organize_imports, 'Organize Imports (Java)' },
              ['<leader>cc'] = { require('jdtls').compile, 'Compile Code (Java)' },
              ['<leader>cb'] = { require('jdtls').build_projects, 'Build Projects (Java)' },
              ['<leader>cu'] = { require('jdtls').update_projects_config, 'Update Projects Config (Java)' },
              ['<leader>cp'] = { require('jdtls').javap, 'Run javap (Java)' },
              ['<leader>cj'] = { require('jdtls').jshell, 'Run jshell (Java)' },
              ['<leader>cl'] = { require('jdtls').jol, 'Run jol (Java)' },
              ['<leader>ce'] = { require('jdtls').set_runtime, 'Set Runtime (Java)' },
            }, { mode = 'n', buffer = args.buf })
            wk.register({
              ['<leader>c'] = { name = '+[code]' },
              ['<leader>cx'] = { name = '+[extract]' },
              ['<leader>cxm'] = {
                [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]],
                'Extract Method (Java)',
              },
              ['<leader>cxv'] = {
                [[<ESC><CMD>lua require('jdtls').extract_variable_all(true)<CR>]],
                'Extract Variable (Java)',
              },
              ['<leader>cxc'] = {
                [[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]],
                'Extract Constant (Java)',
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
                  ['<leader>t'] = { name = '+[test]' },
                  ['<leader>tt'] = { require('jdtls.dap').test_class, 'Test Class (Java)' },
                  ['<leader>tr'] = { require('jdtls.dap').test_nearest_method, 'Test Nearest Method (Java)' },
                  ['<leader>tp'] = { require('jdtls.dap').pick_test, 'Pick Test (Java)' },
                  ['<leader>dm'] = { require('jdtls.dap').fetch_main_configs, 'Fetch Main Class (Java)' },
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

  -- Ensure java debugger and test packages are installed.
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
          vim.list_extend(opts.ensure_installed, { 'jdtls', 'java-test', 'java-debug-adapter' })
        end,
      },
    },
  },

  -- Setup neotest
  {
    'nvim-neotest/neotest',
    dependencies = {
      'rcasia/neotest-java',
    },
  },
}
