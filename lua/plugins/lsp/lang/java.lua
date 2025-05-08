local Util = require 'util'

local java_filetypes = { 'java' }
local root_markers = { 'gradlew', 'mvnw', 'gradle', 'mvn', '.git' }

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
    configuration = {
      detectJdksAtStart = true,
      checkProjectSettingsExclusions = true,
      workspaceCacheLimit = 90,
      maven = {
        notCoveredPluginExecutionSeverity = 'warning',
        defaultMojoExecutionAction = 'ignore',
      },
      runtimes = {
        {
          name = 'JavaSE-11',
          path = '~/.asdf/installs/java/temurin-11.0.27+6/',
        },
        {
          name = 'JavaSE-17',
          path = '~/.asdf/installs/java/temurin-17.0.15+6/',
        },
        {
          name = 'JavaSE-21',
          path = '~/.asdf/installs/java/temurin-21.0.7+6.0.LTS/',
          default = true,
        },
        {
          name = 'JavaSE-24',
          path = '~/.asdf/installs/java/temurin-24.0.1+9/',
        },
      },
      updateBuildConfiguration = 'interactive',
    },
    jdt = {
      ls = {
        vmargs = '-javaagent:/home/seba/.local/share/nvim/mason/packages/jdtls/lombok.jar -XX:+UseParallelGC -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -Dsun.zip.disableMemoryMapping=true -Xmx4G -Xms100m -Xlog:enable',
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
    server = {
      launchMode = 'Hybrid',
    },
    compile = {
      nullAnalysis = {
        mode = 'interactive',
        nonnull = { 'javax.annotation.Nonnull', 'org.eclipse.jdt.annotation.NonNull', 'org.springframework.lang.NonNull' },
        nonnullbydefault = {
          'javax.annotation.ParametersAreNonnullByDefault',
          'org.eclipse.jdt.annotation.NonNullByDefault',
          'org.springframework.lang.NonNullApi',
        },
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
      lazyLoad = false,
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
      actions = { 'renameFileToType' },
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
        avoidVolatileChanges = false,
      },
    },
    completion = {
      enabled = true,
      chain = {
        enabled = true,
      },
      collapseCompletionItems = true,
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
        'org.mockito.BDDMockito.*',
        'org.instancio.Instancio.*',
        'org.instancio.Select.*',
      },
      filteredTypes = { 'java.awt.*', 'com.sun.*', 'sun.*', 'jdk.*', 'org.graalvm.*', 'io.micrometer.shaded.*' },
      guessMethodArguments = 'auto',
      importOrder = { '', 'javax', 'java', '#' },
      matchCase = 'firstLetter',
      maxResults = 100,
      postfix = {
        enabled = true,
      },
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
        url = '~/.config/nvim/java-formatter.xml',
      },
    },
    implementationsCodeLens = {
      enabled = true,
    },
    import = {
      project_selection = 'automatic',
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
    maven = {
      downloadSources = true,
      updateSnapshots = false,
    },
    maxConcurrentBuilds = 1,
    project = {
      importHint = true,
      importOnFirstTimeStartup = 'automatic',
      encoding = 'ignore',
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
      validateAllOpenBuffersOnChanges = true,
      smartSemicolonDetection = {
        enabled = true,
      },
    },
  },
}

return {

  {
    'mason-org/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'clang-format', 'trivy', 'sonarlint-language-server', 'xmlformatter' })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'java', 'xml', 'yaml', 'properties' })
    end,
  },

  -- [sonarlint.nvim] - Sonarlint LSP
  -- see: `:h sonarlint.nvim`
  -- link: https://gitlab.com/schrieveslaach/sonarlint.nvim
  {
    'https://gitlab.com/schrieveslaach/sonarlint.nvim',
    enabled = false,
    ft = { 'java' },
    config = function()
      require('sonarlint').setup {
        server = {
          cmd = {
            'sonarlint-language-server',
            '-stdio',
            '-analyzers',
            vim.fn.expand '$MASON/share/sonarlint-analyzers/sonarjava.jar',
          },
        },
        filetypes = {
          'java',
        },
      }
    end,
  },

  {
    'neovim/nvim-lspconfig',
    opts = {
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

  -- [nvim-jdtls] - Java LSP extension for Nvim.
  -- see: `:h nvim-jdtls`
  -- link: https://github.com/mfussenegger/nvim-jdtls
  {
    'mfussenegger/nvim-jdtls',
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
          local jdtls_dir = vim.fn.expand("$MASON/share/jdtls")
          local lombok_path = jdtls_dir .. '/lombok.jar'
          local lombok_agent_param = '--jvm-arg=-javaagent:' .. lombok_path
          local xmx_param = '--jvm-arg=-Xmx4g'
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
    config = function(_, opts)
      -- local opts = Util.opts 'nvim-jdtls' or {}
      -- Find the extra bundles that should be passed on the jdtls command-line
      -- if nvim-dap is enabled with java debug/test.
      local mason_registry = require 'mason-registry'
      local bundles = {} ---@type string[]
      if opts.dap and Util.has 'nvim-dap' and mason_registry.is_installed 'java-debug-adapter' then
        local java_dbg_path = vim.fn.expand("$MASON/share/java-debug-adapter")
        local jar_patterns = {
          java_dbg_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar',
        }
        if mason_registry.is_installed 'vscode-java-decompiler' then
          local java_decompiler_path = vim.fn.expand("$MASON/share/vscode-java-decompiler")
          vim.list_extend(jar_patterns, {
            java_decompiler_path .. '/server/*.jar',
          })
        end
        -- java-test also depends on java-debug-adapter.
        if opts.test and mason_registry.is_installed 'java-test' then
          local java_test_path = vim.fn.expand("$MASON/share/java-test")
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
        local capabilities = require('blink.cmp').get_lsp_capabilities {}
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
          capabilities = capabilities,
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
            wk.add {
              { '<leader>c', name = '+[code]' },
              { '<leader>cx', group = '+[extract]' },
              { '<leader>cxv', require('jdtls').extract_variable_all, desc = 'Extract Variable [cxv]', mode = 'n', buffer = args.buf },
              { '<leader>cxc', require('jdtls').extract_constant, desc = 'Extract Constant [cxc]', mode = 'n', buffer = args.buf },
              { '<leader>cg', group = '+[goto]' },
              { '<leader>cgs', require('jdtls').super_implementation, desc = 'Goto Super [cgs]', mode = 'n', buffer = args.buf },
              { '<leader>cgt', require('jdtls.tests').goto_subjects, desc = 'Goto Test Class [cgt]', mode = 'n', buffer = args.buf },
              { '<leader>ct', require('jdtls.tests').generate, desc = 'Generate Test Class [ct]', mode = 'n', buffer = args.buf },
              { '<leader>cz', require('jdtls').organize_imports, desc = 'Organize Imports [cz]', mode = 'n', buffer = args.buf },
              { '<leader>cc', require('jdtls').compile, desc = 'Compile Code [cc]', mode = 'n', buffer = args.buf },
              { '<leader>cb', require('jdtls').build_projects, desc = 'Build Projects [cb]', mode = 'n', buffer = args.buf },
              { '<leader>cu', require('jdtls').update_projects_config, desc = 'Update Projects Config [cu]', mode = 'n', buffer = args.buf },
              { '<leader>cp', require('jdtls').javap, desc = 'Run javap [cp]', mode = 'n', buffer = args.buf },
              { '<leader>cj', require('jdtls').jshell, desc = 'Run jshell [cj]', mode = 'n', buffer = args.buf },
              { '<leader>cl', require('jdtls').jol, desc = 'Run jol [cl]', mode = 'n', buffer = args.buf },
              { '<leader>ce', require('jdtls').set_runtime, desc = 'Set Runtime [ce]', mode = 'n', buffer = args.buf },
              { '<leader>cxm', [[<ESC><CMD>lua require('jdtls').extract_method(true)<CR>]], desc = 'Extract Method [cxm]', mode = 'v', buffer = args.buf },
              {
                '<leader>cxv',
                [[<ESC><CMD>lua require('jdtls').extract_variable_all(true)<CR>]],
                desc = 'Extract Variable [cxv]',
                mode = 'v',
                buffer = args.buf,
              },
              { '<leader>cxc', [[<ESC><CMD>lua require('jdtls').extract_constant(true)<CR>]], desc = 'Extract Constant [cxc]', mode = 'v', buffer = args.buf },
            }
            if opts.dap and Util.has 'nvim-dap' and mason_registry.is_installed 'java-debug-adapter' then
              -- custom init for Java debugger
              require('jdtls').setup_dap(opts.dap)
              require('jdtls.dap').setup_dap_main_class_configs()
              -- Java Test require Java debugger to work
              if opts.test and mason_registry.is_installed 'java-test' then
                -- custom keymaps for Java test runner (not yet compatible with neotest)
                wk.add {
                  { '<leader>d', group = '+[debug]' },
                  { '<leader>dT', require('jdtls.dap').test_class, desc = 'Debug Test Class [tt]', mode = 'n', buffer = args.buf },
                  { '<leader>dt', require('jdtls.dap').test_nearest_method, desc = 'Debug Nearest Test Method [tr]', mode = 'n', buffer = args.buf },
                  { '<leader>dP', require('jdtls.dap').pick_test, desc = 'Pick Test and Debug [tp]', mode = 'n', buffer = args.buf },
                  { '<leader>dM', require('jdtls.dap').fetch_main_configs, desc = 'Fetch Main Class [dM]', mode = 'n', buffer = args.buf },
                }
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

  {
    'mfussenegger/nvim-dap',
    dependencies = {
      {
        'mason-org/mason.nvim',
        opts = function(_, opts)
          opts.registries = {
            'github:mason-org/mason-registry',
          }
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { 'jdtls', 'java-test', 'java-debug-adapter' })
        end,
      },
    },
  },

  {
    'nvim-neotest/neotest',
    dependencies = { 'rcasia/neotest-java' },
  },
}
