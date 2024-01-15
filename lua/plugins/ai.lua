return {
  {
    'jackMort/ChatGPT.nvim',
    event = 'VeryLazy',
    dependencies = {
      'MunifTanjim/nui.nvim',
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
    },
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
          max_tokens = 4096,
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
        actions_paths = {},
        show_quickfixes_cmd = 'Trouble quickfix',
        predefined_chat_gpt_prompts = 'https://raw.githubusercontent.com/f/awesome-chatgpt-prompts/main/prompts.csv',
        highlights = {
          help_key = '@symbol',
          help_description = '@comment',
        },
      }

      require('which-key').register {
        ['<leader>z'] = {
          name = 'ChatGPT',
          c = { '<cmd>ChatGPT<CR>', 'Chat' },
          e = { '<cmd>ChatGPTEditWithInstruction<CR>', 'Edit with instruction', mode = { 'n', 'v' } },
          z = { '<cmd>ChatGPTCompleteCode<CR>', 'Complete Code' },
          g = { '<cmd>ChatGPTRun grammar_correction<CR>', 'Grammar Correction', mode = { 'n', 'v' } },
          l = { '<cmd>ChatGPTRun translate<CR>', 'Translate', mode = { 'n', 'v' } },
          k = { '<cmd>ChatGPTRun keywords<CR>', 'Keywords', mode = { 'n', 'v' } },
          d = { '<cmd>ChatGPTRun docstring<CR>', 'Docstring', mode = { 'n', 'v' } },
          t = { '<cmd>ChatGPTRun add_tests<CR>', 'Add Tests', mode = { 'n', 'v' } },
          o = { '<cmd>ChatGPTRun optimize_code<CR>', 'Optimize Code', mode = { 'n', 'v' } },
          s = { '<cmd>ChatGPTRun summarize<CR>', 'Summarize', mode = { 'n', 'v' } },
          f = { '<cmd>ChatGPTRun fix_bugs<CR>', 'Fix Bugs', mode = { 'n', 'v' } },
          x = { '<cmd>ChatGPTRun explain_code<CR>', 'Explain Code', mode = { 'n', 'v' } },
          r = { '<cmd>ChatGPTRun code_readability_analysis<CR>', 'Code Readability Analysis', mode = { 'n', 'v' } },
          y = { '<cmd>ChatGPTActAs<CR>', 'Act As' },
        },
      }
    end,
  },
  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    event = 'InsertEnter',
    dependencies = {
      {
        'zbirenbaum/copilot-cmp',
        config = function()
          require('copilot_cmp').setup()
        end,
      },
      { 'AndreM222/copilot-lualine' },
    },
    config = function()
      require('copilot').setup {
        panel = {
          enabled = true,
        },
        suggestion = {
          enabled = false,
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
      }
    end,
  },
  {
    'David-Kunz/gen.nvim',
    event = 'VeryLazy',
    opts = {
      model = 'deepseek-coder:6.7b-instruct', -- The default model to use.
      display_mode = 'float', -- The display mode. Can be "float" or "split".
      show_prompt = true, -- Shows the Prompt submitted to Ollama.
      show_model = true, -- Displays which model you are using at the beginning of your chat session.
      no_auto_close = false, -- Never closes the window automatically.
      init = function(options)
        pcall(io.popen, 'ollama serve > /dev/null 2>&1 &')
      end,
      -- Function to initialize Ollama
      command = 'curl --silent --no-buffer -X POST http://localhost:11434/api/generate -d $body',
      -- The command for the Ollama service. You can use placeholders $prompt, $model and $body (shellescaped).
      -- This can also be a lua function returning a command string, with options as the input parameter.
      -- The executed command must return a JSON object with { response, context }
      -- (context property is optional).
      debug = false, -- Prints errors and the command which is run.
    },
    keys = {
      { '<leader>zG', '<cmd>Gen<CR>', desc = "LLM Gen", mode = { 'n' } },
      { '<leader>zG', "'<,'><cmd>Gen<CR>", desc = "LLM Gen", mode = { 'v' } },
    },
  },
}
