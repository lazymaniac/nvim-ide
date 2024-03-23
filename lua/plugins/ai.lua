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
          inline = 'openai',
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

  -- [gen.nvim] - Integration with local LLMs
  -- see: `:h gen.nvim`
  {
    'David-Kunz/gen.nvim',
    enabled = true,
    event = 'VeryLazy',
    config = function()
      require('gen').setup {
        model = 'nous-hermes2:10.7b-solar-q5_K_M', -- The default model to use.
        display_mode = 'split', -- The display mode. Can be "float" or "split".
        show_prompt = true, -- Shows the Prompt submitted to Ollama.
        show_model = true, -- Displays which model you are using at the beginning of your chat session.
        no_auto_close = true, -- Never closes the window automatically.
        init = function(options)
          vim.print(options)
          pcall(io.popen, 'ollama serve > /dev/null 2>&1 &')
        end,
        -- Function to initialize Ollama
        command = 'curl --silent --no-buffer -X POST http://localhost:11434/api/generate -d $body',
        -- The command for the Ollama service. You can use placeholders $prompt, $model and $body (shellescaped).
        -- This can also be a lua function returning a command string, with options as the input parameter.
        -- The executed command must return a JSON object with { response, context }
        -- (context property is optional).
        debug = false, -- Prints errors and the command which is run.
      }
      require('gen').prompts['Fix_Code'] = {
        prompt = 'Your task is to fix the following code. Only output the result in format ```$filetype\n...\n```:\n```$filetype\n$text\n```',
        replace = false,
        extract = '```$filetype\n(.-)```',
      }
      require('gen').prompts['Generate_Tests'] = {
        prompt = 'Write tests for the following code. Only output the result in format ```$filetype\n...\n```:\n```$filetype\n$text\n```',
        replace = false,
        extract = '```$filetype\n(.-)```',
      }
    end,
    keys = {
      { '<leader>zz', ':Gen<CR>', desc = 'Local LLM [zz]', mode = { 'n', 'v' } },
    },
  },
}
