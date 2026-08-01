local M = {
  schema_version = 1,
  mason = {
    tools = {
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
    },
  },
  lsp = {
    servers = {
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
    },
  },
  treesitter = {
    parsers = {
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
    },
  },
  prerequisites = {
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
  },
  runtimes = {
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
    {
      id = 'haskell',
      executables = { 'ghcup', 'cabal', 'ghc' },
      version = { command = { 'ghc', '--numeric-version' }, pattern = '(%d+%.%d+%.%d+)', minimum = '8.10.0' },
      capabilities = {
        {
          id = 'cabal_version',
          kind = 'command_version',
          command = { 'cabal', '--numeric-version' },
          pattern = '(%d+%.%d+%.%d+)',
          minimum = '3.0.0',
        },
      },
    },
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
      capabilities = {
        {
          id = 'development_headers',
          kind = 'command',
          command = {
            'ruby',
            '-rrbconfig',
            '-e',
            "header = File.join(RbConfig::CONFIG.fetch('rubyhdrdir'), 'ruby.h'); exit(File.file?(header) ? 0 : 1)",
          },
        },
      },
    },
    {
      id = 'rust',
      executables = { 'rustc', 'cargo' },
      version = { command = { 'rustc', '--version' }, pattern = 'rustc%s+(%d+%.%d+%.%d+)', minimum = '1.42.0' },
      capabilities = {
        {
          id = 'cargo_version',
          kind = 'command_version',
          command = { 'cargo', '--version' },
          pattern = 'cargo%s+(%d+%.%d+%.%d+)',
          minimum = '1.42.0',
        },
      },
    },
    { id = 'scala', executables = { 'scala', 'sbt' } },
    { id = 'sql', executables = { 'psql' } },
    { id = 'terraform', executables = { 'terraform' } },
  },
  external_actions = {
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
  },
  ai = {
    cli = { 'claude', 'cline', 'codex' },
    backends = {
      { id = 'ollama', executable = 'ollama', url = 'http://127.0.0.1:11434' },
    },
    credentials = { 'ANTHROPIC_API_KEY', 'OPENAI_API_KEY' },
  },
  plugin_branches = {
    ['linux-cultist/venv-selector.nvim'] = 'regexp',
    ['nvim-treesitter/nvim-treesitter'] = 'main',
    ['nvim-treesitter/nvim-treesitter-textobjects'] = 'main',
  },
}

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

local mason = vim.deepcopy(M.mason.tools)
for _, server in ipairs(M.lsp.servers) do
  mason[#mason + 1] = server_packages[server] or server:gsub('_', '-')
end
M.mason.packages = sorted_unique(mason)

local function canonical(value)
  if type(value) ~= 'table' then
    return vim.json.encode(value)
  end
  if vim.islist(value) then
    local parts = {}
    for _, item in ipairs(value) do
      parts[#parts + 1] = canonical(item)
    end
    return '[' .. table.concat(parts, ',') .. ']'
  end
  local keys = vim.tbl_keys(value)
  table.sort(keys)
  local parts = {}
  for _, key in ipairs(keys) do
    parts[#parts + 1] = canonical(key) .. ':' .. canonical(value[key])
  end
  return '{' .. table.concat(parts, ',') .. '}'
end

function M.fingerprint()
  return vim.fn.sha256(canonical {
    schema_version = M.schema_version,
    mason = M.mason,
    lsp = M.lsp,
    treesitter = M.treesitter,
    prerequisites = M.prerequisites,
    runtimes = M.runtimes,
    external_actions = M.external_actions,
    ai = M.ai,
    plugin_branches = M.plugin_branches,
  })
end

return M
