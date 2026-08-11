local config = {
  adapters = {
    http = {
      opts = {
        show_presets = false,
        show_model_choices = true,
      },
      ollama = function()
        return require('codecompanion.adapters').extend('ollama', {
          schema = {
            model = {
              default = 'ornith:35b-q8_0',
            },
          },
        })
      end,
    },
    acp = {
      opts = {
        show_presets = false,
      },
    },
  },
  extensions = {
    reasoning = {
      enabled = true,
      opts = {
        auto_attach = true,
        default_depth = 'deep',
      },
    },
  },
  interactions = {
    background = {
      adapter = 'ollama',
    },
    -- CHAT STRATEGY ----------------------------------------------------------
    chat = {
      adapter = 'ollama',
      opts = {
        completion_provider = 'blink', -- blink|cmp|coc|default
      },
      roles = {
        llm = function(adapter)
          if adapter.parameters and adapter.parameters.model then
            return adapter.formatted_name .. ' (model=' .. adapter.parameters.model .. ')'
          else
            return adapter.formatted_name
          end
        end,
        user = 'Me',
      },
      tools = {
        opts = {
          default_tools = {
            'agent',
          },
        },
      },
    },
    -- INLINE STRATEGY --------------------------------------------------------
    inline = {
      adapter = 'ollama',
    },
    cmd = {
      adapter = 'ollama',
    },
    cli = {
      agent = 'claude_code',
      agents = {
        claude_code = {
          cmd = 'claude',
          args = {},
          description = 'Claude Code CLI',
          provider = 'terminal',
        },
        codex = {
          cmd = 'codex',
          args = {},
          description = 'OpenAI Codex CLI',
          provider = 'terminal',
        },
        cline = {
          cmd = 'cline',
          args = {},
          description = 'Cline CLI',
          provider = 'terminal',
        },
      },
    },
  },
  -- PROMPT LIBRARY (action palette entries) -----------------------------------
  -- Entries use mode-keyed function prompts so the palette can drive the CLI
  -- interaction, which has no dedicated palette handler.
  prompt_library = {
    ['CLI: Custom Prompt'] = {
      interaction = 'chat',
      description = 'Open input buffer and write a prompt for the CLI agent',
      opts = { index = 20 },
      prompts = {
        n = function()
          require('codecompanion').cli { prompt = true }
        end,
        v = function()
          require('codecompanion').cli { prompt = true }
        end,
      },
    },
    ['CLI: Share Buffer'] = {
      interaction = 'chat',
      description = 'Share current buffer (or selection) with the CLI agent',
      opts = { index = 21 },
      prompts = {
        n = function()
          require('codecompanion').cli('#{buffer}', { focus = false })
        end,
        v = function()
          vim.cmd 'normal! gv'
          require('codecompanion').cli('#{this}', { focus = false })
        end,
      },
    },
    ['CLI: Share Diagnostics'] = {
      interaction = 'chat',
      description = 'Share diagnostics from current buffer with the CLI agent',
      opts = { index = 22 },
      prompts = {
        n = function()
          require('codecompanion').cli('#{diagnostics}', { focus = false })
        end,
        v = function()
          require('codecompanion').cli('#{diagnostics}', { focus = false })
        end,
      },
    },
    ['CLI: Fix Diagnostics'] = {
      interaction = 'chat',
      description = 'Send diagnostics to the CLI agent and ask for a fix',
      opts = { index = 23 },
      prompts = {
        n = function()
          require('codecompanion').cli('#{diagnostics} Fix these diagnostics.', { focus = false, submit = true })
        end,
        v = function()
          require('codecompanion').cli('#{diagnostics} Fix these diagnostics.', { focus = false, submit = true })
        end,
      },
    },
    ['CLI: Share Terminal Output'] = {
      interaction = 'chat',
      description = 'Share latest terminal output with the CLI agent',
      opts = { index = 24 },
      prompts = {
        n = function()
          require('codecompanion').cli('#{terminal}', { focus = false })
        end,
        v = function()
          require('codecompanion').cli('#{terminal}', { focus = false })
        end,
      },
    },
    ['CLI: Fix Terminal Errors'] = {
      interaction = 'chat',
      description = 'Send terminal output to the CLI agent and ask for a fix',
      opts = { index = 25 },
      prompts = {
        n = function()
          require('codecompanion').cli('#{terminal} This is the latest terminal output. Investigate and fix the errors.', { focus = false, submit = true })
        end,
        v = function()
          require('codecompanion').cli('#{terminal} This is the latest terminal output. Investigate and fix the errors.', { focus = false, submit = true })
        end,
      },
    },
    ['CLI: Explain Code'] = {
      interaction = 'chat',
      description = 'Ask the CLI agent to explain buffer or selection',
      opts = { index = 26 },
      prompts = {
        n = function()
          require('codecompanion').cli('#{buffer} Explain this code.', { submit = true })
        end,
        v = function()
          vim.cmd 'normal! gv'
          require('codecompanion').cli('#{this} Explain this code.', { submit = true })
        end,
      },
    },
    ['CLI: Review Buffer'] = {
      interaction = 'chat',
      description = 'Ask the CLI agent to review buffer or selection',
      opts = { index = 28 },
      prompts = {
        n = function()
          require('codecompanion').cli(
            '#{buffer} Review this code. Point out bugs, code smells, and possible simplifications. One line per finding: location, problem, suggested fix.',
            { submit = true }
          )
        end,
        v = function()
          vim.cmd 'normal! gv'
          require('codecompanion').cli(
            '#{this} Review this code. Point out bugs, code smells, and possible simplifications. One line per finding: location, problem, suggested fix.',
            { submit = true }
          )
        end,
      },
    },
    ['CLI: Share Quickfix List'] = {
      interaction = 'chat',
      description = 'Share quickfix list items with the CLI agent',
      opts = { index = 29 },
      prompts = {
        n = function()
          require('codecompanion').cli('#{quickfix}', { focus = false })
        end,
        v = function()
          require('codecompanion').cli('#{quickfix}', { focus = false })
        end,
      },
    },
    ['CLI: Bump Dependencies'] = {
      interaction = 'chat',
      description = 'Ask the CLI agent to update project dependencies to latest versions',
      opts = { index = 30 },
      prompts = {
        n = function()
          require('codecompanion').cli(
            'Detect the package manager and dependency manifest used by this project. Update all dependencies to their latest compatible versions, then build or load the project to verify nothing breaks. Report what was bumped and any breaking changes you had to handle.',
            { submit = true }
          )
        end,
        v = function()
          require('codecompanion').cli(
            'Detect the package manager and dependency manifest used by this project. Update all dependencies to their latest compatible versions, then build or load the project to verify nothing breaks. Report what was bumped and any breaking changes you had to handle.',
            { submit = true }
          )
        end,
      },
    },
    ['CLI: Run App & Fix Errors'] = {
      interaction = 'chat',
      description = 'Ask the CLI agent to run the app and fix any errors',
      opts = { index = 31 },
      prompts = {
        n = function()
          require('codecompanion').cli(
            'Figure out how this project is run (check README, scripts, build files). Run the app, capture any startup or runtime errors, fix them, and rerun until it starts cleanly. Report each error found and how you fixed it.',
            { submit = true }
          )
        end,
        v = function()
          require('codecompanion').cli(
            'Figure out how this project is run (check README, scripts, build files). Run the app, capture any startup or runtime errors, fix them, and rerun until it starts cleanly. Report each error found and how you fixed it.',
            { submit = true }
          )
        end,
      },
    },
    ['CLI: Run Tests & Fix Failures'] = {
      interaction = 'chat',
      description = 'Ask the CLI agent to run the test suite and fix failing cases',
      opts = { index = 32 },
      prompts = {
        n = function()
          require('codecompanion').cli(
            'Detect the test framework and runner for this project. Run the full test suite, then fix the failing tests one by one - prefer fixing the code under test unless the test itself is clearly wrong. Rerun until green. Report each failure and its fix.',
            { submit = true }
          )
        end,
        v = function()
          require('codecompanion').cli(
            'Detect the test framework and runner for this project. Run the full test suite, then fix the failing tests one by one - prefer fixing the code under test unless the test itself is clearly wrong. Rerun until green. Report each failure and its fix.',
            { submit = true }
          )
        end,
      },
    },
    ['CLI: Share All Buffers'] = {
      interaction = 'chat',
      description = 'Share all open buffers with the CLI agent',
      opts = { index = 27 },
      prompts = {
        n = function()
          require('codecompanion').cli('#{buffers}', { focus = false })
        end,
        v = function()
          require('codecompanion').cli('#{buffers}', { focus = false })
        end,
      },
    },
  },
  -- DISPLAY OPTIONS ----------------------------------------------------------
  display = {
    action_palette = {
      width = 95,
      height = 10,
      provider = 'default', -- default|telescope
      opts = {
        title = 'AI Actions',
      },
    },
    chat = {
      window = {
        layout = 'vertical', -- float|vertical|horizontal|buffer
        border = 'rounded',
        height = 0.8,
        width = 0.4,
        relative = 'editor',
      },
      auto_scroll = true, -- Automatically scroll down and place the cursor at the end?
      intro_message = 'Press ? for options',

      separator = '─', -- The separator between the different messages in the chat buffer
      show_header_separator = false, -- Show header separators in the chat buffer? Set this to false if you're using an external markdown formatting plugin

      fold_context = false, -- Fold context in the chat buffer?
      show_context = true, -- Show context that you've shared with the LLM in the chat buffer?

      fold_reasoning = false, -- Fold the reasoning content in the chat buffer?
      show_reasoning = true, -- Show reasoning content in the chat buffer?

      show_settings = false, -- Show an LLM's settings at the top of the chat buffer?
      show_token_count = true, -- Show the token count for each response?
      show_tools_processing = true, -- Show the loading message when tools are being executed?
      start_in_insert_mode = false, -- Open the chat buffer in insert mode?
    },
    diff = {
      enabled = true,
      -- At or below this diff size, always display the diff in the chat buffer
      threshold_for_chat = 6,
      word_highlights = {
        additions = true,
        deletions = true,
      },
    },
    inline = {
      -- If the inline prompt creates a new buffer, how should we display this?
      layout = 'vertical', -- vertical|horizontal|buffer
    },
  },
  -- GENERAL OPTIONS ----------------------------------------------------------
  opts = {
    log_level = 'ERROR', -- TRACE|DEBUG|ERROR|INFO
    -- If this is false then any default prompt that is marked as containing code
    -- will not be sent to the LLM. Please note that whilst I have made every
    -- effort to ensure no code leakage, using this is at your own risk
    send_code = true,
    -- Project overrides are loaded through vim.secure.read() below. Keeping
    -- CodeCompanion's direct dofile loader disabled prevents untrusted files
    -- from executing before Neovim records an explicit trust decision.
    per_project_config = {
      enabled = false,
    },
  },
}

return {

  -- [[ AI ]] ---------------------------------------------------------------

  -- [codecompanion.nvim] - Integrates LLMs with neovim
  -- see: `:h codecompanion.txt`
  -- link: https://github.com/olimorris/codecompanion.nvim
  {
    'olimorris/codecompanion.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'lazymaniac/codecompanion-reasoning.nvim',
    },
    -- stylua: ignore
    keys = {
      { '<leader>ai', '<cmd>CodeCompanion<cr>', mode = { 'n', 'v' }, desc = 'Inline Prompt [ai]' },
      { '<leader>ac', '<cmd>CodeCompanionChat<cr>', mode = { 'n', 'v' }, desc = 'Open Chat [ac]' },
      { '<leader>at', '<cmd>CodeCompanionChat Toggle<cr>', mode = { 'n', 'v' }, desc = 'Toggle Chat [at]' },
      { '<leader>aa', '<cmd>CodeCompanionActions<cr>', mode = { 'n', 'v' }, desc = 'Actions [aa]' },
      { '<leader>au', '<cmd>CodeCompanionCLI agent=claude_code<cr>', mode = { 'n', 'v' }, desc = 'Claude Code CLI [au]' },
      { '<leader>ad', '<cmd>CodeCompanionCLI agent=codex<cr>', mode = { 'n', 'v' }, desc = 'Codex CLI [ad]' },
      { '<leader>al', '<cmd>CodeCompanionCLI agent=cline<cr>', mode = { 'n', 'v' }, desc = 'Cline CLI [al]' },
    },
    opts = config,
    config = function(_, opts)
      local wk = require 'which-key'
      local defaults = {
        { '<leader>a', group = '+[AI]' },
      }
      wk.add(defaults)
      local trusted = require('nv_ide.codecompanion').resolve(opts)
      require('codecompanion').setup(trusted)
    end,
  },
}
