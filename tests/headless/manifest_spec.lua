local h = require 'tests.headless.harness'

local expected_tools = {
  'actionlint',
  'ansible-lint',
  'bash-debug-adapter',
  'beautysh',
  'black',
  'clj-kondo',
  'cmakelang',
  'cmakelint',
  'codelldb',
  'cypher-language-server',
  'debugpy',
  'delve',
  'detekt',
  'djlint',
  'docformatter',
  'erb-formatter',
  'erb-lint',
  'eslint_d',
  'gofumpt',
  'goimports',
  'golangci-lint',
  'graphql-language-service-cli',
  'hadolint',
  'haskell-debug-adapter',
  'hlint',
  'htmlhint',
  'java-debug-adapter',
  'java-test',
  'jq',
  'js-debug-adapter',
  'jsonlint',
  'kotlin-debug-adapter',
  'ktlint',
  'kube-linter',
  'luacheck',
  'markdown-toc',
  'markdownlint',
  'postgres-language-server',
  'prettierd',
  'pydocstyle',
  'pylint',
  'rubocop',
  'shellcheck',
  'shellharden',
  'sonarlint-language-server',
  'sqlfluff',
  'sqlfmt',
  'sqruff',
  'staticcheck',
  'stylelint',
  'stylua',
  'tfsec',
  'trivy',
  'vscode-java-decompiler',
  'vscode-java-dependency',
  'vscode-spring-boot-tools',
  'write-good',
  'xmlformatter',
  'yamllint',
}

local expected_servers = {
  'angularls',
  'ansiblels',
  'bashls',
  'clangd',
  'clojure_lsp',
  'cmake',
  'cssls',
  'cucumber_language_server',
  'docker_compose_language_service',
  'dockerls',
  'emmet_ls',
  'gopls',
  'gradle_ls',
  'groovyls',
  'helm_ls',
  'hls',
  'html',
  'jdtls',
  'jsonls',
  'kotlin_language_server',
  'lua_ls',
  'marksman',
  'puppet',
  'pyright',
  'rubocop',
  'ruby_lsp',
  'rust_analyzer',
  'sqls',
  'svelte',
  'taplo',
  'terraformls',
  'vtsls',
  'yamlls',
}

local expected_parsers = {
  'angular',
  'bash',
  'c',
  'clojure',
  'cmake',
  'cpp',
  'css',
  'dap_repl',
  'diff',
  'dockerfile',
  'dot',
  'git_config',
  'git_rebase',
  'gitattributes',
  'gitcommit',
  'gitignore',
  'go',
  'gomod',
  'gosum',
  'gowork',
  'groovy',
  'haskell',
  'hcl',
  'helm',
  'html',
  'http',
  'java',
  'javascript',
  'jsdoc',
  'json',
  'json5',
  'kotlin',
  'latex',
  'lua',
  'luadoc',
  'luap',
  'markdown',
  'markdown_inline',
  'mermaid',
  'ninja',
  'properties',
  'python',
  'query',
  'r',
  'regex',
  'ron',
  'rst',
  'ruby',
  'rust',
  'scala',
  'scss',
  'sql',
  'svelte',
  'terraform',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'vue',
  'xml',
  'yaml',
}

local expected_prerequisites = {
  { id = 'archive', executables = { 'tar', 'unzip' }, required = true },
  { id = 'bash', executables = { 'bash' }, required = true },
  { id = 'c_compiler', executables = { 'cc', 'clang', 'gcc' }, any = true, required = true },
  { id = 'curl', executables = { 'curl' }, required = true },
  { id = 'git', executables = { 'git' }, required = true },
  { id = 'gzip', executables = { 'gzip' }, required = true },
  { id = 'lua_package_manager', executables = { 'luarocks' }, required = true },
  {
    id = 'mason_hlint_rosetta',
    executables = { 'arch' },
    required = true,
    platform = { os = 'Darwin', arches = { 'arm64', 'aarch64' } },
    capabilities = {
      { id = 'x86_64_translation', kind = 'command', command = { 'arch', '-x86_64', '/usr/bin/true' } },
    },
  },
  { id = 'ripgrep', executables = { 'rg' }, required = true },
  { id = 'ruby_package_manager', executables = { 'gem' }, required = true },
  { id = 'snacks_image_ghostscript', executables = { 'gs' }, required = false },
  { id = 'snacks_image_latex', executables = { 'tectonic', 'pdflatex' }, any = true, required = false },
  { id = 'snacks_image_mermaid', executables = { 'mmdc' }, required = false },
  { id = 'snacks_image_raster', executables = { 'magick' }, required = false },
  { id = 'tree_sitter_cli', executables = { 'tree-sitter' }, required = true },
}

local expected_runtimes = {
  { id = 'ansible', executables = { 'ansible', 'ansible-playbook' } },
  { id = 'clojure', executables = { 'clojure', 'lein', 'bb' }, any = true },
  { id = 'cmake', executables = { 'cmake', 'ninja' } },
  { id = 'containers', executables = { 'docker', 'podman' }, any = true },
  { id = 'dart', executables = { 'dart', 'flutter' } },
  {
    id = 'go',
    executables = { 'go' },
    version = { command = { 'go', 'version' }, pattern = 'go(%d+%.%d+%.%d+)', minimum = '1.26.0' },
  },
  { id = 'haskell', executables = { 'ghcup', 'cabal', 'ghc' } },
  {
    id = 'java',
    executables = { 'java', 'javac', 'mvn', 'gradle' },
    version = {
      command = { 'java', '-version' },
      pattern = 'version%s+"?(%d+%.%d+%.%d+)',
      minimum = '21.0.0',
    },
    capabilities = {
      {
        id = 'javac_version',
        kind = 'command_version',
        command = { 'javac', '-version' },
        pattern = 'javac%s+(%d+%.%d+%.%d+)',
        minimum = '21.0.0',
      },
    },
  },
  {
    id = 'javascript',
    executables = { 'node', 'npm' },
    version = { command = { 'node', '--version' }, pattern = 'v?(%d+%.%d+%.%d+)', minimum = '24.15.0' },
  },
  { id = 'kotlin', executables = { 'kotlinc' } },
  { id = 'lua', executables = { 'lua', 'luajit' }, any = true },
  {
    id = 'python',
    executables = { 'python3' },
    version = {
      command = { 'python3', '--version' },
      pattern = 'Python%s+(%d+%.%d+%.%d+)',
      minimum = '3.10.0',
      maximum_exclusive = '3.14.0',
    },
    capabilities = { { id = 'venv', kind = 'python_venv', executable = 'python3' } },
  },
  { id = 'r', executables = { 'R' } },
  {
    id = 'ruby',
    executables = { 'ruby', 'bundle' },
    version = { command = { 'ruby', '--version' }, pattern = 'ruby%s+(%d+%.%d+%.%d+)', minimum = '3.0.0' },
  },
  { id = 'rust', executables = { 'rustc', 'cargo' } },
  { id = 'scala', executables = { 'scala', 'sbt' } },
  { id = 'sql', executables = { 'psql' } },
  { id = 'terraform', executables = { 'terraform' } },
}

local expected_external_actions = {
  { id = 'btop', command = { 'btop' } },
  { id = 'cloudlens', command = { 'cloudlens' } },
  { id = 'clx', command = { 'clx' } },
  { id = 'dua', command = { 'dua', 'i' } },
  { id = 'euporie-notebook', command = { 'euporie-notebook' } },
  { id = 'glab-tui', command = { 'glab-tui' } },
  { id = 'harlequin', command = { 'harlequin' } },
  { id = 'jshell', command = { 'jshell' } },
  { id = 'k9s', command = { 'k9s' } },
  { id = 'lazydocker', command = { 'lazydocker' } },
  { id = 'nap', command = { 'nap' } },
  { id = 'omm', command = { 'omm', '--editor', 'nvim' } },
  { id = 'podman-tui', command = { 'podman-tui' } },
  { id = 'posting', command = { 'posting' } },
  { id = 'python3', command = { 'python3' } },
  { id = 'termscp', command = { 'termscp' } },
  { id = 'tiki', command = { 'tiki' } },
  {
    id = 'zellij',
    command = { 'zellij', 'attach', '-c', 'options', '--theme', 'kanagawa', '--show-startup-tips', 'true' },
  },
}

local expected_ai = {
  cli = { 'claude', 'cline', 'codex' },
  backends = {
    { id = 'ollama', executable = 'ollama', url = 'http://127.0.0.1:11434' },
  },
  credentials = { 'ANTHROPIC_API_KEY', 'OPENAI_API_KEY' },
}

local expected_plugin_branches = {
  ['linux-cultist/venv-selector.nvim'] = 'regexp',
  ['nvim-treesitter/nvim-treesitter'] = 'main',
  ['nvim-treesitter/nvim-treesitter-textobjects'] = 'main',
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

  h.it('describes every prerequisite, runtime, external action, and AI dependency exactly', function()
    local manifest = require 'nv_ide.toolchain.manifest'
    h.deep_equal(manifest.prerequisites, expected_prerequisites)
    h.deep_equal(manifest.runtimes, expected_runtimes)
    h.deep_equal(manifest.external_actions, expected_external_actions)
    h.deep_equal(manifest.ai, expected_ai)
    h.deep_equal(manifest.plugin_branches, expected_plugin_branches)

    local rendered = vim.inspect(manifest):lower()
    h.falsy(rendered:find('profile', 1, true), 'runtime manifest must expose one inventory, not selectors')
  end)

  h.it('has a stable schema-bound fingerprint', function()
    local manifest = require 'nv_ide.toolchain.manifest'
    local first = manifest.fingerprint()
    local second = manifest.fingerprint()
    h.equal(first, second)
    h.truthy(first:match '^[0-9a-f]+$')
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
    package.loaded['lazy.core.cache'] = {
      find = function()
        return { true }
      end,
    }
    package.loaded['config.autocmds'] = nil
    package.loaded['config.keymaps'] = nil
    package.preload['config.autocmds'] = function()
      return {}
    end
    package.preload['config.keymaps'] = function()
      return {}
    end

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
    if not ok then
      error(err, 0)
    end

    h.deep_equal(attempts, { 'Failed loading config.keymaps' })
  end)
end)
