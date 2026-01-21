local config = {
  adapters = {
    http = {
      opts = {
        show_defaults = false,
        show_model_choices = true,
      },
      anthropic = function()
        return require('codecompanion.adapters').extend('anthropic', {
          schema = {
            auth_type = {
              default = 'oauth',
            },
          },
          env = {
            api_key = 'cmd:cat ~/.anthropic',
          },
        })
      end,
      openai = function()
        return require('codecompanion.adapters').extend('openai', {
          schema = {
            model = {
              default = 'gpt-5',
            },
          },
          env = {
            api_key = 'cmd:cat ~/.gpt',
          },
        })
      end,
      openai_responses = function()
        return require('codecompanion.adapters').extend('openai_responses', {
          schema = {
            model = {
              default = 'gpt-5',
            },
          },
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
              default = 'gpt-oss:120b',
            },
            num_ctx = {
              default = 120000,
            },
            temperature = {
              default = 0.8,
            },
          },
        })
      end,
    },
  },
  extensions = {
    mcphub = {
      callback = 'mcphub.extensions.codecompanion',
      opts = {
        make_vars = true,
        make_slash_commands = true,
        show_result_in_chat = true,
      },
    },
    reasoning = {
      callback = 'codecompanion._extensions.reasoning',
      opts = {
        project_knowledge_initialization = {
          adapter = 'openai', -- defaults to chat adapter
          model = 'gpt-5-mini',
        },
        session_optimizer = {
          adapter = 'openai', -- defaults to chat adapter
          model = 'gpt-5-nano', -- defaults to chat model
          summary_max_words = 2000, -- target words in generated summary
        },
        session_title_generator = {
          adapter = 'openai', -- defaults to chat adapter
          model = 'gpt-5-nano', -- defaults to chat model
          refresh_every_n_user_prompts = 3,
          max_words_per_title = 6,
          format_title = nil,
        },
        reflect_on_progress = {
          adapter = 'openai',
          model = 'gpt-5-nano',
        },
        session_history = {
          auto_save = true,
          auto_generate_title = true,
          continue_last_session = false,
          picker = 'default',
          max_sessions = 100,
          sessions_dir = vim.fn.stdpath 'data' .. '/codecompanion-reasoning/sessions',
          session_file_pattern = 'session_%Y%m%d_%H%M%S.lua',
          keymaps = {
            rename = { n = 'r', i = '<M-r>' },
            delete = { n = 'd', i = '<M-d>' },
            duplicate = { n = '<C-y>', i = '<C-y>' },
          },
        },
        enabled = true,
      },
    },
  },
  strategies = {
    -- CHAT STRATEGY ----------------------------------------------------------
    chat = {
      adapter = 'openai_responses',
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
            'meta_agent',
          },
        },
      },
      slash_commands = {
        ['ls_git_files'] = {
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
      adapter = 'openai_responses',
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
    'olimorris/codecompanion.nvim',
    -- dir = '/Users/sebastian/workspace/codecompanion.nvim/',
    -- dev = true,
    -- 'lazymaniac/codecompanion.nvim',
    -- branch = 'feature/lsp-tool',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-treesitter/nvim-treesitter',
      {
        'ravitemer/mcphub.nvim',
        cmd = 'MCPHub',
        build = 'bundled_build.lua',
        opts = {
          use_bundled_binary = true, -- Use local `mcp-hub` binary (set this to true when using build = "bundled_build.lua")
          workspace = {
            enabled = true, -- Enable project-local configuration files
            look_for = { '.mcphub/servers.json', '.vscode/mcp.json', '.cursor/mcp.json' }, -- Files to look for when detecting project boundaries (VS Code format supported)
            reload_on_dir_changed = true, -- Automatically switch hubs on DirChanged event
            port_range = { min = 40000, max = 41000 }, -- Port range for generating unique workspace ports
            get_port = nil, -- Optional function returning custom port number. Called when generating ports to allow custom port assignment logic
          },
          ---Chat-plugin related options-----------------
          auto_approve = false, -- Auto approve mcp tool calls
          auto_toggle_mcp_servers = false, -- Let LLMs start and stop MCP servers automatically
          --- Plugin specific options-------------------
          native_servers = {}, -- add your custom lua native servers here
          builtin_tools = {
            edit_file = {
              parser = {
                track_issues = true,
                extract_inline_content = true,
              },
              locator = {
                fuzzy_threshold = 0.8,
                enable_fuzzy_matching = true,
              },
              ui = {
                go_to_origin_on_complete = true,
                keybindings = {
                  accept = '.',
                  reject = ',',
                  next = 'n',
                  prev = 'p',
                  accept_all = 'ga',
                  reject_all = 'gr',
                },
              },
            },
          },
          ui = {
            window = {
              width = 0.8, -- 0-1 (ratio); "50%" (percentage); 50 (raw number)
              height = 0.8, -- 0-1 (ratio); "50%" (percentage); 50 (raw number)
              align = 'center', -- "center", "top-left", "top-right", "bottom-left", "bottom-right", "top", "bottom", "left", "right"
              relative = 'editor',
              zindex = 50,
              border = 'rounded', -- "none", "single", "double", "rounded", "solid", "shadow"
            },
            wo = { -- window-scoped options (vim.wo)
              winhl = 'Normal:MCPHubNormal,FloatBorder:MCPHubBorder',
            },
          },
        },
      },
      {
        dir = '/Users/sebastian/workspace/codecompanion-reasoning.nvim/',
        dev = true,
      },
    },
    -- stylua: ignore
    keys = {
      { '<leader>ai', '<cmd>CodeCompanion<cr>', mode = { 'n', 'v' }, desc = 'Inline Prompt [ai]' },
      { '<leader>ac', '<cmd>CodeCompanionChat<cr>', mode = { 'n', 'v' }, desc = 'Open Chat [ac]' },
      { '<leader>at', '<cmd>CodeCompanionChat Toggle<cr>', mode = { 'n', 'v' }, desc = 'Toggle Chat [at]' },
      { '<leader>aa', '<cmd>CodeCompanionActions<cr>', mode = { 'n', 'v' }, desc = 'Actions [aa]' },
      { '<leader>am', '<cmd>MCPHub<cr>', mode = { 'n' }, desc = 'MCP Hub [am]' },
      { '<leader>ah', '<cmd>CodeCompanionChatHistory<cr>', mode = { 'n' }, desc = 'Chat History [ah]' },
      { '<leader>al', '<cmd>CodeCompanionChatLast<cr>', mode = { 'n' }, desc = 'Continue Last Session [al]' },
      { '<leader>ap', '<cmd>CodeCompanionProjectKnowledge<cr>', mode = { 'n' }, desc = 'Open Project Knowledge file [ap]' },
      { '<leader>ap', '<cmd>CodeCompanionInitProjectKnowledge<cr>', mode = { 'n' }, desc = 'Initialize Project Knowledge [ap]' },
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
