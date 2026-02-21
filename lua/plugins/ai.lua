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
              default = 'qwen3-next',
            },
            num_ctx = {
              default = 120000,
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
        layout = 'float', -- float|vertical|horizontal|buffer
        border = 'rounded',
        height = 0.8,
        width = 0.8,
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
      provider = 'inline', -- mini_diff|split|inline

      provider_opts = {
        -- Options for inline diff provider
        inline = {
          layout = 'float', -- float|buffer - Where to display the diff

          opts = {
            context_lines = 4, -- Number of context lines in hunks
            dim = 25, -- Background dim level for floating diff (0-100, [100 full transparent], only applies when layout = "float")
            full_width_removed = true, -- Make removed lines span full width
            show_keymap_hints = true, -- Show "gda: accept | gdr: reject" hints above diff
            show_removed = true, -- Show removed lines as virtual text
          },
        },

        -- Options for the split provider
        split = {
          close_chat_at = 240, -- Close an open chat buffer if the total columns of your display are less than...
          layout = 'vertical', -- vertical|horizontal split
          opts = {
            'internal',
            'filler',
            'closeoff',
            'algorithm:histogram', -- https://adamj.eu/tech/2024/01/18/git-improve-diff-histogram/
            'indent-heuristic', -- https://blog.k-nut.eu/better-git-diffs
            'followwrap',
            'linematch:120',
          },
        },
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
    -- 'olimorris/codecompanion.nvim',
    dir = '/Users/sebastian/workspace/codecompanion.nvim/',
    dev = true,
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
