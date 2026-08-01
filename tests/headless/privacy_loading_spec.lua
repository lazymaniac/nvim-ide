local h = require('tests.headless.harness')

local function plugin(specs, name)
  for _, spec in ipairs(specs) do
    if spec[1] == name then return spec end
  end
  error('plugin spec not found: ' .. name)
end

h.describe('AI privacy boundary', function()
  h.it('uses quiet, code-private defaults and disables unchecked project loading', function()
    local spec = plugin(dofile('lua/plugins/ai.lua'), 'olimorris/codecompanion.nvim')

    h.equal(spec.opts.opts.log_level, 'ERROR')
    h.falsy(spec.opts.opts.send_code)
    h.falsy(spec.opts.opts.per_project_config.enabled)
    h.truthy(spec.opts.adapters.http.ollama, 'the local Ollama adapter must remain available by default')
    h.falsy(spec.opts.adapters.http.anthropic, 'remote HTTP adapters must not be enabled globally')
  end)

  h.it('ignores an untrusted project override without evaluating it', function()
    local resolver = require('nv_ide.codecompanion')
    local evaluated = false
    local base = { opts = { send_code = false }, marker = 'base' }
    local resolved = resolver.resolve(base, {
      cwd = '/workspace/project',
      secure_read = function(path)
        h.equal(path, '/workspace/project/.codecompanion.lua')
        return nil
      end,
      evaluate = function()
        evaluated = true
        return { marker = 'project' }
      end,
    })

    h.equal(resolved.marker, 'base')
    h.falsy(evaluated, 'untrusted project configuration must never execute')
  end)

  h.it('merges a project override only after Neovim returns trusted contents', function()
    local resolver = require('nv_ide.codecompanion')
    local trusted_source = 'return { adapters = { http = { anthropic = {} } } }'
    local resolved = resolver.resolve({
      adapters = { http = { ollama = {} } },
      opts = { send_code = false },
    }, {
      cwd = '/workspace/project',
      secure_read = function() return trusted_source end,
    })

    h.truthy(resolved.adapters.http.ollama)
    h.truthy(resolved.adapters.http.anthropic)
    h.falsy(resolved.opts.send_code)
  end)

  h.it('rejects malformed trusted project configuration', function()
    local resolver = require('nv_ide.codecompanion')

    h.raises('must return a table', function()
      resolver.resolve({}, {
        cwd = '/workspace/project',
        secure_read = function() return 'return "not a table"' end,
      })
    end)
    h.raises('failed to compile trusted CodeCompanion config', function()
      resolver.resolve({}, {
        cwd = '/workspace/project',
        secure_read = function() return 'return {' end,
      })
    end)
  end)
end)
