local M = {}

local function executable(name)
  return vim.fn.executable(name) == 1
end

local function read_number(path)
  local ok, lines = pcall(vim.fn.readfile, path, '', 1)
  return ok and tonumber(lines[1]) or nil
end

local function command_output(command, timeout_ms)
  local ok, process = pcall(vim.system, command, { text = true })
  if not ok then
    return nil
  end
  local waited, result = pcall(process.wait, process, timeout_ms or 1000)
  if not waited or result.code ~= 0 then
    return nil
  end
  return vim.trim(table.concat { result.stdout or '', result.stderr or '' })
end

local function command_result(command, timeout_ms)
  local ok, process = pcall(vim.system, command, { text = true })
  if not ok then
    return nil
  end
  local waited, result = pcall(process.wait, process, timeout_ms or 1000)
  return waited and result or nil
end

local function default_watcher()
  local supported = false
  local ok, handle = pcall(vim.uv.new_fs_event)
  if ok and handle then
    supported = true
    handle:close()
  end
  local result = { supported = supported, backend = supported and 'fs_event' or 'unavailable' }
  if vim.uv.os_uname().sysname == 'Linux' then
    local watches = read_number '/proc/sys/fs/inotify/max_user_watches'
    local instances = read_number '/proc/sys/fs/inotify/max_user_instances'
    result.inotify = {
      max_user_watches = watches,
      max_user_instances = instances,
      sufficient = watches ~= nil and watches >= 524288 and instances ~= nil and instances >= 128,
    }
  end
  return result
end

local function tmux_clipboard()
  if not vim.env.TMUX then
    return { active = false, set_clipboard = 'not-applicable', ms = false }
  end
  if not executable 'tmux' then
    return { active = true, set_clipboard = 'unknown', ms = false }
  end

  local set_clipboard = command_output { 'tmux', 'show', '-s', '-gv', 'set-clipboard' } or 'unknown'
  local info = command_output { 'tmux', 'info' } or ''
  local ms = false
  for line in info:gmatch '[^\r\n]+' do
    if line:find('Ms:', 1, true) then
      ms = not line:find('[missing]', 1, true) and not line:match 'Ms:%s*$'
      break
    end
  end
  return { active = true, set_clipboard = set_clipboard, ms = ms }
end

local function default_clipboard()
  local os_name = vim.uv.os_uname().sysname
  local local_providers = {
    pbcopy = executable 'pbcopy' and executable 'pbpaste',
    wl_copy = executable 'wl-copy' and executable 'wl-paste',
    xclip = executable 'xclip',
    xsel = executable 'xsel',
  }
  local ssh = vim.env.SSH_CONNECTION ~= nil or vim.env.SSH_TTY ~= nil
  local configured = type(vim.g.clipboard) == 'table' and vim.g.clipboard.name or nil
  local provider = configured
  if not provider and not ssh then
    if os_name == 'Darwin' and local_providers.pbcopy then
      provider = 'pbcopy'
    elseif local_providers.wl_copy then
      provider = 'wl-clipboard'
    elseif local_providers.xclip then
      provider = 'xclip'
    elseif local_providers.xsel then
      provider = 'xsel'
    end
  end
  return {
    session = ssh and 'ssh' or 'local',
    provider = provider or 'none',
    available = provider ~= nil,
    tmux = tmux_clipboard(),
    local_providers = local_providers,
  }
end

local function default_backend(backend)
  if not executable(backend.executable) or not executable 'curl' then
    return false
  end
  local ok, process = pcall(vim.system, {
    'curl',
    '--silent',
    '--fail',
    '--max-time',
    '1',
    backend.url,
  }, { text = true })
  if not ok then
    return false
  end
  local waited, result = pcall(process.wait, process, 1500)
  return waited and result.code == 0
end

function M.mason_package_status(package)
  local installing_ok, installing = pcall(package.is_installing, package)
  if not installing_ok then
    return { status = 'unknown' }
  end
  if installing then
    return { status = 'installing' }
  end

  local installed_ok, installed = pcall(package.is_installed, package)
  if not installed_ok then
    return { status = 'unknown' }
  end
  if installed then
    local receipt_ok, receipt = pcall(function()
      return package:get_receipt():or_else(nil)
    end)
    local completed = receipt_ok and type(receipt) == 'table' and type(receipt.metrics) == 'table' and tonumber(receipt.metrics.completion_time) ~= nil
    if not completed then
      return { status = 'failed' }
    end
    local version_ok, version = pcall(package.get_installed_version, package)
    if not version_ok or type(version) ~= 'string' or version == '' then
      return { status = 'failed' }
    end
    return { status = 'installed', version = version }
  end

  local handle_ok, handle = pcall(function()
    return package:get_install_handle():or_else(nil)
  end)
  if handle_ok and handle then
    return { status = 'failed' }
  end
  return { status = 'missing' }
end

local function default_mason_status(name)
  local ok, package = pcall(function()
    return require('mason-registry').get_package(name)
  end)
  if not ok or not package then
    return { status = 'unknown' }
  end
  return M.mason_package_status(package)
end

function M.parser_install_status(installed, revision)
  if not installed then
    return { status = 'missing' }
  end
  if not revision or vim.trim(tostring(revision)) == '' then
    return { status = 'failed' }
  end
  return { status = 'installed', revision = vim.trim(tostring(revision)) }
end

function M.parser_provider_status(name, installed, options)
  local ok, status = pcall(require('nv_ide.toolchain.treesitter_receipt').inspect, name, installed, options)
  return ok and status or { status = 'failed' }
end

local function default_parser_status(name, installed)
  return M.parser_provider_status(name, installed[name] == true)
end

local function default_treesitter_cli_version()
  local output = command_output { 'tree-sitter', '--version' }
  return output and output:match '[vV]?(%d+%.%d+%.%d+[%w%._%-]*)' or nil
end

local function version_parts(version)
  local major, minor, patch = tostring(version or ''):match '^(%d+)%.(%d+)%.(%d+)'
  if not major then
    return nil
  end
  return { tonumber(major), tonumber(minor), tonumber(patch) }
end

local function compare_versions(left, right)
  left, right = version_parts(left), version_parts(right)
  if not left or not right then
    return nil
  end
  for index = 1, 3 do
    if left[index] ~= right[index] then
      return left[index] < right[index] and -1 or 1
    end
  end
  return 0
end

function M.version_supported(value, minimum, maximum_exclusive)
  local minimum_comparison = compare_versions(value, minimum)
  if minimum_comparison == nil or minimum_comparison < 0 then
    return false
  end
  if maximum_exclusive then
    local maximum_comparison = compare_versions(value, maximum_exclusive)
    if maximum_comparison == nil or maximum_comparison >= 0 then
      return false
    end
  end
  return true
end

local function version_at_least(value, minimum)
  return M.version_supported(value, minimum)
end

function M.command_version_status(constraint, runner)
  runner = runner or command_result
  local ok, result = pcall(runner, constraint.command, 3000)
  if not ok or type(result) ~= 'table' or result.code ~= 0 then
    return { supported = false }
  end
  local output = vim.trim(table.concat { result.stdout or '', result.stderr or '' })
  local version = output:match(constraint.pattern)
  return {
    version = version,
    supported = M.version_supported(version, constraint.minimum, constraint.maximum_exclusive),
  }
end

function M.python_venv_capability(executable_name, dependencies)
  dependencies = dependencies or {}
  local tempname = dependencies.tempname or vim.fn.tempname
  local delete = dependencies.delete or function(path)
    return vim.fn.delete(path, 'rf')
  end
  local run = dependencies.run or command_result
  local path = tempname()
  local ok, result = pcall(run, { executable_name, '-m', 'venv', path }, 30000)
  pcall(delete, path)
  return ok and type(result) == 'table' and result.code == 0
end

local function default_version(_, constraint)
  return M.command_version_status(constraint)
end

local function default_capability(_, capability)
  if capability.kind == 'python_venv' then
    return { available = M.python_venv_capability(capability.executable) }
  elseif capability.kind == 'command' then
    local result = command_result(capability.command, 3000)
    return { available = result ~= nil and result.code == 0 }
  elseif capability.kind == 'command_version' then
    local status = M.command_version_status(capability)
    status.available = status.supported
    return status
  end
  return { available = false }
end

local function default_probe()
  local installed_parsers
  return {
    manifest = require 'nv_ide.toolchain.manifest',
    system = function()
      local uname, version = vim.uv.os_uname(), vim.version()
      return {
        os = uname.sysname,
        arch = uname.machine,
        nvim = ('%d.%d.%d'):format(version.major, version.minor, version.patch),
      }
    end,
    executable = executable,
    version = default_version,
    capability = default_capability,
    mason_status = default_mason_status,
    parser_status = function(name)
      if not installed_parsers then
        installed_parsers = {}
        local ok, parsers = pcall(function()
          return require('nvim-treesitter.config').get_installed 'parsers'
        end)
        if ok then
          for _, parser in ipairs(parsers) do
            installed_parsers[parser] = true
          end
        end
      end
      return default_parser_status(name, installed_parsers)
    end,
    treesitter_cli_version = default_treesitter_cli_version,
    toolchain_state = function()
      local ok, state = pcall(function()
        return require('nv_ide.toolchain.state').new():read()
      end)
      return ok and state or nil
    end,
    watcher = default_watcher,
    clipboard = default_clipboard,
    backend_available = default_backend,
    credential = function(name)
      return vim.env[name]
    end,
  }
end

local function platform_applies(record, system)
  if type(record.platform) ~= 'table' then
    return true
  end
  if record.platform.os and record.platform.os ~= system.os then
    return false
  end
  if type(record.platform.arches) == 'table' and not vim.tbl_contains(record.platform.arches, system.arch) then
    return false
  end
  return true
end

local function dependency(record, probe, required, system)
  if not platform_applies(record, system) then
    return {
      id = record.id,
      required = false,
      available = true,
      applicable = false,
      any = record.any == true,
      executables = {},
    }
  end
  local executables, available = {}, record.any ~= true
  for _, name in ipairs(record.executables) do
    local present = probe.executable(name) == true
    executables[#executables + 1] = { name = name, available = present }
    if record.any then
      available = available or present
    else
      available = available and present
    end
  end
  local result = {
    id = record.id,
    required = required == true,
    available = available,
    applicable = true,
    any = record.any == true,
    executables = executables,
  }
  if record.version then
    local ok, observed = pcall(probe.version or default_version, record.id, record.version)
    observed = ok and type(observed) == 'table' and observed or {}
    result.version = type(observed.version) == 'string' and observed.version or nil
    result.version_supported = observed.supported == true
    result.minimum_version = record.version.minimum
    result.maximum_version_exclusive = record.version.maximum_exclusive
    result.available = result.available and result.version_supported
  end
  if record.capabilities then
    result.capabilities = {}
    for _, capability in ipairs(record.capabilities) do
      local ok, observed = pcall(probe.capability or default_capability, record.id, capability)
      local capability_available = ok and type(observed) == 'table' and observed.available == true
      result.capabilities[#result.capabilities + 1] = {
        id = capability.id,
        available = capability_available,
        version = type(observed.version) == 'string' and observed.version or nil,
        supported = observed.supported == true,
        minimum_version = capability.minimum,
        maximum_version_exclusive = capability.maximum_exclusive,
      }
      result.available = result.available and capability_available
    end
  end
  return result
end

local function sanitize_watcher(value)
  value = type(value) == 'table' and value or {}
  local inotify = type(value.inotify) == 'table' and value.inotify or nil
  return {
    supported = value.supported == true,
    backend = tostring(value.backend or 'unknown'),
    inotify = inotify and {
      max_user_watches = tonumber(inotify.max_user_watches),
      max_user_instances = tonumber(inotify.max_user_instances),
      sufficient = inotify.sufficient == true,
    } or nil,
  }
end

local function sanitize_clipboard(value)
  value = type(value) == 'table' and value or {}
  local tmux = type(value.tmux) == 'table' and value.tmux or {}
  local local_providers = type(value.local_providers) == 'table' and value.local_providers or {}
  return {
    session = value.session == 'ssh' and 'ssh' or 'local',
    provider = tostring(value.provider or 'none'),
    available = value.available == true,
    tmux = {
      active = tmux.active == true,
      set_clipboard = tostring(tmux.set_clipboard or 'unknown'),
      ms = tmux.ms == true,
    },
    local_providers = {
      pbcopy = local_providers.pbcopy == true,
      wl_copy = local_providers.wl_copy == true,
      xclip = local_providers.xclip == true,
      xsel = local_providers.xsel == true,
    },
  }
end

local MASON_STATUSES = {
  failed = true,
  installed = true,
  installing = true,
  missing = true,
  unknown = true,
}

local function mason_record(name, probe)
  local value
  if probe.mason_status then
    local ok, result = pcall(probe.mason_status, name)
    value = ok and type(result) == 'table' and result or { status = 'unknown' }
  else
    local ok, installed = pcall(probe.mason_installed, name)
    value = { status = ok and installed == true and 'installed' or 'missing' }
  end
  local status = MASON_STATUSES[value.status] and value.status or 'unknown'
  return {
    id = name,
    required = true,
    available = status == 'installed',
    status = status,
    version = value.version and tostring(value.version) or nil,
  }
end

local function parser_record(name, probe)
  local value
  if probe.parser_status then
    local ok, result = pcall(probe.parser_status, name)
    value = ok and type(result) == 'table' and result or { status = 'unknown' }
  else
    local ok, installed = pcall(probe.parser_installed, name)
    value = { status = ok and installed == true and 'installed' or 'missing' }
  end
  local status = value.status == 'installed' and 'installed' or value.status == 'missing' and 'missing' or value.status == 'failed' and 'failed' or 'unknown'
  return {
    id = name,
    required = true,
    available = status == 'installed',
    status = status,
    revision = value.revision and tostring(value.revision) or nil,
  }
end

local PREREQUISITE_FIXES = {
  Darwin = {
    archive = 'brew install unzip',
    bash = 'brew install bash',
    c_compiler = 'xcode-select --install',
    curl = 'brew install curl',
    delta = 'brew install git-delta',
    git = 'brew install git',
    gzip = 'brew install gzip',
    just = 'brew install just',
    lua_package_manager = 'brew install luarocks',
    ripgrep = 'brew install ripgrep',
    ruby_package_manager = 'brew install ruby; add Homebrew Ruby to PATH so gem is available',
    snacks_image_ghostscript = 'brew install ghostscript',
    snacks_image_latex = 'brew install tectonic',
    snacks_image_mermaid = 'npm install --global @mermaid-js/mermaid-cli',
    snacks_image_raster = 'brew install imagemagick',
    tree_sitter_cli = 'brew install tree-sitter-cli',
  },
  Linux = {
    archive = 'Debian/Ubuntu: sudo apt install tar unzip; Fedora: sudo dnf install tar unzip; Arch: sudo pacman -S tar unzip',
    bash = 'Debian/Ubuntu: sudo apt install bash; Fedora: sudo dnf install bash; Arch: sudo pacman -S bash',
    c_compiler = 'Debian/Ubuntu: sudo apt install build-essential; Fedora: sudo dnf group install development-tools; Arch: sudo pacman -S base-devel',
    curl = 'Debian/Ubuntu: sudo apt install curl; Fedora: sudo dnf install curl; Arch: sudo pacman -S curl',
    delta = 'Debian/Ubuntu: install the release .deb from https://github.com/dandavison/delta/releases; Fedora: sudo dnf install git-delta; Arch: sudo pacman -S git-delta; Cargo: cargo install git-delta',
    git = 'Debian/Ubuntu: sudo apt install git; Fedora: sudo dnf install git; Arch: sudo pacman -S git',
    gzip = 'Debian/Ubuntu: sudo apt install gzip; Fedora: sudo dnf install gzip; Arch: sudo pacman -S gzip',
    just = 'Debian 13/Ubuntu 24.04+: sudo apt install just; Fedora: sudo dnf install just; Arch: sudo pacman -S just; Cargo: cargo install just',
    lua_package_manager = 'Debian/Ubuntu: sudo apt install luarocks; Fedora: sudo dnf install luarocks; Arch: sudo pacman -S luarocks',
    ripgrep = 'Debian/Ubuntu: sudo apt install ripgrep; Fedora: sudo dnf install ripgrep; Arch: sudo pacman -S ripgrep',
    ruby_package_manager = 'Debian/Ubuntu: sudo apt install ruby-dev; Fedora: sudo dnf install ruby-devel; Arch: sudo pacman -S ruby (gem is included)',
    snacks_image_ghostscript = 'Debian/Ubuntu: sudo apt install ghostscript; Fedora: sudo dnf install ghostscript; Arch: sudo pacman -S ghostscript',
    snacks_image_latex = 'Install tectonic or a TeX distribution with pdflatex using your Linux package manager',
    snacks_image_mermaid = 'npm install --global @mermaid-js/mermaid-cli',
    snacks_image_raster = 'Debian/Ubuntu: sudo apt install imagemagick; Fedora: sudo dnf install ImageMagick; Arch: sudo pacman -S imagemagick',
    tree_sitter_cli = 'cargo install tree-sitter-cli --version 0.26.3 --locked',
  },
}

local RUNTIME_FIXES = {
  Darwin = {
    ansible = 'brew install ansible',
    cmake = 'brew install cmake ninja',
    containers = 'brew install podman',
    dart = 'brew install --cask flutter',
    go = 'brew install go; verify that go version reports >= 1.26.0',
    java = 'brew install openjdk@21 maven gradle; ensure java and javac both report >= 21.0.0',
    javascript = 'brew install node; verify that node --version reports >= 24.15.0',
    kotlin = 'brew install kotlin',
    lua = 'brew install lua luajit',
    python = 'brew install python@3.13; verify with python3 --version and python3 -m venv /tmp/nv-ide-venv-test',
    r = 'brew install --cask r',
    ruby = "brew install ruby; ensure Homebrew Ruby's bin is before /usr/bin, ruby reports >= 3.0.0, RbConfig rubyhdrdir contains ruby.h, and Xcode Command Line Tools provide a C compiler",
    rust = 'brew install rustup-init && rustup-init -y',
    scala = 'brew install scala sbt',
    sql = 'brew install libpq',
    terraform = 'brew tap hashicorp/tap && brew install hashicorp/tap/terraform',
  },
  Linux = {
    ansible = 'Debian/Ubuntu: sudo apt install ansible; Fedora: sudo dnf install ansible; Arch: sudo pacman -S ansible',
    cmake = 'Debian/Ubuntu: sudo apt install cmake ninja-build; Fedora: sudo dnf install cmake ninja-build; Arch: sudo pacman -S cmake ninja',
    containers = 'Debian/Ubuntu: sudo apt install podman; Fedora: sudo dnf install podman; Arch: sudo pacman -S podman',
    dart = 'asdf plugin add flutter && asdf install flutter latest && asdf set -u flutter latest',
    go = 'Install Go >= 1.26.0 from https://go.dev/doc/install, then verify with: go version',
    java = 'Debian/Ubuntu: sudo apt install openjdk-21-jdk maven gradle; Fedora: sudo dnf install java-21-openjdk-devel maven gradle; Arch: sudo pacman -S jdk21-openjdk maven gradle; ensure java and javac both report >= 21.0.0',
    javascript = 'Install Node.js >= 24.15.0 with npm from https://nodejs.org/en/download, then verify with: node --version && npm --version',
    kotlin = 'curl -s https://get.sdkman.io | bash && sdk install kotlin',
    lua = 'Debian/Ubuntu: sudo apt install lua5.4 luajit; Fedora: sudo dnf install lua luajit; Arch: sudo pacman -S lua luajit',
    python = 'Install Python 3.10-3.13 with venv support; Debian/Ubuntu: sudo apt install python3 python3-venv; Fedora: sudo dnf install python3; Arch: sudo pacman -S python; verify with python3 -m venv /tmp/nv-ide-venv-test',
    r = 'Debian/Ubuntu: sudo apt install r-base; Fedora: sudo dnf install R; Arch: sudo pacman -S r',
    ruby = 'Install Ruby >= 3.0 with gem, Bundler, development headers, and a C compiler; Debian/Ubuntu: sudo apt install build-essential ruby-full ruby-dev; Fedora: sudo dnf install gcc ruby ruby-devel; Arch: sudo pacman -S base-devel ruby',
    rust = 'curl --proto =https --tlsv1.2 -sSf https://sh.rustup.rs | sh',
    scala = 'curl -fL https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz | gzip -d > cs && chmod +x cs && ./cs setup',
    sql = 'Debian/Ubuntu: sudo apt install postgresql-client; Fedora: sudo dnf install postgresql; Arch: sudo pacman -S postgresql-libs',
    terraform = 'Install from https://developer.hashicorp.com/terraform/install, then verify with: terraform version',
  },
}

local EXTERNAL_FIXES = {
  Darwin = {
    btop = 'brew install btop',
    cloudlens = 'brew install one2nc/cloudlens/cloudlens',
    clx = 'brew install circumflex',
    dua = 'brew install dua-cli',
    ['euporie-notebook'] = 'uv tool install euporie',
    ['glab-tui'] = 'go install github.com/rkristelijn/glab-tui@latest',
    harlequin = 'uv tool install harlequin',
    jshell = 'brew install openjdk',
    k9s = 'brew install derailed/k9s/k9s',
    lazydocker = 'brew install lazydocker',
    nap = 'brew install nap',
    omm = 'brew install dhth/tap/omm',
    ['podman-tui'] = 'brew install podman-tui',
    posting = 'uv tool install posting',
    python3 = 'brew install python',
    termscp = 'curl --proto =https --tlsv1.2 -sSLf https://git.io/JBhDb | sh',
    tiki = 'go install github.com/boolean-maybe/tiki@latest',
    zellij = 'brew install zellij',
  },
  Linux = {
    btop = 'Debian/Ubuntu: sudo apt install btop; Fedora: sudo dnf install btop; Arch: sudo pacman -S btop',
    cloudlens = 'brew install one2nc/cloudlens/cloudlens (Linuxbrew)',
    clx = 'go install github.com/bensadeh/circumflex/cmd/clx@latest',
    dua = 'cargo install dua-cli',
    ['euporie-notebook'] = 'uv tool install euporie',
    ['glab-tui'] = 'go install github.com/rkristelijn/glab-tui@latest',
    harlequin = 'uv tool install harlequin',
    jshell = 'Debian/Ubuntu: sudo apt install openjdk-21-jdk; Fedora: sudo dnf install java-21-openjdk-devel; Arch: sudo pacman -S jdk21-openjdk',
    k9s = 'brew install derailed/k9s/k9s (Linuxbrew) or use https://k9scli.io/topics/install',
    lazydocker = 'go install github.com/jesseduffield/lazydocker@latest',
    nap = 'go install github.com/maaslalani/nap@main',
    omm = 'brew install dhth/tap/omm (Linuxbrew)',
    ['podman-tui'] = 'brew install podman-tui (Linuxbrew)',
    posting = 'uv tool install posting',
    python3 = 'Debian/Ubuntu: sudo apt install python3; Fedora: sudo dnf install python3; Arch: sudo pacman -S python',
    termscp = 'curl --proto =https --tlsv1.2 -sSLf https://git.io/JBhDb | sh',
    tiki = 'go install github.com/boolean-maybe/tiki@latest',
    zellij = 'cargo install --locked zellij',
  },
}

local AI_FIXES = {
  cli = {
    claude = 'npm install --global @anthropic-ai/claude-code',
    cline = 'npm install --global cline',
    codex = 'npm install --global @openai/codex',
  },
  backend = {
    Darwin = { ollama = 'brew install ollama' },
    Linux = { ollama = 'curl -fsSL https://ollama.com/install.sh | sh' },
  },
}

local function prerequisite_fix(record, os_name)
  local platform = PREREQUISITE_FIXES[os_name]
  if platform and platform[record.id] then
    return platform[record.id]
  end
  return 'Install ' .. table.concat(
    vim.tbl_map(function(item)
      return item.name
    end, record.executables),
    ', '
  )
end

local function dependency_fix(record, kind, os_name)
  if kind == 'prerequisite' then
    return prerequisite_fix(record, os_name)
  elseif kind == 'mason' then
    if record.status == 'installing' then
      return 'Wait for installation to finish, then rerun :checkhealth nv_ide'
    end
    return 'Run :ToolchainRepair!; inspect :Mason and :MasonLog if the managed retry fails'
  elseif kind == 'parser' then
    return 'Run :ToolchainRepair! so the single toolchain owner repairs parser state'
  elseif kind == 'runtime' then
    local platform = RUNTIME_FIXES[os_name] or {}
    return platform[record.id] or ('Install the %s runtime and place its executables on PATH'):format(record.id)
  elseif kind == 'external' then
    local platform = EXTERNAL_FIXES[os_name] or {}
    return platform[record.id] or ('Install %s from its upstream project and place it on PATH'):format(record.executable)
  elseif kind == 'ai_cli' then
    return AI_FIXES.cli[record.id] or ('Install %s and place it on PATH'):format(record.id)
  elseif kind == 'ai_backend' then
    local platform = AI_FIXES.backend[os_name] or {}
    return platform[record.id] or ('Install and start %s, then verify %s'):format(record.executable, record.url)
  end
end

local function safe_observed_value(value)
  if type(value) == 'number' then
    value = tostring(value)
  elseif type(value) ~= 'string' then
    value = nil
  end
  if not value or #value > 128 or not value:match '^[%w%._%+%-]+$' then
    return nil
  end
  return value
end

local function observed_inventory(value, allowed)
  local result = {}
  if type(value) ~= 'table' then
    return result
  end
  for name, observed in pairs(value) do
    if allowed[name] then
      local safe = safe_observed_value(observed)
      if safe then
        result[name] = safe
      end
    end
  end
  return result
end

local function sanitize_update(value, manifest)
  local update = type(value) == 'table' and value.plugin_update or nil
  if type(update) ~= 'table' then
    return nil
  end
  local mason, parsers = {}, {}
  for _, name in ipairs(manifest.mason.packages) do
    mason[name] = true
  end
  for _, name in ipairs(manifest.treesitter.parsers) do
    parsers[name] = true
  end

  local observed = type(update.observed) == 'table' and update.observed or {}
  local function side(name)
    local data = type(observed[name]) == 'table' and observed[name] or {}
    return {
      mason_receipts = observed_inventory(data.mason_receipts, mason),
      treesitter_parser_info = observed_inventory(data.treesitter_parser_info, parsers),
    }
  end
  local statuses = { failed = true, running = true, success = true }
  return {
    status = statuses[update.status] and update.status or 'unknown',
    observed = { before = side 'before', after = side 'after' },
    rollback = {
      lazy = 'exact',
      mason = 'not-guaranteed',
      treesitter = 'not-guaranteed',
      limitation = 'Only Lazy rollback is exact; Mason and parser exact downgrades are not guaranteed',
    },
  }
end

function M.collect(probe)
  probe = probe or default_probe()
  local manifest = probe.manifest or require 'nv_ide.toolchain.manifest'
  local report = {
    system = probe.system(),
    prerequisites = {},
    mason = {},
    parsers = {},
    treesitter = { cli = { available = false } },
    runtimes = {},
    external_actions = {},
    watcher = sanitize_watcher(probe.watcher()),
    clipboard = sanitize_clipboard(probe.clipboard()),
    ai = { cli = {}, backends = {}, credentials = {} },
  }
  report.system.nvim_supported = M.version_supported(report.system.nvim, '0.12.0')

  local state_ok, state = pcall(probe.toolchain_state or function()
    return nil
  end)
  report.update = sanitize_update(state_ok and state or nil, manifest)

  local cli_ok, cli_version = pcall(probe.treesitter_cli_version or function()
    return nil
  end)
  report.treesitter.cli = {
    available = probe.executable 'tree-sitter' == true,
    version = cli_ok and cli_version and tostring(cli_version) or nil,
  }
  report.treesitter.cli.supported = report.treesitter.cli.available and version_at_least(report.treesitter.cli.version, '0.26.1')

  for _, record in ipairs(manifest.prerequisites) do
    report.prerequisites[#report.prerequisites + 1] = dependency(record, probe, record.required, report.system)
  end
  for _, name in ipairs(manifest.mason.packages) do
    report.mason[#report.mason + 1] = mason_record(name, probe)
  end
  for _, name in ipairs(manifest.treesitter.parsers) do
    report.parsers[#report.parsers + 1] = parser_record(name, probe)
  end
  for _, record in ipairs(manifest.runtimes) do
    report.runtimes[#report.runtimes + 1] = dependency(record, probe, record.optional ~= true, report.system)
  end
  for _, action in ipairs(manifest.external_actions) do
    report.external_actions[#report.external_actions + 1] = {
      id = action.id,
      required = false,
      available = probe.executable(action.command[1]) == true,
      executable = action.command[1],
    }
  end
  for _, name in ipairs(manifest.ai.cli) do
    report.ai.cli[#report.ai.cli + 1] = {
      id = name,
      required = false,
      available = probe.executable(name) == true,
    }
  end
  for _, backend in ipairs(manifest.ai.backends) do
    report.ai.backends[#report.ai.backends + 1] = {
      id = backend.id,
      required = false,
      available = probe.backend_available(backend) == true,
      executable = backend.executable,
      url = backend.url,
    }
  end
  for _, name in ipairs(manifest.ai.credentials) do
    local value = probe.credential(name)
    report.ai.credentials[#report.ai.credentials + 1] = {
      id = name,
      required = false,
      present = value ~= nil and tostring(value) ~= '',
    }
  end
  return report
end

local function render_observed(reporter, records)
  local observed = {}
  for _, record in ipairs(records) do
    local value = record.version or record.revision
    if record.available and value then
      observed[#observed + 1] = ('%s@%s'):format(record.id, value)
    end
  end
  for index = 1, #observed, 8 do
    reporter.info('Observed: ' .. table.concat(observed, ', ', index, math.min(index + 7, #observed)))
  end
end

local function render_records(reporter, title, records, options)
  options = options or {}
  reporter.start(title)
  local missing = {}
  for _, record in ipairs(records) do
    if not record.available then
      missing[#missing + 1] = record
    end
  end
  if #missing == 0 then
    reporter.ok(('%d dependencies available'):format(#records))
    render_observed(reporter, records)
    return
  end
  reporter.info(('%d/%d dependencies available'):format(#records - #missing, #records))
  for _, record in ipairs(missing) do
    local detail = record.executables and vim.tbl_map(function(item)
      return item.name
    end, record.executables) or nil
    local state = record.status and (' [%s]'):format(record.status) or ''
    local message = detail and ('%s%s (%s)'):format(record.id, state, table.concat(detail, ', ')) or record.id .. state
    local constraints = {}
    if record.minimum_version and not record.version_supported then
      local labels = {
        git = 'Git',
        go = 'Go',
        java = 'Java',
        javascript = 'Node.js',
        python = 'Python',
        ruby = 'Ruby',
        rust = 'Rust',
      }
      local requirement = ('%s %s requires >= %s'):format(
        labels[record.id] or record.id,
        record.version or 'version unknown',
        record.minimum_version
      )
      if record.maximum_version_exclusive then
        requirement = requirement .. ' and < ' .. record.maximum_version_exclusive
      end
      constraints[#constraints + 1] = requirement
    end
    for _, capability in ipairs(record.capabilities or {}) do
      if capability.minimum_version and not capability.supported then
        local labels = { cargo_version = 'cargo', javac_version = 'javac' }
        local requirement = ('%s %s requires >= %s'):format(
          labels[capability.id] or capability.id,
          capability.version or 'version unknown',
          capability.minimum_version
        )
        if capability.maximum_version_exclusive then
          requirement = requirement .. ' and < ' .. capability.maximum_version_exclusive
        end
        constraints[#constraints + 1] = requirement
      elseif not capability.available then
        local labels = { python = 'Python', ruby = 'Ruby' }
        constraints[#constraints + 1] = ('%s %s capability is unavailable'):format(
          labels[record.id] or record.id,
          capability.id
        )
      end
    end
    if #constraints > 0 then
      message = message .. ': ' .. table.concat(constraints, '; ')
    end
    local fix = dependency_fix(record, options.kind, options.os)
    if fix then
      message = message .. '. Fix: ' .. fix
    end
    local level = record.status == 'installing' and 'warn' or record.required and 'error' or 'warn'
    reporter[level](message)
  end
  render_observed(reporter, records)
end

local function render_observed_update(reporter, label, value)
  local parts = {}
  for name, version in pairs(value or {}) do
    parts[#parts + 1] = ('%s@%s'):format(name, version)
  end
  table.sort(parts)
  if #parts > 0 then
    reporter.info(('%s: %s'):format(label, table.concat(parts, ', ')))
  end
end

function M.check(probe, reporter)
  reporter = reporter or vim.health
  local report = M.collect(probe)

  reporter.start 'nv_ide system'
  local system_message = ('Neovim %s on %s/%s'):format(report.system.nvim, report.system.os, report.system.arch)
  if report.system.nvim_supported then
    reporter.info(system_message)
  else
    reporter.error(
      system_message
        .. '. NV-IDE requires Neovim >= 0.12.0. Fix: install a supported release from https://neovim.io/doc/install/'
    )
  end
  render_records(reporter, 'Required and optional prerequisites', report.prerequisites, {
    kind = 'prerequisite',
    os = report.system.os,
  })

  reporter.start 'Tree-sitter CLI'
  if report.treesitter.cli.supported then
    reporter.ok('Tree-sitter CLI ' .. report.treesitter.cli.version)
  elseif report.treesitter.cli.available and report.treesitter.cli.version then
    reporter.error(
      ('Tree-sitter CLI %s is unsupported; NV-IDE requires >= 0.26.1. Fix: %s'):format(
        report.treesitter.cli.version,
        prerequisite_fix({ id = 'tree_sitter_cli', executables = { { name = 'tree-sitter' } } }, report.system.os)
      )
    )
  elseif report.treesitter.cli.available then
    reporter.warn 'Tree-sitter CLI is executable, but its version could not be determined'
  else
    reporter.error('Tree-sitter CLI unavailable. Fix: ' .. prerequisite_fix({
      id = 'tree_sitter_cli',
      executables = { { name = 'tree-sitter' } },
    }, report.system.os))
  end

  render_records(reporter, 'Mason packages', report.mason, { kind = 'mason', os = report.system.os })
  render_records(reporter, 'Tree-sitter parsers', report.parsers, { kind = 'parser', os = report.system.os })
  render_records(reporter, 'Language runtimes', report.runtimes, { kind = 'runtime', os = report.system.os })
  render_records(reporter, 'External terminal actions', report.external_actions, {
    kind = 'external',
    os = report.system.os,
  })

  reporter.start 'File watching'
  if report.watcher.supported then
    reporter.ok('filesystem event watcher available: ' .. report.watcher.backend)
  else
    local fix = report.system.os == 'Darwin' and 'brew reinstall neovim, then rerun :checkhealth nv_ide'
      or report.system.os == 'Linux' and 'install a Neovim build with libuv/inotify support, then rerun :checkhealth nv_ide'
      or 'install a Neovim build with libuv filesystem-event support'
    reporter.warn('filesystem event watcher unavailable. Fix: ' .. fix)
  end
  if report.watcher.inotify then
    local inotify = report.watcher.inotify
    local message = ('inotify watches=%s instances=%s'):format(
      tostring(inotify.max_user_watches or 'unknown'),
      tostring(inotify.max_user_instances or 'unknown')
    )
    if inotify.sufficient then
      reporter.ok(message)
    else
      reporter.warn(
        message
          .. '. Fix now: sudo sysctl -w fs.inotify.max_user_watches=524288 fs.inotify.max_user_instances=128; '
          .. 'persist both values under /etc/sysctl.d/99-nvim.conf'
      )
    end
  end

  reporter.start 'Clipboard'
  if report.clipboard.available then
    reporter.ok(('%s provider: %s'):format(report.clipboard.session, report.clipboard.provider))
  else
    local fix
    if report.clipboard.session == 'ssh' then
      fix = 'verify terminal OSC 52 support and reconnect SSH so NV-IDE can select its OSC 52 provider'
    elseif report.system.os == 'Darwin' then
      fix = 'restore /usr/bin to PATH; pbcopy and pbpaste are provided by macOS'
    elseif report.system.os == 'Linux' then
      fix = 'Wayland: sudo apt install wl-clipboard; X11: sudo apt install xclip or sudo apt install xsel'
    else
      fix = 'install a clipboard provider supported by :help clipboard-tool'
    end
    reporter.warn(('%s clipboard provider unavailable. Fix: %s'):format(report.clipboard.session, fix))
  end
  local osc52 = report.clipboard.session == 'ssh' or report.clipboard.provider:lower():find('osc 52', 1, true) ~= nil
  if osc52 and report.clipboard.tmux.active and report.clipboard.tmux.set_clipboard ~= 'on' then
    reporter.warn "tmux set-clipboard is not on. Fix: add 'set -s set-clipboard on' to ~/.tmux.conf, then run: tmux set -s set-clipboard on"
  end
  if osc52 and report.clipboard.tmux.active and not report.clipboard.tmux.ms then
    reporter.warn 'tmux lacks the Ms clipboard capability. Fix: add "set -as terminal-features \',*:clipboard\'" to ~/.tmux.conf, then restart tmux'
  end

  reporter.start 'Update and rollback evidence'
  if report.update then
    reporter.info('Last plugin update status: ' .. report.update.status)
    reporter.warn(report.update.rollback.limitation)
    render_observed_update(reporter, 'Mason before', report.update.observed.before.mason_receipts)
    render_observed_update(reporter, 'Mason after', report.update.observed.after.mason_receipts)
    render_observed_update(reporter, 'Parsers before', report.update.observed.before.treesitter_parser_info)
    render_observed_update(reporter, 'Parsers after', report.update.observed.after.treesitter_parser_info)
  else
    reporter.info 'No persisted plugin update evidence is available yet'
    reporter.warn 'Only Lazy rollback is exact; Mason and parser exact downgrades are not guaranteed'
  end

  render_records(reporter, 'AI CLI agents', report.ai.cli, { kind = 'ai_cli', os = report.system.os })
  render_records(reporter, 'AI backends', report.ai.backends, { kind = 'ai_backend', os = report.system.os })
  reporter.start 'AI credentials'
  for _, credential in ipairs(report.ai.credentials) do
    reporter.info(('%s: %s'):format(credential.id, credential.present and 'present' or 'missing'))
    if not credential.present then
      reporter.info(('Set %s in your trusted shell or project environment; health never reads it back aloud'):format(credential.id))
    end
  end
  return report
end

return M
