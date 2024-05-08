return {

  {
    'williamboman/mason.nvim',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { 'clang-format', 'trivy', 'sonarlint-language-server' })
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
        java = { 'trivy' },
      },
    },
  },

  -- [sonarlint.nvim] - Sonarlint LSP
  -- see: `:h sonarlint.nvim`
  {
    'https://gitlab.com/schrieveslaach/sonarlint.nvim',
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
    dependencies = {
      'nvim-java/nvim-java',
    },
    opts = {
      servers = {
        jdtls = {
          settings = {
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
                    path = '~/.sdkman/candidates/java/11.0.22-tem/',
                  },
                  {
                    name = 'JavaSE-17',
                    path = '~/.sdkman/candidates/java/17.0.10-tem/',
                    default = true,
                  },
                  {
                    name = 'JavaSE-21',
                    path = '~/.sdkman/candidates/java/21.0.2-tem/',
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
          },
        },
      },
    },
  },

  {
    'nvim-java/nvim-java',
    branch = 'main',
    dependencies = {
      'nvim-java/lua-async-await',
      'nvim-java/nvim-java-refactor',
      'nvim-java/nvim-java-core',
      'nvim-java/nvim-java-test',
      'nvim-java/nvim-java-dap',
      'MunifTanjim/nui.nvim',
      'mfussenegger/nvim-dap',
      'williamboman/mason.nvim',
    },
  },

  -- Ensure java debugger and test packages are installed.
  {
    'mfussenegger/nvim-dap',
    dependencies = {
      {
        'williamboman/mason.nvim',
        opts = function(_, opts)
          opts.ensure_installed = opts.ensure_installed or {}
          vim.list_extend(opts.ensure_installed, { 'jdtls', 'java-test', 'java-debug-adapter' })
        end,
      },
    },
  },

  -- Setup neotest
  {
    'nvim-neotest/neotest',
    dependencies = { 'rcasia/neotest-java' },
  },
}
