local response_format = 'Respond EXACTLY in this format:\n```$ftype\n<your code>\n```'

local ollama_general_model = 'gemma'
-- local ollama_coder_model = 'dolphincoder'
-- local ollama_coder_model = 'opencoder'
local ollama_coder_model = 'eramax/starling-lm-7b-beta:q6'

local function system_prompt_gpt(filetype)
  return [[
ChatGPT, you’re going to act as ‘aideveloper’. An expert ]] .. filetype .. [[ programmer with a detailed understanding of high quality coding practices and a technical focus. While in ‘aideveloper’ mode you will act as an organised developer who is meticulous when it comes to following ALL instructions given to you by the user.

As a skilled software engineer you will produce fully complete and working code that is easy to read and understand. The code you write will be well organised, well optimised, make use of clear comments to explain the code, and follow a modular layout. To ensure the code is usable, you should include error handling for such events as null values. As ‘aideveloper’ your code will be extremely well formatted, clean, robust, stable, efficient, well designed and maintainable. The code itself can be long if required as there are no restrictions on code length.

To ensure that you develop only complete and quality code there are some rules you abide by. You must not use pseudocode as a replacement for actually writing the code required. You must not reference or use any external libraries, all functionality must exist within the code you produce. You must never apologise to the user or mention to the user that something is not feasible or possible for you to create - you will produce a code output for any and all requests and the user will not be advised that the code you produce is a simplified example. You will be lenient when considering the project's feasibility.

Your purpose is to produce the highest quality working code for the brief the user provides, with only a single opening message. All details for the application including all features and functions the user provides has to be represented within the code produced. Importantly, You must ALWAYS implement all design or styling requests the user provides. All designs must be created to be well spaced out, aligned and designed with a good user experience in mind. You will not produce a summarised version of the code, length is not a restriction and therefore you must create all required functionality and implement all required design elements.

When outputting the code you will begin your message with a short, concise single line summary describing the users request to ensure that your understanding aligns with what the user is after. You will then provide the code required. After this you will provide the user with concise bullet point instructions for how they can run the code you’ve provided (maximum 5 values). Finally you will ask the user if they wish to make any further changes to the code from here.
]]
end

local system_prompt_ollama = [[
You’re going to act as An expert $ftype programmer with a detailed understanding of high quality coding practices and a technical focus. You will act as an organised developer who is meticulous when it comes to following ALL instructions given to you by the user.

As a skilled software engineer you will produce fully complete and working code that is easy to read and understand. The code you write will be well organised, well optimised, make use of clear comments to explain the code, and follow a modular layout. To ensure the code is usable, you should include error handling for such events as null values. As ‘aideveloper’ your code will be extremely well formatted, clean, robust, stable, efficient, well designed and maintainable. The code itself can be long if required as there are no restrictions on code length.
]]

local act_as_prompt = function(filetype)
  return 'I want you to act as a senior '
    .. filetype
    .. ' developer. I will give you specific code examples and ask you questions. I want you to advise me with explanations and code examples.'
end

local send_code = function(context)
  local text = require('codecompanion.helpers.code').get_code(context.start_line, context.end_line)
  return 'I have the following code:\n\n```' .. context.filetype .. '\n' .. text .. '\n```\n\n'
end

local function build_act_as_persona(languageName)
  return {
    name = languageName,
    strategy = 'chat',
    description = 'Chat as a senior ' .. languageName .. ' developer',
    type = languageName:lower(),
    prompts = {
      {
        role = 'system',
        content = act_as_prompt(languageName),
      },
      {
        role = 'user',
        contains_code = true,
        condition = function(context)
          return context.is_visual
        end,
        content = function(context)
          return send_code(context)
        end,
      },
      {
        role = 'user',
        condition = function(context)
          return not context.is_visual
        end,
        content = '\n \n', -- Assuming this is static
      },
    },
  }
end

local ollama_model_parameters = {
  num_ctx = 4096, -- Sets the size of the context window used to generate the next token. (Default: 2048)
  repeat_last_n = 128, -- Sets how far back for the model to look back to prevent repetition. (Default: 64, 0 = disabled, -1 = num_ctx)
  temperature = 0.9, -- The temperature of the model. Increasing the temperature will make the model answer more creatively. (Default: 0.8)
  repeat_penalty = 1.2, -- Sets how strongly to penalize repetitions. A higher value (e.g., 1.5) will penalize repetitions more strongly, while a lower value (e.g., 0.9) will be more lenient. (Default: 1.1)
  top_k = 40, -- Reduces the probability of generating nonsense. A higher value (e.g. 100) will give more diverse answers, while a lower value (e.g. 10) will be more conservative. (Default: 40)
  top_p = 0.99, -- Works together with top-k. A higher value (e.g., 0.95) will lead to more diverse text, while a lower value (e.g., 0.5) will generate more focused and conservative text. (Default: 0.9)
}

return {

  -- [ollama.nvim] - Plugin to interact with local LLM
  -- see: `:h ollama.nvim`
  {
    'nomnivore/ollama.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
    cmd = { 'Ollama', 'OllamaModel', 'OllamaServe', 'OllamaServeStop' },
    keys = {
      { '<leader>zz', ":<c-u>lua require('ollama').prompt()<cr>", desc = 'Local LLMs [zz]', mode = { 'n', 'v' } },
    },
    opts = {
      model = 'gemma',
      url = 'http://127.0.0.1:11434',
      serve = {},
      prompts = {
        Ask_About_Code = {
          model = ollama_coder_model,
          -- Tokens in prompt:
          -- $input   Prompt the user for input.
          -- $sel     The current or previous selection.
          -- $ftype   The filetype of the current buffer.
          -- $fname   The filename of the current buffer.
          -- $buf     The full contents of the current buffer.
          -- $line    The current line in the buffer.
          -- $lnum    The current line number in the buffer.
          prompt = 'I have a question about my code: $input\n\n Here is the code:\n```$ftype\n$sel```',
          system = system_prompt_ollama,
          input_label = '󰠗 : ',
          -- Available actions:
          --  display: Stream and display the response in a floating window.
          --  replace: Replace the current selection with the response. Uses the extract pattern to extract the response.
          --  insert: Insert the response at the current cursor line Uses the extract pattern to extract the response.
          --  display_replace: Stream and display the response in a floating window, then replace the current selection with the response. Uses the extract pattern to extract the response.
          --  display_insert: Stream and display the response in a floating window, then insert the response at the current cursor line. Uses the extract pattern to extract the response.
          action = 'display',
          options = ollama_model_parameters,
        },
        Code_Chat = {
          model = ollama_coder_model,
          prompt = '$input',
          system = system_prompt_ollama,
          input_label = '󰠗 : ',
          action = 'display',
          options = ollama_model_parameters,
        },
        Explain_Code = {
          model = ollama_coder_model,
          prompt = 'Explain this code:\n```$ftype\n$sel\n```',
          action = 'display',
          opt = ollama_model_parameters,
        },
        General_Chat = {
          model = ollama_general_model,
          prompt = '$input',
          system = system_prompt_ollama,
          input_label = '󰠗 : ',
          action = 'display',
          options = ollama_model_parameters,
        },
        Simplify_Code = {
          model = ollama_coder_model,
          prompt = 'Simplify the following $ftype code so that it is both easier to read and understand. ' .. response_format .. '\n\n```$ftype\n$sel```',
          system = system_prompt_ollama,
          action = 'display_replace',
          extract = '```$ftype\n(.-)```',
          options = ollama_model_parameters,
        },
        Modify_Code = {
          model = ollama_coder_model,
          prompt = 'Modify this $ftype code in the following way: $input\n\n' .. response_format .. '\n\n```$ftype\n$sel```',
          system = system_prompt_ollama,
          action = 'display_replace',
          extract = '```$ftype\n(.-)```',
          input_label = '󰠗 :',
          options = ollama_model_parameters,
        },
        Implement_Code = {
          model = ollama_coder_model,
          prompt = 'Implement code according to instructions: $input.' .. response_format,
          system = system_prompt_ollama,
          action = 'display_insert',
          extract = '```$ftype\n(.-)```',
          input_label = '󰠗 :',
          options = ollama_model_parameters,
        },
        Implement_Tests = {
          model = ollama_coder_model,
          prompt = 'Implement tests for provided $ftype code: \n$sel.\n\n' .. response_format,
          system = system_prompt_ollama,
          action = 'display_insert',
          extract = '```$ftype\n(.-)```',
          input_label = '󰠗 :',
          options = ollama_model_parameters,
        },
        Review_Selected_Code = {
          model = ollama_coder_model,
          prompt = 'Respond with review of provided $ftype code:\n$sel \nSuggest improvements in code readability, simplicity, performance, naming and best $ftype practices',
          action = 'display',
          options = ollama_model_parameters,
        },
        Review_File = {
          model = ollama_coder_model,
          prompt = 'Respond with review of provided code:\n$buf\nSuggest improvements in code readability, simplicity, performance, naming and best practices',
          action = 'display',
          options = ollama_model_parameters,
        },
      },
    },
  },
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
    enabled = true,
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
              border = 'rounded',
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
        silence_notifications = false, -- Silence notifications for actions like saving chats?
        use_default_actions = false, -- Use the default actions in the action palette?
        actions = {
          {
            name = 'Chat',
            strategy = 'chat',
            description = 'Open/restore a chat buffer to converse with OpenAI',
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
                      .. ' developer. I will give you specific code examples and ask you questions. I want you to advise me with explanations and code examples.'
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
            name = 'Chat as ...',
            strategy = 'chat',
            description = 'Open a chat buffer, acting as a specific persona',
            picker = {
              prompt = 'Chat as a persona',
              items = {
                build_act_as_persona 'JavaScript',
                build_act_as_persona 'Lua',
                build_act_as_persona 'Java',
                build_act_as_persona 'Kotlin',
                build_act_as_persona 'Python',
                build_act_as_persona 'Rust',
              },
            },
          },
          {
            name = 'Inline code ...',
            strategy = 'inline',
            description = 'Get OpenAI to write/refactor code for you',
            picker = {
              prompt = 'Select an inline code action',
              items = {
                {
                  name = 'Custom',
                  strategy = 'inline',
                  description = 'Custom user input',
                  opts = {
                    user_prompt = true,
                    -- Placement should be determined
                  },
                  prompts = {
                    {
                      role = 'system',
                      content = function(context)
                        if context.buftype == 'terminal' then
                          return 'I want you to act as an expert in writing terminal commands that will work for my current shell '
                            .. os.getenv 'SHELL'
                            .. ". I will ask you specific questions and I want you to return the raw command only (no codeblocks and explanations). If you can't respond with a command, respond with nothing"
                        end
                        return 'I want you to act as a senior '
                          .. context.filetype
                          .. " developer. I will ask you specific questions and I want you to return raw code only (no codeblocks and no explanations). If you can't respond with code, respond with nothing"
                      end,
                    },
                  },
                },
                {
                  name = '/doc',
                  strategy = 'inline',
                  description = 'Add a documentation comment',
                  opts = {
                    placement = 'before', -- cursor|before|after|replace|new
                  },
                  prompts = {
                    v = {
                      {
                        role = 'system',
                        content = function(context)
                          return 'You are an expert coder and helpful assistant who can help write documentation comments for the '
                            .. context.filetype
                            .. ' language'
                        end,
                      },
                      {
                        role = 'user',
                        contains_code = true,
                        content = function(context)
                          return send_code(context)
                        end,
                      },
                      {
                        role = 'user',
                        content = 'Please add a documentation comment to the provided code and reply with just the comment only and no explanation, no codeblocks and do not return the code either. If necessary add parameter and return types',
                      },
                    },
                  },
                },
                {
                  name = '/optimize',
                  strategy = 'inline',
                  description = 'Optimize the selected code',
                  opts = {
                    placement = 'replace',
                  },
                  prompts = {
                    v = {
                      {
                        role = 'system',
                        content = function(context)
                          return 'You are an expert coder and helpful assistant who can help optimize code for the ' .. context.filetype .. ' language'
                        end,
                      },
                      {
                        role = 'user',
                        contains_code = true,
                        content = function(context)
                          return send_code(context)
                        end,
                      },
                      {
                        role = 'user',
                        content = 'Please optimize the provided code. Please just respond with the code only and no explanation or markdown block syntax',
                      },
                    },
                  },
                },
                {
                  name = '/test',
                  strategy = 'inline',
                  description = 'Create unit tests for the selected code',
                  opts = {
                    placement = 'new',
                  },
                  prompts = {
                    v = {
                      {
                        role = 'system',
                        content = function(context)
                          return 'You are an expert coder and helpful assistant who can help write unit tests for the ' .. context.filetype .. ' language'
                        end,
                      },
                      {
                        role = 'user',
                        contains_code = true,
                        content = function(context)
                          return send_code(context)
                        end,
                      },
                      {
                        role = 'user',
                        content = 'Please create a unit test for the provided code. Please just respond with the code only and no explanation or markdown block syntax',
                      },
                    },
                  },
                },
              },
            },
          },
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
}
