return {

  -- [[ AI ]] ---------------------------------------------------------------

  {
    'huynle/ogpt.nvim',
    event = 'VeryLazy',
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
      { '<leader>zt', '<cmd>OGPTRun translate<CR>', desc = 'Translate', mode = { 'n', 'v' } },
      { '<leader>zk', '<cmd>OGPTRun keywords<CR>', desc = 'Keywords', mode = { 'n', 'v' } },
      { '<leader>zr', '<cmd>OGPTRun do_complete_code<CR>', desc = 'Complete Code', mode = { 'n', 'v' } },
      { '<leader>?', '<cmd>OGPTRun quick_question<CR>', desc = 'Quick Question', mode = { 'n' } },
      { '<leader>zi', '<cmd>OGPTRun optimize_code<CR>', desc = 'Optimize Code', mode = { 'n', 'v' } },
      { '<leader>zd', '<cmd>OGPTRun docstring<CR>', desc = 'Docstring', mode = { 'n', 'v' } },
      { '<leader>za', '<cmd>OGPTRun add_tests<CR>', desc = 'Add Tests', mode = { 'n', 'v' } },
      { '<leader>z<leader>', '<cmd>OGPTRun custom_input<CR>', desc = 'Custom Input', mode = { 'n', 'v' } },
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
          model = 'gpt-4',
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
        anthropic = {
          enabled = false,
        },
        textgenui = {
          enabled = false,
        },
        ollama = {
          enabled = true,
          api_host = 'http://localhost:11434',
          api_key = os.getenv 'OLLAMA_API_KEY' or '',
          models = {
            {
              name = 'nous-hermes2:10.7b-solar-q5_K_M',
            },
          },
          model = {
            name = 'nous-hermes2:10.7b-solar-q5_K_M',
            system_message = nil,
          },
          api_params = {
            model = nil,
            temperature = 0.5,
            top_p = 0.99,
          },
          api_chat_params = {
            model = nil,
            temperature = 0.8,
            top_p = 0.99,
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
        dynamic_resize = true,
        position = {
          row = 0,
          col = 30,
        },
        relative = 'cursor',
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
        loading_text = 'Loading, please wait ...',
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
            top = ' {{{input}}} ',
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
            top = ' {{{instruction}}} ',
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
          type = 'edit',
          strategy = 'edit_code',
          template = 'Given the follow code snippet, {{{instruction}}}.\n\nCode:\n```{{{filetype}}}\n{{{input}}}\n```',
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
          -- if not specified, will use default provider
          -- provider = "ollama",
          -- model = "mistral:7b",
          type = 'edit',
          strategy = 'edit',
          template = 'Given the follow input, {{{instruction}}}.\n\nInput:\n```{{{filetype}}}\n{{{input}}}\n```',
          delay = true,
          params = {
            temperature = 0.5,
            top_p = 0.99,
          },
        },
        grammar_correction = {
          type = 'popup',
          template = 'Correct the given text to standard {{{lang}}}:\n\n```{{{input}}}```',
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
          template = 'Translate this into {{{lang}}}:\n\n{{{input}}}',
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
          template = 'Extract the main keywords from the following text to be used as document tags.\n\n```{{{input}}}```',
          strategy = 'display',
          params = {
            model = 'general_model', -- use of model alias, generally, this model alias should be available to all providers in use
            temperature = 0.5,
            frequency_penalty = 0.8,
          },
        },
        do_complete_code = {
          type = 'popup',
          template = 'Code:\n```{{{filetype}}}\n{{{input}}}\n```\n\nCompleted Code:\n```{{{filetype}}}',
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
          template = '{{{question}}}',
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
          template = 'Given the follow snippet, {{{instruction}}}.\n\nsnippet:\n```{{{filetype}}}\n{{{input}}}\n```',
          strategy = 'display',
        },
        optimize_code = {
          type = 'popup',
          system = 'You are a helpful coding assistant. Complete the given prompt.',
          template = 'Optimize the code below, following these instructions:\n\n{{{instruction}}}.\n\nCode:\n```{{{filetype}}}\n{{{input}}}\n```\n\nOptimized version:\n```{{{filetype}}}',
          strategy = 'edit_code',
          params = {
            model = 'coder',
            stop = {
              '```',
            },
          },
        },
      },
      show_quickfixes_cmd = 'Trouble quickfix',
    },
  },
}
