return {

  -- [[ AI ]] ---------------------------------------------------------------

  -- [ChatGPT.nvim] - Integration with ChatGPT.
  -- see: `:h ChatGPT.nvim`
  {
    'jackMort/ChatGPT.nvim',
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
    event = 'VeryLazy',
    config = function()
      require('gen').setup {
        model = 'deepseek-coder:6.7b-instruct-q5_K_M', -- The default model to use.
        display_mode = 'split', -- The display mode. Can be "float" or "split".
        show_prompt = true, -- Shows the Prompt submitted to Ollama.
        show_model = true, -- Displays which model you are using at the beginning of your chat session.
        no_auto_close = true, -- Never closes the window automatically.
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

  {
    'huynle/ogpt.nvim',
    event = 'VeryLazy',
    enabled = false,
    init = function(_)
      pcall(io.popen, 'ollama serve > /dev/null 2>&1 &')
    end,
    -- stylua: ignore
    keys = {
      { '<leader>zf', '<cmd>OGPTFocus<CR>', desc = 'GPT Focus' },
      { '<leader>zz', ":'<,'>OGPTRun<CR>", desc = 'GPT', mode = { 'n', 'v' } },
      { '<leader>zc', '<cmd>OGPTRun edit_code_with_instructions<CR>', desc = 'Edit with instructions', mode = { 'n', 'v' } },
      { '<leader>ze', '<cmd>OGPTRun edit_with_instructions<CR>', desc = 'Edit with instructions', mode = { 'n', 'v' } },
      { '<leader>zg', '<cmd>OGPTRun grammar_correction<CR>', desc = 'Grammar Correction', mode = { 'n', 'v' } },
      { '<leader>zr', '<cmd>OGPTRun evaluate<CR>', desc = 'Evaluate', mode = { 'n', 'v' } },
      { '<leader>zi', '<cmd>OGPTRun get_info<CR>', desc = 'Get Info', mode = { 'n', 'v' } },
      { '<leader>zt', '<cmd>OGPTRun translate<CR>', desc = 'Translate', mode = { 'n', 'v' } },
      { '<leader>zk', '<cmd>OGPTRun keywords<CR>', desc = 'Keywords', mode = { 'n', 'v' } },
      { '<leader>zd', '<cmd>OGPTRun docstring<CR>', desc = 'Docstring', mode = { 'n', 'v' } },
      { '<leader>za', '<cmd>OGPTRun add_tests<CR>', desc = 'Add Tests', mode = { 'n', 'v' } },
      { '<leader>z<leader>', '<cmd>OGPTRun custom_input<CR>', desc = 'Custom Input', mode = { 'n', 'v' } },
      { '<leader>?', '<cmd>OGPTRun quick_question<CR>', desc = 'Quick Question', mode = { 'n' } },
      { '<leader>zf', '<cmd>OGPTRun fix_bugs<CR>', desc = 'Fix Bugs', mode = { 'n', 'v' } },
      { '<leader>zx', '<cmd>OGPTRun explain_code<CR>', desc = 'Explain Code', mode = { 'n', 'v' } },
    },
    dependencies = {
      'MunifTanjim/nui.nvim',
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
    },
    opts = {
      edgy = false,
      single_window = false,
      yank_register = '+',
      default_provider = 'ollama',
      providers = {
        openai = {
          enabled = true,
          model = 'gpt-4-1106-preview',
          api_host = 'https://api.openai.com',
          api_key = os.getenv 'OPENAI_API_KEY' or '',
          api_params = {
            temperature = 0.5,
            top_p = 0.99,
          },
          api_chat_params = {
            frequency_penalty = 0.8,
            presence_penalty = 0.5,
            temperature = 0.8,
            top_p = 0.99,
          },
        },
        gemini = {
          enabled = false,
        },
        textgenui = {
          enabled = false,
        },
        ollama = {
          enabled = true,
          api_host = 'http://localhost:11434',
          model = 'mistral:7b',
          -- model definitions
          models = {
            -- alias to actual model name, helpful to define same model name across multiple providers
            coder = 'deepseek-coder:6.7b-instruct-q5_K_M',
            general_model = 'mistral:7b',
          },
          -- default model params for all 'actions'
          api_params = {
            model = 'mistral:7b',
            temperature = 0.8,
            top_p = 0.9,
          },
          api_chat_params = {
            model = 'mistral:7b',
            frequency_penalty = 0,
            presence_penalty = 0,
            temperature = 0.5,
            top_p = 0.9,
          },
        },
      },
      edit = {
        layout = 'default',
        edgy = nil, -- use global default
        diff = false,
        keymaps = {
          close = '<C-c>',
          accept = '<C-y>', -- accept the output and write to original buffer
          toggle_diff = '<C-d>', -- view the diff between left and right panes and use diff-mode
          toggle_parameters = '<C-p>', -- Toggle parameters window
          cycle_windows = '<Tab>',
          use_output_as_input = '<C-u>',
        },
      },
      popup = {
        edgy = nil, -- use global default
        position = 1,
        size = {
          width = '40%',
          height = 10,
        },
        padding = { 1, 1, 1, 1 },
        enter = true,
        focusable = true,
        zindex = 50,
        border = {
          style = 'rounded',
        },
        buf_options = {
          modifiable = false,
          readonly = false,
          filetype = 'ogpt-popup',
          syntax = 'markdown',
        },
        win_options = {
          wrap = true,
          linebreak = true,
          winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
        },
        keymaps = {
          close = { '<C-c>', 'q' },
          accept = '<C-y>',
          append = 'a',
          prepend = 'p',
          yank_code = 'c',
          yank_to_register = 'y',
        },
      },
      chat = {
        question_sign = '', -- 🙂
        answer_sign = 'ﮧ', -- 🤖
        border_left_sign = '|',
        border_right_sign = '|',
        max_line_length = 120,
        edgy = nil, -- use global default
        sessions_window = {
          active_sign = ' 󰄵 ',
          inactive_sign = ' 󰄱 ',
          current_line_sign = '',
          border = {
            style = 'rounded',
            text = {
              top = ' Sessions ',
            },
          },
          win_options = {
            winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
          },
          buf_options = {
            filetype = 'ogpt-sessions',
          },
        },
        keymaps = {
          close = { '<C-c>' },
          yank_last = '<C-y>',
          yank_last_code = '<C-i>',
          scroll_up = '<C-u>',
          scroll_down = '<C-d>',
          new_session = '<C-n>',
          cycle_windows = '<Tab>',
          cycle_modes = '<C-f>',
          next_message = 'J',
          prev_message = 'K',
          select_session = '<CR>',
          rename_session = 'r',
          delete_session = 'd',
          draft_message = '<C-d>',
          edit_message = 'e',
          delete_message = 'd',
          toggle_parameters = '<C-p>',
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
          width_parameters_open = '50%',
        },
      },
      output_window = {
        border = {
          highlight = 'FloatBorder',
          style = 'rounded',
          text = {
            top = ' OGPT ',
          },
        },
        win_options = {
          wrap = true,
          linebreak = true,
          foldcolumn = '1',
          winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
        },
        buf_options = {
          filetype = 'ogpt-window',
          syntax = 'markdown',
        },
      },
      util_window = {
        border = {
          highlight = 'FloatBorder',
          style = 'rounded',
        },
        win_options = {
          wrap = true,
          linebreak = true,
          foldcolumn = '2',
          winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
        },
      },
      input_window = {
        prompt = '  ',
        border = {
          highlight = 'FloatBorder',
          style = 'rounded',
          text = {
            top_align = 'center',
            top = ' {{input}} ',
          },
        },
        win_options = {
          winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
        },
        buf_options = {
          filetype = 'ogpt-input',
        },
        submit = '<C-Enter>',
        submit_n = '<Enter>',
        max_visible_lines = 20,
      },
      instruction_window = {
        prompt = '  ',
        border = {
          highlight = 'FloatBorder',
          style = 'rounded',
          text = {
            top_align = 'center',
            top = ' {{instruction}} ',
          },
        },
        win_options = {
          winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
        },
        buf_options = {
          filetype = 'ogpt-instruction',
        },
        submit = '<C-Enter>',
        submit_n = '<Enter>',
        max_visible_lines = 20,
      },
      parameters_window = {
        setting_sign = '  ',
        border = {
          style = 'rounded',
          text = {
            top = ' Parameters ',
          },
        },
        win_options = {
          winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
        },
        buf_options = {
          filetype = 'ogpt-parameters-window',
        },
      },
      actions = {
        -- all strategy "edit" have instruction as input
        edit_code_with_instructions = {
          provider = 'ollama',
          model = 'coder',
          type = 'edit',
          strategy = 'edit_code',
          template = 'Given the follow code snippet, {{instruction}}.\n\nCode:\n```{{filetype}}\n{{input}}\n```',
          delay = true,
          extract_codeblock = true,
          params = {
            -- frequency_penalty = 0,
            -- presence_penalty = 0,
            temperature = 0.5,
            top_p = 0.99,
          },
        },
        -- all strategy "edit" have instruction as input
        edit_with_instructions = {
          provider = 'ollama',
          model = 'coder',
          type = 'edit',
          strategy = 'edit',
          template = 'Given the follow input, {{instruction}}.\n\nInput:\n```{{filetype}}\n{{input}}\n```',
          delay = true,
          params = {
            temperature = 0.5,
            top_p = 0.99,
          },
        },
        grammar_correction = {
          type = 'popup',
          template = 'Correct the given text to standard {{lang}}:\n\n```{{input}}```',
          system = 'You are a helpful note writing assistant, given a text input, correct the text only for grammar and spelling error. You are to keep all formatting the same, e.g. markdown bullets, should stay as a markdown bullet in the result, and indents should stay the same. Return ONLY the corrected text.',
          strategy = 'replace',
          params = {
            temperature = 0.3,
          },
          args = {
            lang = {
              type = 'string',
              optional = 'true',
              default = 'english',
            },
          },
        },
        translate = {
          type = 'popup',
          template = 'Translate this into {{lang}}:\n\n{{input}}',
          strategy = 'display',
          params = {
            temperature = 0.3,
          },
          args = {
            lang = {
              type = 'string',
              optional = 'true',
              default = 'vietnamese',
            },
          },
        },
        keywords = {
          type = 'popup',
          template = 'Extract the main keywords from the following text to be used as document tags.\n\n```{{input}}```',
          strategy = 'display',
          params = {
            model = 'general_model', -- use of model alias, generally, this model alias should be available to all providers in use
            temperature = 0.5,
            frequency_penalty = 0.8,
          },
        },
        do_complete_code = {
          type = 'popup',
          template = 'Code:\n```{{filetype}}\n{{input}}\n```\n\nCompleted Code:\n```{{filetype}}',
          strategy = 'display',
          params = {
            model = 'coder',
            stop = {
              '```',
            },
          },
        },
        quick_question = {
          type = 'popup',
          args = {
            -- template expansion
            question = {
              type = 'string',
              optional = 'true',
              default = function()
                return vim.fn.input 'question: '
              end,
            },
          },
          system = 'You are a helpful assistant',
          template = '{{question}}',
          strategy = 'display',
        },
        custom_input = {
          type = 'popup',
          args = {
            instruction = {
              type = 'string',
              optional = 'true',
              default = function()
                return vim.fn.input 'instruction: '
              end,
            },
          },
          system = 'You are a helpful assistant',
          template = 'Given the follow snippet, {{instruction}}.\n\nsnippet:\n```{{filetype}}\n{{input}}\n```',
          strategy = 'display',
        },
        optimize_code = {
          type = 'popup',
          system = 'You are a helpful coding assistant. Complete the given prompt.',
          template = 'Optimize the code below, following these instructions:\n\n{{instruction}}.\n\nCode:\n```{{filetype}}\n{{input}}\n```\n\nOptimized version:\n```{{filetype}}',
          strategy = 'edit_code',
          params = {
            model = 'coder',
            stop = {
              '```',
            },
          },
        },
      },
    },
  },
}
