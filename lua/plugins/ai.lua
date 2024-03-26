local expert = function(filetype)
  return 'I want you to act as a senior '
    .. filetype
    .. ' developer. I will give you specific code examples and ask you questions. I want you to advise me with explanations and code examples.'
end

local send_code = function(context)
  local text = require('codecompanion.helpers.code').get_code(context.start_line, context.end_line)

  return 'I have the following code:\n\n```' .. context.filetype .. '\n' .. text .. '\n```\n\n'
end

return {

  -- [[ AI ]] ---------------------------------------------------------------

  {
    'folke/edgy.nvim',
    event = 'VeryLazy',
    enabled = true,
    init = function()
      vim.opt.laststatus = 3
      vim.opt.splitkeep = 'screen'
    end,
    opts = {
      right = {
        { ft = 'codecompanion', title = 'Code Companion Chat', size = { width = 0.40 } },
      },
    },
  },

  {
    'olimorris/codecompanion.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter', 'nvim-telescope/telescope.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>zg', '<cmd>CodeCompanion<cr>', mode = { 'n', 'v' }, desc = 'Code Companion [zg]' },
      { '<leader>zc', '<cmd>CodeCompanionChat<cr>', mode = { 'n', 'v' }, desc = 'Chat [zc]' },
      { '<leader>zt', '<cmd>CodeCompanionToggle<cr>', mode = { 'n', 'v' }, desc = 'Toggle [zt]' },
      { '<leader>za', '<cmd>CodeCompanionActions<cr>', mode = { 'n', 'v' }, desc = 'Actions [za]' },
    },
    config = function()
      require('codecompanion').setup {
        adapters = { -- anthropic|ollama|openai
          chat = require('codecompanion.adapters').use('openai', {
            env = {
              api_key = 'cmd:cat ' .. vim.fn.expand '~/.gpt',
            },
          }),
          inline = require('codecompanion.adapters').use('openai', {
            env = {
              api_key = 'cmd:cat ' .. vim.fn.expand '~/.gpt',
            },
          }),
        },
        saved_chats = {
          save_dir = vim.fn.stdpath 'data' .. '/codecompanion/saved_chats', -- Path to save chats to
        },
        display = {
          action_palette = {
            width = 95,
            height = 10,
          },
          chat = { -- Options for the chat strategy
            type = 'float', -- float|buffer
            show_settings = true, -- Show the model settings in the chat buffer?
            show_token_count = true, -- Show the token count for the current chat in the buffer?
            buf_options = { -- Buffer options for the chat buffer
              buflisted = false,
            },
            float_options = { -- Float window options if the type is "float"
              border = 'single',
              buflisted = false,
              max_height = 0,
              max_width = 0,
              padding = 1,
            },
            win_options = { -- Window options for the chat buffer
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
        },
        keymaps = {
          ['<C-s>'] = 'keymaps.save', -- Save the chat buffer and trigger the API
          ['<C-c>'] = 'keymaps.close', -- Close the chat buffer
          ['q'] = 'keymaps.cancel_request', -- Cancel the currently streaming request
          ['gc'] = 'keymaps.clear', -- Clear the contents of the chat
          ['ga'] = 'keymaps.codeblock', -- Insert a codeblock into the chat
          ['gs'] = 'keymaps.save_chat', -- Save the current chat
          [']'] = 'keymaps.next', -- Move to the next header in the chat
          ['['] = 'keymaps.previous', -- Move to the previous header in the chat
        },
        log_level = 'ERROR', -- TRACE|DEBUG|ERROR
        send_code = true, -- Send code context to the generative AI service? Disable to prevent leaking code outside of Neovim
        silence_notifications = false, -- Silence notifications for actions like saving saving chats?
        use_default_actions = true, -- Use the default actions in the action palette?
        actions = {
          {
            name = 'Code advisor',
            strategy = 'chat',
            description = "Get advice on the code you've selected",
            type = nil,
            prompts = {
              n = function()
                return require('codecompanion').chat()
              end,
              v = {
                {
                  role = 'system',
                  content = function(context)
                    return 'I want you to act as a senior '
                      .. context.filetype
                      .. ' developer. I will ask you specific questions and I want you to return concise explanations and codeblock examples.'
                  end,
                },
                {
                  role = 'user',
                  contains_code = true,
                  content = function(context)
                    return send_code(context)
                  end,
                },
              },
            },
          },
          {
            name = 'LSP assistant',
            strategy = 'chat',
            description = 'Get help from OpenAI to fix LSP diagnostics',
            type = nil,
            opts = {
              auto_submit = true, -- Automatically submit the chat
              user_prompt = false, -- Prompt the user for their own input
            },
            prompts = {
              v = {
                {
                  role = 'system',
                  content = [[You are an expert coder and helpful assistant who can help debug code diagnostics, such as warning and error messages. When appropriate, give solutions with code snippets as fenced codeblocks with a language identifier to enable syntax highlighting.]],
                },
                {
                  role = 'user',
                  content = function(context)
                    local diagnostics = require('codecompanion.helpers.lsp').get_diagnostics(context.start_line, context.end_line, context.bufnr)

                    local concatenated_diagnostics = ''
                    for i, diagnostic in ipairs(diagnostics) do
                      concatenated_diagnostics = concatenated_diagnostics
                        .. i
                        .. '. Issue '
                        .. i
                        .. '\n  - Location: Line '
                        .. diagnostic.line_number
                        .. '\n  - Severity: '
                        .. diagnostic.severity
                        .. '\n  - Message: '
                        .. diagnostic.message
                        .. '\n'
                    end

                    return 'The programming language is ' .. context.filetype .. '. This is a list of the diagnostic messages:\n\n' .. concatenated_diagnostics
                  end,
                },
                {
                  role = 'user',
                  contains_code = true,
                  content = function(context)
                    return 'This is the code, for context:\n\n'
                      .. '```'
                      .. context.filetype
                      .. '\n'
                      .. require('codecompanion.helpers.code').get_code(context.start_line, context.end_line, { show_line_numbers = true })
                      .. '\n```\n\n'
                  end,
                },
              },
            },
          },
        },
      }
    end,
  },
  -- [ChatGPT.nvim] - Integration with ChatGPT.
  -- see: `:h ChatGPT.nvim`
  {
    'jackMort/ChatGPT.nvim',
    enabled = false,
    event = 'VeryLazy',
    dependencies = { 'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope.nvim' },
    config = function()
      require('chatgpt').setup {
        api_key_cmd = 'cat ' .. vim.fn.expand '~/.gpt',
        yank_register = '+',
        edit_with_instructions = {
          diff = true,
          keymaps = {
            close = '<C-c>',
            accept = '<C-y>',
            toggle_diff = '<C-d>',
            toggle_settings = '<C-o>',
            toggle_help = '<C-h>',
            cycle_windows = '<Tab>',
            use_output_as_input = '<C-i>',
          },
        },
        chat = {
          keymaps = {
            close = '<C-c>',
            yank_last = '<C-y>',
            yank_last_code = '<C-k>',
            scroll_up = '<C-u>',
            scroll_down = '<C-d>',
            new_session = '<C-n>',
            cycle_windows = '<Tab>',
            cycle_modes = '<C-f>',
            next_message = '<C-j>',
            prev_message = '<C-k>',
            select_session = '<Space>',
            rename_session = 'r',
            delete_session = 'd',
            draft_message = '<C-r>',
            edit_message = 'e',
            delete_message = 'd',
            toggle_settings = '<C-o>',
            toggle_sessions = '<C-p>',
            toggle_help = '<C-h>',
            toggle_message_role = '<C-r>',
            toggle_system_role_open = '<C-s>',
            stop_generating = '<C-x>',
          },
        },
        popup_layout = {
          default = 'center',
          center = {
            width = '80%',
            height = '80%',
          },
          right = {
            width = '30%',
            width_settings_open = '50%',
          },
        },
        popup_window = {
          border = {
            highlight = 'FloatBorder',
            style = 'rounded',
            text = {
              top = ' Assistant ',
            },
          },
          win_options = {
            wrap = true,
            linebreak = true,
            foldcolumn = '1',
            winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
          },
          buf_options = {
            filetype = 'markdown',
          },
        },
        system_window = {
          border = {
            highlight = 'FloatBorder',
            style = 'rounded',
            text = {
              top = ' SYSTEM ',
            },
          },
          win_options = {
            wrap = true,
            linebreak = true,
            foldcolumn = '2',
            winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
          },
        },
        popup_input = {
          prompt = '  ',
          border = {
            highlight = 'FloatBorder',
            style = 'rounded',
            text = {
              top_align = 'center',
              top = ' Prompt ',
            },
          },
          win_options = {
            winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
          },
          submit = '<C-Enter>',
          submit_n = '<Enter>',
          max_visible_lines = 20,
        },
        settings_window = {
          setting_sign = '  ',
          border = {
            style = 'rounded',
            text = {
              top = ' Settings ',
            },
          },
          win_options = {
            winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
          },
        },
        help_window = {
          setting_sign = '  ',
          border = {
            style = 'rounded',
            text = {
              top = ' Help ',
            },
          },
          win_options = {
            winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
          },
        },
        openai_params = {
          model = 'gpt-4-1106-preview',
          frequency_penalty = 0,
          presence_penalty = 0,
          max_tokens = 2048,
          temperature = 0,
          top_p = 1,
          n = 1,
        },
        openai_edit_params = {
          model = 'gpt-4-1106-preview',
          frequency_penalty = 0,
          presence_penalty = 0,
          temperature = 0,
          top_p = 1,
          n = 1,
        },
        use_openai_functions_for_edits = false,
        actions_paths = { vim.fn.expand '~/.config/nvim/actions.json' },
        show_quickfixes_cmd = 'Trouble quickfix',
        highlights = {
          help_key = '@symbol',
          help_description = '@comment',
        },
        predefined_chat_gpt_prompts = 'file:///' .. vim.fn.expand '~' .. '/.config/nvim/lua/plugins/chatgpt-prompts.csv',
      }
      require('which-key').register {
        ['<leader>z'] = {
          name = '+[AI]',
          c = { '<cmd>ChatGPT<CR>', 'Chat [zc]' },
          e = { '<cmd>ChatGPTEditWithInstruction<CR>', 'Edit with instruction [ze]', mode = { 'n', 'v' } },
          C = { '<cmd>ChatGPTCompleteCode<CR>', 'Complete Code [zZ]' },
          g = { '<cmd>ChatGPTRun grammar_correction<CR>', 'Grammar Correction [zg]', mode = { 'n', 'v' } },
          l = { '<cmd>ChatGPTRun translate<CR>', 'Translate [zl]', mode = { 'n', 'v' } },
          k = { '<cmd>ChatGPTRun keywords<CR>', 'Keywords [zk]', mode = { 'n', 'v' } },
          d = { '<cmd>ChatGPTRun docstring<CR>', 'Docstring [zd]', mode = { 'n', 'v' } },
          t = { '<cmd>ChatGPTRun add_tests<CR>', 'Add Tests [zt]', mode = { 'n', 'v' } },
          o = { '<cmd>ChatGPTRun optimize_code<CR>', 'Optimize Code [zo]', mode = { 'n', 'v' } },
          s = { '<cmd>ChatGPTRun summarize<CR>', 'Summarize [zs]', mode = { 'n', 'v' } },
          f = { '<cmd>ChatGPTRun fix_bugs<CR>', 'Fix Bugs [zf]', mode = { 'n', 'v' } },
          x = { '<cmd>ChatGPTRun explain_code<CR>', 'Explain Code [zx]', mode = { 'n', 'v' } },
          r = { '<cmd>ChatGPTRun code_readability_analysis<CR>', 'Code Readability Analysis [zr]', mode = { 'n', 'v' } },
          y = { '<cmd>ChatGPTActAs<CR>', 'Act As [zy]' },
        },
      }
    end,
  },

  -- [ollama.nvim] - Plugin to interact with local LLM
  -- see: `:h ollama.nvim`
  {
    'nomnivore/ollama.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    cmd = { 'Ollama', 'OllamaModel', 'OllamaServe', 'OllamaServeStop' },
    keys = {
      { '<leader>zz', ":<c-u>lua require('ollama').prompt()<cr>", desc = 'ollama prompt', mode = { 'n', 'v' } },
    },
    opts = {
      model = 'nous-hermes2:10.7b-solar-q5_K_M',
      url = 'http://127.0.0.1:11434',
      serve = {
        on_start = false,
        command = 'ollama',
        args = { 'serve' },
        stop_command = 'pkill',
        stop_args = { '-SIGTERM', 'ollama' },
      },
      -- View the actual default prompts in ./lua/ollama/prompts.lua
      prompts = {
        Implement_Code = {
          -- Tokens in prompt:
          -- $input	  Prompt the user for input.
          -- $sel	    The current or previous selection.
          -- $ftype 	The filetype of the current buffer.
          -- $fname	  The filename of the current buffer.
          -- $buf	    The full contents of the current buffer.
          -- $line	  The current line in the buffer.
          -- $lnum	  The current line number in the buffer.
          prompt = 'Implement code:\n$sel \naccording to instructions: $input. Only output the result in format ```$ftype\n...\n```:\n```$ftype\n```',
          input_label = '> ',
          -- Available actions:
          -- display: Stream and display the response in a floating window.
          -- replace: Replace the current selection with the response.
          -- Uses the extract pattern to extract the response.
          -- insert: Insert the response at the current cursor line
          -- Uses the extract pattern to extract the response.
          -- display_replace: Stream and display the response in a floating window, then replace the current selection with the response.
          -- Uses the extract pattern to extract the response.
          -- display_insert: Stream and display the response in a floating window, then insert the response at the current cursor line.
          -- Uses the extract pattern to extract the response.
          action = 'replace',
        },
      },
    },
  },
}
