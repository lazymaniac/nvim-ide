local config = {
  adapters = {
    opts = {
      show_defaults = false,
      show_model_choices = true,
    },
    anthropic = function()
      return require('codecompanion.adapters').extend('anthropic', {
        schema = {
          model = {
            default = 'claude-3-7-sonnet-20250219',
          },
        },
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
    copilot = function()
      return require('codecompanion.adapters').extend('copilot', {
        schema = {
          model = {
            default = 'claude-sonnet-4',
          },
        },
      })
    end,
    ollama = function()
      return require('codecompanion.adapters').extend('ollama', {
        schema = {
          model = {
            default = 'llama4:latest',
          },
          num_ctx = {
            default = 8192,
          },
          temperature = {
            default = 0.9,
          },
        },
      })
    end,
  },
  extensions = {
    history = {
      enabled = true,
      opts = {
        keymap = 'gh',
        auto_save = false,
        expiration_days = 0,
        picker = 'default', --- ("telescope", "snacks", "fzf-lua", or "default")
        picker_keymaps = {
          rename = { n = 'r', i = '<M-r>' },
          delete = { n = 'd', i = '<M-d>' },
          duplicate = { n = '<C-y>', i = '<C-y>' },
        },
        auto_generate_title = false,
        continue_last_chat = false,
        delete_on_clearing_chat = false,
        dir_to_save = vim.fn.stdpath 'data' .. '/codecompanion-history',
        enable_logging = true,
      },
    },
    mcphub = {
      callback = 'mcphub.extensions.codecompanion',
      opts = {
        make_vars = true,
        make_slash_commands = true,
        show_result_in_chat = true,
      },
    },
    vectorcode = {
      opts = {
        add_tool = true,
      },
    },
  },
  strategies = {
    -- CHAT STRATEGY ----------------------------------------------------------
    chat = {
      adapter = 'anthropic',
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
            'list_code_usages',
            -- 'insert_edit_into_file',
          },
        },
      },
      slash_commands = {
        ['git_files'] = {
          description = 'List git files',
          ---@param chat CodeCompanion.Chat
          callback = function(chat)
            local handle = io.popen 'git ls-files'
            if handle ~= nil then
              local result = handle:read '*a'
              handle:close()
              chat:add_reference({ content = result }, 'git', '<git_files>')
              return vim.notify 'Git files added to the chat.'
            else
              return vim.notify('No git files available', vim.log.levels.INFO, { title = 'CodeCompanion' })
            end
          end,
          opts = {
            contains_code = false,
          },
        },
      },
    },
    -- INLINE STRATEGY --------------------------------------------------------
    inline = {
      adapter = 'anthropic',
    },
    -- CMD STRATEGY -----------------------------------------------------------
    cmd = {
      adapter = 'anthropic',
    },
  },
  prompt_library = {
    ['Suggest Refactoring'] = {
      strategy = 'chat',
      description = 'Suggest refactoring for provided piece of code.',
      opts = {
        modes = { 'v' },
        short_name = 'refactor',
        auto_submit = false,
        is_slash_command = false,
        is_default = true,
        stop_context_insertion = true,
        user_prompt = false,
      },
      prompts = {
        {
          role = 'system',
          content = function(_)
            return [[ Your task is to suggest refactoring of a specified piece of code to improve its efficiency, readability, and maintainability without altering its functionality. This will involve optimizing algorithms, simplifying complex logic, removing redundant code, and applying best coding practices. Check every aspect of the code, including variable names, function structures, and overall design patterns. Your goal is to provide a cleaner, more efficient version of the code that adheres to modern coding standards. ]]
          end,
        },
        {
          role = 'user',
          content = function(context)
            local text = require('codecompanion.helpers.actions').get_code(context.start_line, context.end_line)
            return 'I have the following code:\n\n```' .. context.filetype .. '\n' .. text .. '\n```\n\n'
          end,
          opts = {
            contains_code = true,
          },
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
        show_default_actions = true, -- Show the default actions in the action palette?
        show_default_prompt_library = true, -- Show the default prompt library in the action palette?
      },
    },
    chat = {
      window = {
        layout = 'vertical', -- float|vertical|horizontal|buffer
        border = 'rounded',
        height = 0.8,
        width = 0.40,
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
      start_in_insert_mode = true, -- Open the chat buffer in insert mode?
    },
    diff = {
      enabled = true,
      close_chat_at = 240, -- Close an open chat buffer if the total columns of your display are less than...
      layout = 'vertical', -- vertical|horizontal split for default provider
      opts = { 'internal', 'filler', 'closeoff', 'algorithm:patience', 'followwrap', 'linematch:120' },
      provider = 'default', -- default|mini_diff
    },
    inline = {
      -- If the inline prompt creates a new buffer, how should we display this?
      layout = 'vertical', -- vertical|horizontal|buffer
    },
  },
  -- GENERAL OPTIONS ----------------------------------------------------------
  opts = {
    log_level = 'DEBUG', -- TRACE|DEBUG|ERROR|INFO
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
    dir = '/Users/sebastian/workspace/codecompanion.nvim/',
    dev = true,
    -- 'lazymaniac/codecompanion.nvim',
    -- branch = 'feature/lsp-tool',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      'ravitemer/codecompanion-history.nvim',
      {
        'ravitemer/mcphub.nvim',
        cmd = 'MCPHub',
        build = 'bundled_build.lua',
        opts = {
          use_bundled_binary = true,
        },
      },
      {
        'Davidyz/VectorCode',
        version = '*',
        build = 'uv tool upgrade vectorcode',
        dependencies = { 'nvim-lua/plenary.nvim' },
      },
    },
    -- stylua: ignore
    keys = {
      { '<leader>ai', '<cmd>CodeCompanion<cr>',        mode = { 'n', 'v' }, desc = 'Inline Prompt [ai]' },
      { '<leader>ac', '<cmd>CodeCompanionChat<cr>',    mode = { 'n', 'v' }, desc = 'Open Chat [ac]' },
      { '<leader>at', '<cmd>CodeCompanionChat Toggle<cr>',  mode = { 'n', 'v' }, desc = 'Toggle Chat [at]' },
      { '<leader>aa', '<cmd>CodeCompanionActions<cr>', mode = { 'n', 'v' }, desc = 'Actions [aa]' },
      { '<leader>am', '<cmd>MCPHub<cr>', mode = { 'n' }, desc = 'MCP Hub [am]' },
    },
    config = function()
      -- mappings group
      local wk = require 'which-key'
      local defaults = {
        { '<leader>a', group = '+[AI]' },
      }
      wk.add(defaults)
      -- plugin setup
      require('codecompanion').setup(config)
    end,
  },

  -- [copilot.lua] - Copilot integration for Neovim
  -- see: `:h copilot.lua`
  -- link: https://github.com/zbirenbaum/copilot.lua
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    enabled = true,
    event = 'InsertEnter',
    config = function()
      require('copilot').setup {
        server_opts_overrides = {
          settings = {
            telemetry = {
              telemetryLevel = 'off',
            },
          },
        },
        panel = {
          enabled = false,
        },
        suggestion = {
          enabled = true,
        },
        filetypes = {
          yaml = false,
          markdown = false,
          help = false,
          gitcommit = false,
          gitrebase = false,
          hgcommit = false,
          svn = false,
          cvs = false,
          ['.'] = false,
        },
        copilot_model = '',
      }
    end,
  },
}
