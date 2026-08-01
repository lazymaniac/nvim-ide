local h = require 'tests.headless.harness'

local expected_tools = {
  'actionlint', 'ansible-lint', 'bash-debug-adapter', 'beautysh', 'black', 'clj-kondo', 'cmakelang', 'cmakelint',
  'codelldb', 'cypher-language-server', 'debugpy', 'delve', 'detekt', 'djlint', 'docformatter', 'erb-formatter',
  'erb-lint', 'eslint_d', 'gofumpt', 'goimports', 'golangci-lint', 'graphql-language-service-cli', 'hadolint',
  'haskell-debug-adapter', 'hlint', 'htmlhint', 'java-debug-adapter', 'java-test', 'jq', 'js-debug-adapter',
  'jsonlint', 'kotlin-debug-adapter', 'ktlint', 'kube-linter', 'luacheck', 'markdown-toc', 'markdownlint',
  'postgres-language-server', 'prettierd', 'pydocstyle', 'pylint', 'rubocop', 'shellcheck', 'shellharden',
  'sonarlint-language-server', 'sqlfluff', 'sqlfmt', 'sqruff', 'staticcheck', 'stylelint', 'stylua', 'tfsec',
  'trivy', 'vscode-java-decompiler', 'vscode-java-dependency', 'vscode-spring-boot-tools', 'write-good',
  'xmlformatter', 'yamllint',
}

local expected_servers = {
  'angularls', 'ansiblels', 'bashls', 'clangd', 'clojure_lsp', 'cmake', 'cssls', 'cucumber_language_server',
  'docker_compose_language_service', 'dockerls', 'emmet_ls', 'gopls', 'gradle_ls', 'groovyls', 'helm_ls', 'hls',
  'html', 'jdtls', 'jsonls', 'kotlin_language_server', 'lua_ls', 'marksman', 'puppet', 'pyright', 'rubocop',
  'ruby_lsp', 'rust_analyzer', 'sqls', 'svelte', 'taplo', 'terraformls', 'vtsls', 'yamlls',
}

local expected_parsers = {
  'angular', 'bash', 'c', 'clojure', 'cmake', 'cpp', 'css', 'dap_repl', 'diff', 'dockerfile', 'dot', 'git_config',
  'git_rebase', 'gitattributes', 'gitcommit', 'gitignore', 'go', 'gomod', 'gosum', 'gowork', 'groovy', 'haskell',
  'hcl', 'helm', 'html', 'http', 'java', 'javascript', 'jsdoc', 'json', 'json5', 'kotlin', 'latex', 'lua', 'luadoc',
  'luap', 'markdown', 'markdown_inline', 'mermaid', 'ninja', 'properties', 'python', 'query', 'r', 'regex', 'ron',
  'rst', 'ruby', 'rust', 'scala', 'scss', 'sql', 'svelte', 'terraform', 'toml', 'tsx', 'typescript', 'vim',
  'vimdoc', 'vue', 'xml', 'yaml',
}

local function sorted_unique(values)
  local seen, result = {}, {}
  for _, value in ipairs(values) do
    if not seen[value] then
      seen[value] = true
      result[#result + 1] = value
    end
  end
  table.sort(result)
  return result
end

local server_packages = {
  angularls = 'angular-language-server',
  ansiblels = 'ansible-language-server',
  bashls = 'bash-language-server',
  clojure_lsp = 'clojure-lsp',
  cmake = 'cmake-language-server',
  cssls = 'css-lsp',
  cucumber_language_server = 'cucumber-language-server',
  docker_compose_language_service = 'docker-compose-language-service',
  dockerls = 'dockerfile-language-server',
  emmet_ls = 'emmet-language-server',
  gradle_ls = 'gradle-language-server',
  groovyls = 'groovy-language-server',
  helm_ls = 'helm-ls',
  hls = 'haskell-language-server',
  html = 'html-lsp',
  jsonls = 'json-lsp',
  kotlin_language_server = 'kotlin-language-server',
  lua_ls = 'lua-language-server',
  puppet = 'puppet-editor-services',
  ruby_lsp = 'ruby-lsp',
  rust_analyzer = 'rust-analyzer',
  svelte = 'svelte-language-server',
  terraformls = 'terraform-ls',
  yamlls = 'yaml-language-server',
}

local function expected_mason()
  local values = vim.deepcopy(expected_tools)
  for _, server in ipairs(expected_servers) do
    values[#values + 1] = server_packages[server] or server:gsub('_', '-')
  end
  return sorted_unique(values)
end

local function names(records)
  local result = {}
  for _, record in ipairs(records or {}) do result[#result + 1] = record.id end
  return result
end

h.describe('complete toolchain manifest', function()
  h.it('contains the exact deduplicated Mason and Tree-sitter inventories', function()
    package.loaded['nv_ide.toolchain.manifest'] = nil
    local manifest = require 'nv_ide.toolchain.manifest'
    h.equal(manifest.schema_version, 1)
    h.deep_equal(manifest.mason.tools, expected_tools)
    h.deep_equal(manifest.lsp.servers, expected_servers)
    h.deep_equal(manifest.mason.packages, expected_mason())
    h.equal(#manifest.mason.packages, 91)
    h.deep_equal(manifest.treesitter.parsers, expected_parsers)
    h.equal(#manifest.treesitter.parsers, 62)
  end)

  h.it('describes every runtime, external action, and AI dependency without selectors', function()
    local manifest = require 'nv_ide.toolchain.manifest'
    local runtime_names = names(manifest.runtimes)
    for _, runtime in ipairs {
      'ansible', 'clojure', 'cmake', 'containers', 'dart', 'go', 'haskell', 'java', 'javascript', 'kotlin',
      'lua', 'python', 'r', 'ruby', 'rust', 'scala', 'sql', 'terraform',
    } do
      h.truthy(vim.tbl_contains(runtime_names, runtime), 'missing runtime: ' .. runtime)
    end

    local action_names = names(manifest.external_actions)
    h.deep_equal(action_names, {
      'btop', 'cloudlens', 'clx', 'dua', 'euporie-notebook', 'glab-tui', 'harlequin', 'jshell', 'k9s',
      'lazydocker', 'nap', 'omm', 'podman-tui', 'posting', 'python3', 'termscp', 'tiki', 'zellij',
    })
    h.deep_equal(manifest.ai.cli, { 'claude', 'cline', 'codex' })
    h.deep_equal(names(manifest.ai.backends), { 'ollama' })
    h.truthy(manifest.plugin_branches['nvim-treesitter/nvim-treesitter'] == 'main')
    h.truthy(manifest.plugin_branches['linux-cultist/venv-selector.nvim'] == 'regexp')

    local rendered = vim.inspect(manifest):lower()
    h.falsy(rendered:find('profile', 1, true), 'runtime manifest must expose one inventory, not selectors')
  end)

  h.it('has a stable schema-bound fingerprint', function()
    local manifest = require 'nv_ide.toolchain.manifest'
    local first = manifest.fingerprint()
    local second = manifest.fingerprint()
    h.equal(first, second)
    h.truthy(first:match('^[0-9a-f]+$'))
    h.equal(#first, 64)
  end)

  h.it('honors setup options and loads each config module once', function()
    local saved = {
      config = package.loaded.config,
      util = package.loaded.util,
      cache = package.loaded['lazy.core.cache'],
    }
    local attempts = {}
    package.loaded.config = nil
    package.loaded.util = {
      root = { setup = function() end },
      try = function(callback, opts)
        attempts[#attempts + 1] = opts.msg
        callback()
      end,
      lazy_notify = function() end,
    }
    package.loaded['lazy.core.cache'] = { find = function() return { true } end }
    package.loaded['config.autocmds'] = nil
    package.loaded['config.keymaps'] = nil
    package.preload['config.autocmds'] = function() return {} end
    package.preload['config.keymaps'] = function() return {} end

    local ok, err = xpcall(function()
      require('config').setup { defaults = { autocmds = false, keymaps = true } }
    end, debug.traceback)

    package.loaded.config = saved.config
    package.loaded.util = saved.util
    package.loaded['lazy.core.cache'] = saved.cache
    package.loaded['config.autocmds'] = nil
    package.loaded['config.keymaps'] = nil
    package.preload['config.autocmds'] = nil
    package.preload['config.keymaps'] = nil
    if not ok then error(err, 0) end

    h.deep_equal(attempts, { 'Failed loading config.keymaps' })
  end)
end)
