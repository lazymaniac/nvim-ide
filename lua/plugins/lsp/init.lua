local Util = require 'util'

local function ensure_installed(packages)
  for _, package in ipairs(packages) do
    if not require('mason-registry').is_installed(package) then
      vim.cmd('MasonInstall ' .. package)
    end
  end
end

local packages = {
  'stylua', -- lua
  'hadolint', -- docker
  'djlint', -- angular, go
  'ansible-lint', -- ansible
  'cmakelint', -- cmake
  'cmakelang',
  'codelldb', -- rust, c
  'shellcheck', -- bash
  'shellharden',
  'beautysh',
  'bash-debug-adapter',
  'goimports', -- go
  'gofumpt',
  'staticcheck',
  'trivy',
  'delve',
  'haskell-debug-adapter', -- haskell
  'hlint',
  'prettierd', -- html
  'htmlhint',
  'stylelint',
  'eslint_d',
  'java-debug-adapter', -- java
  'checkstyle',
  'java-test',
  'vscode-java-decompiler',
  'jq', -- json
  'jsonlint',
  'prettierd',
  'ktlint', -- kotlin
  'kotlin-debug-adapter',
  'markdown-toc', -- markdown
  'markdownlint',
  'write-good',
  'black', -- python
  'pydocstyle',
  'pylint',
  'docformatter',
  'debugpy',
  'erb-formatter', -- ruby
  'erb-lint',
  'robocop',
  'sqlfmt', -- sql
  'sqlfluff',
  'sqruff',
  'tfsec', -- terraform
  'trivy',
  'chrome-debug-adapter', -- typescript
  'firefox-debug-adapter',
  'js-debug-adapter',
  'node-debug2-adapter',
  'eslint_d',
  'yamllint', -- yaml
  'prettierd',
}

return {
  --
  -- [mason.nvim] - LSP, formatter, dap, test tools installer
  -- see: `:h mason.nvim`
  -- link: https://github.com/mason-org/mason.nvim
  {
    'mason-org/mason.nvim',
    branch = 'main',
    event = 'VeryLazy',
    cmd = 'Mason',
    build = ':MasonUpdate',
    opts = {
      registries = {
        'github:mason-org/mason-registry',
      },
      providers = {
        'mason.providers.registry-api',
        'mason.providers.client',
      },
      ui = {
        check_outdated_packages_on_open = true,
        border = nil,
        backdrop = 60,
        width = 0.8,
        height = 0.9,
        icons = {
          package_installed = '✓',
          package_pending = '➜',
          package_uninstalled = '✗',
        },
      },
    },
    config = function(_, opts)
      require('mason').setup(opts)
      ensure_installed(packages)
    end,
  },

  {
    'mason-org/mason-lspconfig.nvim',
    branch = 'main',
    opts = {
      ensure_installed = {
        'lua_ls',
        'vimls',
        'clangd',
        'angularls',
        'ansiblels',
        'bashls',
        'clojure_lsp',
        'cmake',
        'cucumber_language_server',
        'dockerls',
        'docker_compose_language_service',
        'elixirls',
        'gopls',
        'gradle_ls',
        'groovyls',
        'hls',
        'yamlls',
        'helm_ls',
        'html',
        'emmet_ls',
        'cssls',
        'jdtls',
        'sonarlint-language-server',
        'jsonls',
        'julials',
        'kotlin_language_server',
        'marksman',
        'puppet',
        'pyright',
        'ruby_lsp',
        'rubocop',
        'rust_analyzer',
        'taplo',
        'sqls',
        'svelte',
        'terraformls',
        'vtsls',
        'ts_ls',
        'volar',
      },
      automatic_enable = {
        exclude = { 'rust_analyzer', 'jdtls' },
      },
    },
  },

  -- [nvim-lspconfig] - LSP integration config.
  -- see: `:h nvim-lspconfig`
  -- link: https://github.com/neovim/nvim-lspconfig
  {
    'neovim/nvim-lspconfig',
    event = 'VeryLazy',
    config = function(_, opts)
      -- setup keymaps
      Util.lsp.on_attach(function(client, buffer)
        require('plugins.lsp.keymaps').on_attach(client, buffer)
      end)
      local register_capability = vim.lsp.handlers['client/registerCapability']
      vim.lsp.handlers['client/registerCapability'] = function(err, res, ctx)
        local ret = register_capability(err, res, ctx)
        local client_id = ctx.client_id
        local client = vim.lsp.get_client_by_id(client_id)
        local buffer = vim.api.nvim_get_current_buf()
        require('plugins.lsp.keymaps').on_attach(client, buffer)
        return ret
      end
      -- diagnostics
      for name, icon in pairs(require('config').icons.diagnostics) do
        name = 'DiagnosticSign' .. name
        vim.fn.sign_define(name, { text = icon, texthl = name, numhl = '' })
      end
      if opts.inlay_hints.enabled then
        Util.lsp.on_attach(function(client, buffer)
          if client.supports_method 'textDocument/inlayHint' then
            Util.toggle.inlay_hints()
          end
        end)
      end
      if type(opts.diagnostics.virtual_text) == 'table' and opts.diagnostics.virtual_text.prefix == 'icons' then
        opts.diagnostics.virtual_text.prefix = vim.fn.has 'nvim-0.10.0' == 0 and '●'
          or function(diagnostic)
            local icons = require('config').icons.diagnostics
            for d, icon in pairs(icons) do
              if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
                return icon
              end
            end
          end
      end
      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))
      -- get all the servers that are available through mason-lspconfig
      local have_mason, mlsp = pcall(require, 'mason-lspconfig')
      local all_mslp_servers = {}
      if have_mason then
        all_mslp_servers = vim.tbl_keys(require('mason-lspconfig.mappings').get_mason_map().lspconfig_to_package)
      end
      local ensure_installed = {} ---@type string[]
      for server, server_opts in pairs(servers) do
        if server_opts then
          server_opts = server_opts == true and {} or server_opts
          -- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
          if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
            setup(server)
          else
            ensure_installed[#ensure_installed + 1] = server
          end
        end
      end
      if have_mason then
        mlsp.setup { ensure_installed = ensure_installed, handlers = { setup } }
      end
      if Util.lsp.get_config 'denols' and Util.lsp.get_config 'tsserver' then
        local is_deno = require('util').root_pattern('deno.json', 'deno.jsonc')
        Util.lsp.disable('tsserver', is_deno)
        Util.lsp.disable('denols', function(root_dir)
          return not is_deno(root_dir)
        end)
      end
    end,
  },

  {
    'folke/lazydev.nvim',
    ft = 'lua', -- only load on lua files
    cmd = 'LazyDev',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        { path = 'luvit-meta/library', words = { 'vim%.uv' } },
        { path = 'snacks.nvim', words = { 'Snacks' } },
      },
    },
  },

  { 'Bilal2453/luvit-meta', lazy = true }, -- optional `vim.uv` typings
}
