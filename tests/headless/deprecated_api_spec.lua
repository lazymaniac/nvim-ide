local h = require('tests.headless.harness')

local forbidden = {
  { needle = 'vim.loop', label = 'vim.loop' },
  { needle = 'vim.diagnostic.goto_next', label = 'vim.diagnostic.goto_next' },
  { needle = 'vim.diagnostic.goto_prev', label = 'vim.diagnostic.goto_prev' },
  { needle = 'vim.tbl_flatten', label = 'vim.tbl_flatten' },
  { needle = '/Users/sebastian', label = 'personal macOS path' },
  { needle = '/home/seba', label = 'personal Linux path' },
  { needle = '/bin/zsh', label = 'forced zsh path' },
  { needle = '~/.config/nvim', label = 'literal Neovim config path' },
}

local function executable_lua_files()
  local files = vim.fn.glob('lua/**/*.lua', false, true)
  files[#files + 1] = 'init.lua'
  table.sort(files)
  return files
end

h.describe('Neovim 0.12 portability', function()
  h.it('contains no deprecated APIs or machine-specific paths in executable Lua', function()
    local matches = {}
    for _, path in ipairs(executable_lua_files()) do
      local lines = vim.fn.readfile(path)
      for line_number, line in ipairs(lines) do
        for _, item in ipairs(forbidden) do
          if line:find(item.needle, 1, true) then
            matches[#matches + 1] = ('%s:%d: %s'):format(path, line_number, item.label)
          end
        end
      end
    end

    h.equal(#matches, 0, table.concat(matches, '\n'))
  end)

  h.it('discovers Java paths from the environment and Neovim directories', function()
    local java = require('nv_ide.java')
    local discovered = java.discover {
      env = { JAVA_HOME = '/opt/jdk-21', MASON = '/xdg/mason' },
      exepath = function(command)
        if command == 'java' then return '/opt/jdk-21/bin/java' end
        if command == 'jdtls' then return '/xdg/mason/bin/jdtls' end
        return ''
      end,
      stdpath = function(kind)
        if kind == 'config' then return '/xdg/config/nvim' end
        return '/xdg/data/nvim'
      end,
      realpath = function(path) return path end,
      read_file = function(path)
        if path == '/opt/jdk-21/release' then return 'JAVA_VERSION="21.0.7"' end
      end,
    }

    h.equal(discovered.java_home, '/opt/jdk-21')
    h.equal(discovered.jdtls, '/xdg/mason/bin/jdtls')
    h.equal(discovered.lombok, '/xdg/mason/share/jdtls/lombok.jar')
    h.equal(discovered.formatter, '/xdg/config/nvim/java-formatter.xml')
    h.deep_equal(discovered.runtimes, {
      { name = 'JavaSE-21', path = '/opt/jdk-21', default = true },
    })
  end)

  h.it('falls back to the resolved java executable when JAVA_HOME is absent', function()
    local java = require('nv_ide.java')
    local discovered = java.discover {
      env = {},
      exepath = function(command)
        return command == 'java' and '/toolchains/jdk-17/bin/java' or ''
      end,
      stdpath = function(kind) return '/xdg/' .. kind end,
      realpath = function(path) return path end,
      read_file = function(path)
        if path == '/toolchains/jdk-17/release' then return 'JAVA_VERSION="17.0.12"' end
      end,
    }

    h.equal(discovered.java_home, '/toolchains/jdk-17')
    h.equal(discovered.runtimes[1].name, 'JavaSE-17')
  end)

  h.it('keeps tracked shell fragments free of personal home paths', function()
    for _, path in ipairs({ 'dotfiles/.zprofile', 'dotfiles/.zshrc' }) do
      local source = table.concat(vim.fn.readfile(path), '\n')
      h.falsy(source:find('/Users/sebastian', 1, true), path)
      h.falsy(source:find('/home/seba', 1, true), path)
      h.truthy(source:find('$HOME', 1, true), path .. ' must derive user paths from HOME')
    end
  end)
end)
