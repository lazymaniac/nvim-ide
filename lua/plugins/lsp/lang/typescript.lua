return {

  -- correctly setup lspconfig
  {
    'neovim/nvim-lspconfig',
    opts = {
      -- make sure mason installs the server
      servers = {
        vtsls = {
          -- explicitly add default filetypes, so that we can extend
          -- them in related extras
          filetypes = {
            'javascript',
            'javascriptreact',
            'javascript.jsx',
            'typescript',
            'typescriptreact',
            'typescript.tsx',
          },
          settings = {
            complete_function_calls = true,
            vtsls = {
              enableMoveToFileCodeAction = true,
              autoUseWorkspaceTsdk = true,
              experimental = {
                maxInlayHintLength = 30,
                completion = {
                  enableServerSideFuzzyMatch = true,
                },
              },
            },
            typescript = {
              updateImportsOnFileMove = { enabled = 'always' },
              suggest = {
                completeFunctionCalls = true,
              },
              inlayHints = {
                enumMemberValues = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                parameterNames = { enabled = 'literals' },
                parameterTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                variableTypes = { enabled = false },
              },
            },
          },
          keys = {
            {
              'gD',
              function()
                local clients = require('util').lsp.get_clients {
                  bufnr = 0,
                  filter = function(client) return client.name == 'vtsls' end,
                }
                local encoding = clients[1] and clients[1].offset_encoding or 'utf-16'
                local params = vim.lsp.util.make_position_params(0, encoding)
                require('util').lsp.execute {
                  command = 'typescript.goToSourceDefinition',
                  arguments = { params.textDocument.uri, params.position },
                  open = true,
                }
              end,
              desc = 'Goto Source Definition',
            },
            {
              'gR',
              function()
                require('util').lsp.execute {
                  command = 'typescript.findAllFileReferences',
                  arguments = { vim.uri_from_bufnr(0) },
                  open = true,
                }
              end,
              desc = 'File References',
            },
            {
              '<leader>co',
              require('util').lsp.action['source.organizeImports'],
              desc = 'Organize Imports',
            },
            {
              '<leader>cM',
              require('util').lsp.action['source.addMissingImports.ts'],
              desc = 'Add missing imports',
            },
            {
              '<leader>cu',
              require('util').lsp.action['source.removeUnused.ts'],
              desc = 'Remove unused imports',
            },
            {
              '<leader>cD',
              require('util').lsp.action['source.fixAll.ts'],
              desc = 'Fix all diagnostics',
            },
            {
              '<leader>cV',
              function()
                require('util').lsp.execute { command = 'typescript.selectTypeScriptVersion' }
              end,
              desc = 'Select TS workspace version',
            },
          },
        },
      },
      setup = {
        vtsls = function(_, opts)
          require('util').lsp.on_attach(function(client, buffer)
            client.commands['_typescript.moveToFileRefactoring'] = function(command, ctx)
              ---@type string, string, lsp.Range
              local action, uri, range = unpack(command.arguments)

              local function move(newf)
                client:request('workspace/executeCommand', {
                  command = command.command,
                  arguments = { action, uri, range, newf },
                })
              end

              local fname = vim.uri_to_fname(uri)
              client:request('workspace/executeCommand', {
                command = 'typescript.tsserverRequest',
                arguments = {
                  'getMoveToRefactoringFileSuggestions',
                  {
                    file = fname,
                    startLine = range.start.line + 1,
                    startOffset = range.start.character + 1,
                    endLine = range['end'].line + 1,
                    endOffset = range['end'].character + 1,
                  },
                },
              }, function(_, result)
                ---@type string[]
                local files = result.body.files
                table.insert(files, 1, 'Enter new path...')
                vim.ui.select(files, {
                  prompt = 'Select move destination:',
                  format_item = function(f)
                    return vim.fn.fnamemodify(f, ':~:.')
                  end,
                }, function(f)
                  if f and f:find '^Enter new path' then
                    vim.ui.input({
                      prompt = 'Enter move destination:',
                      default = vim.fn.fnamemodify(fname, ':h') .. '/',
                      completion = 'file',
                    }, function(newf)
                      return newf and move(newf)
                    end)
                  elseif f then
                    move(f)
                  end
                end)
              end)
            end
          end, 'vtsls')
          -- copy typescript settings to javascript
          opts.settings.javascript = vim.tbl_deep_extend('force', {}, opts.settings.typescript, opts.settings.javascript or {})
        end,
      },
    },
  },

  {
    'mfussenegger/nvim-dap',
    optional = true,
    opts = function()
      local dap = require 'dap'
      require('dap').adapters['pwa-node'] = {
        type = 'server',
        host = 'localhost',
        port = '${port}',
        executable = {
          command = 'node', -- 💀 Make sure to update this path to point to your installation
          args = {
            require('util').get_pkg_path('js-debug-adapter', 'js-debug/src/dapDebugServer.js'),
            '${port}',
          },
        },
      }
      dap.adapters['node'] = function(cb, config)
        if config.type == 'node' then
          config.type = 'pwa-node'
        end
        local nativeAdapter = dap.adapters['pwa-node']
        if type(nativeAdapter) == 'function' then
          nativeAdapter(cb, config)
        else
          cb(nativeAdapter)
        end
      end

      local js_filetypes = { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'vue' }

      local vscode = require 'dap.ext.vscode'
      vscode.type_to_filetypes['node'] = js_filetypes
      vscode.type_to_filetypes['pwa-node'] = js_filetypes

      local generic = {
        { type = 'pwa-node', request = 'launch', name = 'Launch file', program = '${file}', cwd = '${workspaceFolder}' },
        {
          type = 'pwa-node', request = 'attach', name = 'Attach to Node process',
          processId = require('dap.utils').pick_process, cwd = '${workspaceFolder}',
        },
      }
      for _, language in ipairs(js_filetypes) do
        dap.configurations[language] = vim.deepcopy(generic)
      end

      local default_launch_provider = dap.providers.configs['dap.launch.json']
      dap.providers.configs['dap.launch.json'] = function(bufnr)
        if not vim.tbl_contains(js_filetypes, vim.bo[bufnr].filetype) then
          return default_launch_provider and default_launch_provider(bufnr) or {}
        end
        local context = require('nv_ide.project').javascript(bufnr)
        if not context.launch_json then return {} end
        local ok, configs = pcall(require('dap.ext.vscode').getconfigs, context.launch_json)
        if not ok then
          vim.notify('JavaScript launch.json: ' .. tostring(configs), vim.log.levels.WARN)
          return {}
        end
        return vim.tbl_filter(function(config)
          return config.type == 'node' or config.type == 'pwa-node'
        end, configs or {})
      end

      local package_exec_args = {
        npm = { 'exec', '--' },
        pnpm = { 'exec' },
        yarn = { 'exec' },
        bun = { 'x' },
      }

      local function framework_command(context, name)
        local executable = context.executables[name]
        if executable then return { program = executable } end
        local prefix = context.package_manager and package_exec_args[context.package_manager]
        if not context.configs[name] or not prefix then return nil end
        local runtime_args = vim.deepcopy(prefix)
        runtime_args[#runtime_args + 1] = name
        return { runtimeExecutable = context.package_manager, runtimeArgs = runtime_args }
      end

      local function configured_args(context, name, args, flag)
        args = vim.deepcopy(args)
        local config = context.configs[name]
        if config and flag then
          args[#args + 1] = flag
          args[#args + 1] = config
        end
        return args
      end

      local function add_framework(configs, context, name, config)
        local command = framework_command(context, name)
        if command then
          configs[#configs + 1] = vim.tbl_deep_extend('force', config, command)
        end
      end

      dap.providers.configs.nv_ide_javascript = function(bufnr)
        if not vim.tbl_contains(js_filetypes, vim.bo[bufnr].filetype) then return {} end
        local context = require('nv_ide.project').javascript(bufnr)
        if not context.root then return {} end
        local configs = {}

        add_framework(configs, context, 'jest', {
          type = 'pwa-node', request = 'launch', name = 'Jest Current File',
          args = configured_args(context, 'jest', { '--runInBand', '${relativeFile}' }, '--config'),
          cwd = context.root, console = 'integratedTerminal', internalConsoleOptions = 'neverOpen',
        })
        add_framework(configs, context, 'mocha', {
          type = 'pwa-node', request = 'launch', name = 'Mocha Current File',
          args = configured_args(context, 'mocha', { '--timeout', '999999', '--colors', '${file}' }, '--config'),
          cwd = context.root, console = 'integratedTerminal', internalConsoleOptions = 'neverOpen',
        })
        local karma_args = { 'start' }
        if context.configs.karma then karma_args[#karma_args + 1] = context.configs.karma end
        vim.list_extend(karma_args, { '--browsers', 'ChromeHeadless' })
        add_framework(configs, context, 'karma', {
          type = 'pwa-node', request = 'launch', name = 'Karma All Tests',
          args = karma_args,
          cwd = context.root, console = 'integratedTerminal', internalConsoleOptions = 'neverOpen',
        })
        local jasmine_args = { '${file}' }
        if context.configs.jasmine then
          jasmine_args[#jasmine_args + 1] = '--config=' .. context.configs.jasmine
        end
        add_framework(configs, context, 'jasmine', {
          type = 'pwa-node', request = 'launch', name = 'Jasmine Current File',
          args = jasmine_args,
          cwd = context.root, console = 'integratedTerminal', internalConsoleOptions = 'neverOpen',
        })
        return configs
      end
    end,
  },
}
