local config = {
  adapters = {
    http = {
      opts = {
        show_defaults = false,
        show_model_choices = true,
      },
      anthropic = function()
        return require('codecompanion.adapters').extend('anthropic', {
          env = {
            api_key = 'cmd:cat ~/.anthropic',
          },
        })
      end,
      openai = function()
        return require('codecompanion.adapters').extend('openai', {
          env = {
            api_key = 'cmd:cat ~/.gpt',
          },
        })
      end,
      tavily = function()
        return require('codecompanion.adapters').extend('tavily', {
          env = {
            api_key = 'cmd:cat ~/.tavily',
          },
        })
      end,
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
  },
  interactions = {
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
          auto_submit_errors = true, -- Send any errors to the LLM automatically?
          auto_submit_success = true, -- Send any successful output to the LLM automatically?
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
      },
    },
  },
  -- DISPLAY OPTIONS ----------------------------------------------------------
  display = {
    action_palette = {
      width = 95,
      height = 10,
      prompt = 'Prompt ', -- Prompt used for interactive LLM calls
      provider = 'default', -- default|telescope
      opts = {
        show_preset_actions = true, -- Show the default actions in the action palette?
        show_preset_prompts = true, -- Show the default prompt library in the action palette?
        title = 'AI Actions',
      },
    },
    chat = {
      window = {
        layout = 'vertical', -- float|vertical|horizontal|buffer
        border = 'rounded',
        height = 0.3,
        width = 0.3,
        relative = 'editor',
        opts = {
          breakindent = true,
          cursorcolumn = false,
          cursorline = false,
          foldcolumn = '0',
          linebreak = true,
          list = false,
          signcolumn = 'no',
          spell = false,
          wrap = true,
        },
      },
      intro_message = 'Press ? for help',
      show_header_separator = false, -- Show header separators in the chat buffer? Set this to false if you're using an external markdown formatting plugin
      show_references = true, -- Show references (from slash commands and variables) in the chat buffer?
      separator = '─', -- The separator between the different messages in the chat buffer
      show_settings = false, -- Show LLM settings at the top of the chat buffer?
      show_token_count = true, -- Show the token count for each response?
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
    log_level = 'TRACE', -- TRACE|DEBUG|ERROR|INFO
    -- If this is false then any default prompt that is marked as containing code
    -- will not be sent to the LLM. Please note that whilst I have made every
    -- effort to ensure no code leakage, using this is at your own risk
    send_code = true,
  },
}

return {

  -- [[ AI ]] ---------------------------------------------------------------

  -- [codecompanion.nvim] - Integrates LLMs with neovim
  -- see: `:h codecompanion.txt`
  -- link: https://github.com/olimorris/codecompanion.nvim
  {
    'olimorris/codecompanion.nvim',
    -- dir = '/Users/sebastian/workspace/codecompanion.nvim/',
    -- dev = true,
    -- 'lazymaniac/codecompanion.nvim',
    -- branch = 'feature/lsp-tool',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    -- stylua: ignore
    keys = {
      { '<leader>ai', '<cmd>CodeCompanion<cr>', mode = { 'n', 'v' }, desc = 'Inline Prompt [ai]' },
      { '<leader>ac', '<cmd>CodeCompanionChat<cr>', mode = { 'n', 'v' }, desc = 'Open Chat [ac]' },
      { '<leader>at', '<cmd>CodeCompanionChat Toggle<cr>', mode = { 'n', 'v' }, desc = 'Toggle Chat [at]' },
      { '<leader>aa', '<cmd>CodeCompanionActions<cr>', mode = { 'n', 'v' }, desc = 'Actions [aa]' },
    },
    config = function()
      local wk = require 'which-key'
      local defaults = {
        { '<leader>a', group = '+[AI]' },
      }
      wk.add(defaults)
      require('codecompanion').setup(config)
    end,
  },
}
