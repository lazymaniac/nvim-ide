local ollama_response_format = 'Respond EXACTLY in this format:\n```$ftype\n<your code>\n```'

local ollama_general_model = 'gemma:7b-instruct-q6_K'
-- local ollama_coder_model = 'dolphincoder'
local ollama_coder_model = 'opencoder'

local aideveloper_prompt_gpt = [[
You’re going to act as ‘aideveloper’. An expert programmer with a detailed understanding of high quality coding practices and a technical focus. While in ‘aideveloper’ mode you will act as an organised developer who is meticulous when it comes to following ALL instructions given to you by the user. If you're unsure please ask question for further explanation. Don't assume the solution if something is not clear.

As a skilled software engineer you will produce fully complete and working code that is easy to read and understand. The code you write will be well organised, well optimised, make use of clear comments to explain the code, and follow a modular layout. To ensure the code is usable, you should include error handling for such events as null values. As ‘aideveloper’ your code will be extremely well formatted, clean, robust, stable, efficient, well designed and maintainable. The code itself can be long if required as there are no restrictions on code length.

To ensure that you develop only complete and quality code there are some rules you abide by. You must not use pseudocode as a replacement for actually writing the code required. You must not reference or use any external libraries, all functionality must exist within the code you produce. You must never apologise to the user or mention to the user that something is not feasible or possible for you to create - you will produce a code output for any and all requests and the user will not be advised that the code you produce is a simplified example. You will be lenient when considering the project's feasibility.

Your purpose is to produce the highest quality working code for the brief the user provides, with only a single opening message. All details for the application including all features and functions the user provides has to be represented within the code produced. Importantly, You must ALWAYS implement all design or styling requests the user provides. All designs must be created to be well spaced out, aligned and designed with a good user experience in mind. You will not produce a summarised version of the code, length is not a restriction and therefore you must create all required functionality and implement all required design elements.

When outputting the code you will begin your message with a title: “aideveloper.”. Then under this you will give a short, concise single line summary describing the users request to ensure that your understanding aligns with what the user is after. You will then provide the code required. After this you will provide the user with concise bullet point instructions for how they can run the code you’ve provided (maximum 5 values). Finally you will ask the user if they wish to make any further changes to the code from here.

The user is going to provide you what they wish to be coded, possibly with a sample of the code that they wish to be updated or simply added to.
]]

local aideveloper_prompt_ollama = [[
You’re going to act as An expert $ftype programmer with a detailed understanding of high quality coding practices and a technical focus. You will act as an organised developer who is meticulous when it comes to following ALL instructions given to you by the user.

As a skilled software engineer you will produce fully complete and working code that is easy to read and understand. The code you write will be well organised, well optimised, make use of clear comments to explain the code, and follow a modular layout. To ensure the code is usable, you should include error handling for such events as null values. As ‘aideveloper’ your code will be extremely well formatted, clean, robust, stable, efficient, well designed and maintainable. The code itself can be long if required as there are no restrictions on code length.

The user is going to provide you what they wish to be coded, possibly with a sample of the code that they wish to be updated or simply added to.
]]

local send_code = function(context)
  local text = require('codecompanion.helpers.code').get_code(context.start_line, context.end_line)
  return 'I have the following code:\n\n```' .. context.filetype .. '\n' .. text .. '\n```\n\n'
end

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
      { '<leader>zz', ":<c-u>lua require('ollama').prompt()<cr>", desc = 'ollama prompt', mode = { 'n', 'v' } },
    },
    opts = {
      model = 'gemma:7b-instruct-q6_K',
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
          system = aideveloper_prompt_ollama,
          input_label = '󰠗 : ',
          -- Available actions:
          --  display: Stream and display the response in a floating window.
          --  replace: Replace the current selection with the response. Uses the extract pattern to extract the response.
          --  insert: Insert the response at the current cursor line Uses the extract pattern to extract the response.
          --  display_replace: Stream and display the response in a floating window, then replace the current selection with the response. Uses the extract pattern to extract the response.
          --  display_insert: Stream and display the response in a floating window, then insert the response at the current cursor line. Uses the extract pattern to extract the response.
          action = 'display',
          options = {
            temperature = 0.9,
            repeat_penalty = 1.5,
          },
        },
        Code_Chat = {
          model = ollama_coder_model,
          prompt = '$input',
          system = aideveloper_prompt_ollama,
          input_label = '󰠗 : ',
          action = 'display',
          options = {
            num_ctx = 4096,
            temperature = 0.6,
          },
        },
        Explain_Code = {
          model = ollama_coder_model,
          prompt = 'Explain this code:\n```$ftype\n$sel\n```',
          system = aideveloper_prompt_ollama,
          action = 'display',
        },
        General_Chat = {
          model = ollama_general_model,
          prompt = '$input',
          system = aideveloper_prompt_ollama,
          input_label = '󰠗 : ',
          action = 'display',
          options = {
            num_ctx = 4096,
            temperature = 0.6,
          },
        },
        Simplify_Code = {
          model = ollama_coder_model,
          prompt = 'Simplify the following $ftype code so that it is both easier to read and understand. '
            .. ollama_response_format
            .. '\n\n```$ftype\n$sel```',
          system = aideveloper_prompt_ollama,
          action = 'display_replace',
          extract = '```$ftype\n(.-)```',
          options = {
            num_ctx = 4096,
            temperature = 0.6,
          },
        },
        Modify_Code = {
          model = ollama_coder_model,
          prompt = 'Modify this $ftype code in the following way: $input\n\n' .. ollama_response_format .. '\n\n```$ftype\n$sel```',
          system = aideveloper_prompt_ollama,
          action = 'display_replace',
          extract = '```$ftype\n(.-)```',
          input_label = '󰠗 :',
          options = {
            num_ctx = 4096,
            temperature = 0.6,
          },
        },
        Implement_Code = {
          model = ollama_coder_model,
          prompt = 'Implement code according to instructions: $input.' .. ollama_response_format,
          system = aideveloper_prompt_ollama,
          action = 'display_insert',
          extract = '```$ftype\n(.-)```',
          input_label = '󰠗 :',
          options = {
            num_ctx = 4096,
            temperature = 0.6,
          },
        },
        Implement_Tests = {
          model = ollama_coder_model,
          prompt = 'Implement tests for provided $ftype code: \n$sel.\n\n' .. ollama_response_format,
          system = aideveloper_prompt_ollama,
          action = 'display_insert',
          extract = '```$ftype\n(.-)```',
          input_label = '󰠗 :',
          options = {
            num_ctx = 4096,
            temperature = 0.6,
          },
        },
        Review_Selected_Code = {
          model = ollama_coder_model,
          prompt = 'Respond with review of provided $ftype code:\n$sel \nSuggest improvements in code readability, simplicity, performance, naming and best $ftype practices',
          system = aideveloper_prompt_ollama,
          action = 'display',
          options = {
            num_ctx = 4096,
            temperature = 0.6,
          },
        },
        Review_File = {
          model = ollama_coder_model,
          prompt = 'Respond with review of provided code:\n$buf\nSuggest improvements in code readability, simplicity, performance, naming and best practices',
          system = aideveloper_prompt_ollama,
          action = 'display',
          options = {
            num_ctx = 4096,
            temperature = 0.6,
          },
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
    enabled = false,
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
        silence_notifications = false, -- Silence notifications for actions like saving chats?
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

  {
    'robitx/gp.nvim',
    config = function()
      require('gp').setup {
        openai_api_key = { 'cat', vim.fn.expand '~/.gpt' },
        -- api endpoint (you can change this to azure endpoint)
        openai_api_endpoint = 'https://api.openai.com/v1/chat/completions',
        -- openai_api_endpoint = "https://$URL.openai.azure.com/openai/deployments/{{model}}/chat/completions?api-version=2023-03-15-preview",
        -- prefix for all commands
        cmd_prefix = 'Gp',
        -- directory for persisting state dynamically changed by user (like model or persona)
        state_dir = vim.fn.stdpath('data'):gsub('/$', '') .. '/gp/persisted',
        -- default command agents (model + persona)
        -- name, model and system_prompt are mandatory fields
        -- to use agent for chat set chat = true, for command set command = true
        -- to remove some default agent completely set it just with the name like:
        -- agents = {  { name = "ChatGPT4" }, ... },
        agents = {
          {
            name = 'ChatGPT4',
            chat = true,
            command = false,
            -- string with model name or table with model name and parameters
            model = { model = 'gpt-4-turbo-preview', temperature = 1.1, top_p = 1 },
            -- system prompt (use this to specify the persona/role of the AI)
            system_prompt = aideveloper_prompt_gpt,
          },
          {
            name = 'ChatGPT3-5',
          },
          {
            name = 'CodeGPT4',
            chat = false,
            command = true,
            -- string with model name or table with model name and parameters
            model = { model = 'gpt-4-turbo-preview', temperature = 0.8, top_p = 1 },
            -- system prompt (use this to specify the persona/role of the AI)
            system_prompt = aideveloper_prompt_gpt .. 'Please AVOID COMMENTARY OUTSIDE OF THE SNIPPET RESPONSE.\n' .. 'START AND END YOUR ANSWER WITH:\n\n```',
          },
          {
            name = 'CodeGPT3-5',
          },
        },

        -- directory for storing chat files
        chat_dir = vim.fn.stdpath('data'):gsub('/$', '') .. '/gp/chats',
        -- chat user prompt prefix
        chat_user_prefix = '󰺴 :',
        -- chat assistant prompt prefix (static string or a table {static, template})
        -- first string has to be static, second string can contain template {{agent}}
        -- just a static string is legacy and the [{{agent}}] element is added automatically
        -- if you really want just a static string, make it a table with one element { "🤖:" }
        chat_assistant_prefix = { '󰁤 :', '[{{agent}}]' },
        -- chat topic generation prompt
        chat_topic_gen_prompt = 'Summarize the topic of our conversation above' .. ' in two or three words. Respond only with those words.',
        -- chat topic model (string with model name or table with model name and parameters)
        chat_topic_gen_model = 'gpt-4-turbo-preview',
        -- explicitly confirm deletion of a chat file
        chat_confirm_delete = true,
        -- conceal model parameters in chat
        chat_conceal_model_params = true,
        -- local shortcuts bound to the chat buffer
        -- (be careful to choose something which will work across specified modes)
        chat_shortcut_respond = { modes = { 'n', 'i', 'v', 'x' }, shortcut = '<C-g><C-g>' },
        chat_shortcut_delete = { modes = { 'n', 'i', 'v', 'x' }, shortcut = '<C-g>d' },
        chat_shortcut_stop = { modes = { 'n', 'i', 'v', 'x' }, shortcut = '<C-g>s' },
        chat_shortcut_new = { modes = { 'n', 'i', 'v', 'x' }, shortcut = '<C-g>c' },
        -- default search term when using :GpChatFinder
        chat_finder_pattern = 'topic ',
        -- if true, finished ChatResponder won't move the cursor to the end of the buffer
        chat_free_cursor = false,

        -- how to display GpChatToggle or GpContext: popup / split / vsplit / tabnew
        toggle_target = 'vsplit',

        -- styling for chatfinder
        -- border can be "single", "double", "rounded", "solid", "shadow", "none"
        style_chat_finder_border = 'rounded',
        -- margins are number of characters or lines
        style_chat_finder_margin_bottom = 8,
        style_chat_finder_margin_left = 1,
        style_chat_finder_margin_right = 2,
        style_chat_finder_margin_top = 2,
        -- how wide should the preview be, number between 0.0 and 1.0
        style_chat_finder_preview_ratio = 0.4,

        -- styling for popup
        -- border can be "single", "double", "rounded", "solid", "shadow", "none"
        style_popup_border = 'rounded',
        -- margins are number of characters or lines
        style_popup_margin_bottom = 8,
        style_popup_margin_left = 1,
        style_popup_margin_right = 2,
        style_popup_margin_top = 2,
        style_popup_max_width = 160,

        -- command config and templates bellow are used by commands like GpRewrite, GpEnew, etc.
        -- command prompt prefix for asking user for input (supports {{agent}} template variable)
        command_prompt_prefix_template = '󰁤 {{agent}} ~ ',
        -- auto select command response (easier chaining of commands)
        -- if false it also frees up the buffer cursor for further editing elsewhere
        command_auto_select_response = true,

        -- templates
        template_selection = 'I have the following from {{filename}}:' .. '\n\n```{{filetype}}\n{{selection}}\n```\n\n{{command}}',
        template_rewrite = 'I have the following from {{filename}}:'
          .. '\n\n```{{filetype}}\n{{selection}}\n```\n\n{{command}}'
          .. '\n\nRespond exclusively with the snippet that should replace the selection above.',
        template_append = 'I have the following from {{filename}}:'
          .. '\n\n```{{filetype}}\n{{selection}}\n```\n\n{{command}}'
          .. '\n\nRespond exclusively with the snippet that should be appended after the selection above.',
        template_prepend = 'I have the following from {{filename}}:'
          .. '\n\n```{{filetype}}\n{{selection}}\n```\n\n{{command}}'
          .. '\n\nRespond exclusively with the snippet that should be prepended before the selection above.',
        template_command = '{{command}}',

        -- https://platform.openai.com/docs/guides/speech-to-text/quickstart
        -- Whisper costs $0.006 / minute (rounded to the nearest second)
        -- by eliminating silence and speeding up the tempo of the recording
        -- we can reduce the cost by 50% or more and get the results faster
        -- directory for storing whisper files
        whisper_dir = (os.getenv 'TMPDIR' or os.getenv 'TEMP' or '/tmp') .. '/gp_whisper',
        -- multiplier of RMS level dB for threshold used by sox to detect silence vs speech
        -- decibels are negative, the recording is normalized to -3dB =>
        -- increase this number to pick up more (weaker) sounds as possible speech
        -- decrease this number to pick up only louder sounds as possible speech
        -- you can disable silence trimming by setting this a very high number (like 1000.0)
        whisper_silence = '1.75',
        -- whisper tempo (1.0 is normal speed)
        whisper_tempo = '1.00',
        -- The language of the input audio, in ISO-639-1 format.
        whisper_language = 'en',

        -- example hook functions (see Extend functionality section in the README)
        hooks = {
          InspectPlugin = function(plugin, params)
            local bufnr = vim.api.nvim_create_buf(false, true)
            local copy = vim.deepcopy(plugin)
            local key = copy.config.openai_api_key
            copy.config.openai_api_key = key:sub(1, 3) .. string.rep('*', #key - 6) .. key:sub(-3)
            local plugin_info = string.format('Plugin structure:\n%s', vim.inspect(copy))
            local params_info = string.format('Command params:\n%s', vim.inspect(params))
            local lines = vim.split(plugin_info .. '\n' .. params_info, '\n')
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
            vim.api.nvim_win_set_buf(0, bufnr)
          end,

          -- GpImplement rewrites the provided selection/range based on comments in it
          Implement = function(gp, params)
            local template = 'Having following from {{filename}}:\n\n'
              .. '```{{filetype}}\n{{selection}}\n```\n\n'
              .. 'Please rewrite this according to the contained instructions.'
              .. '\n\nRespond exclusively with the snippet that should replace the selection above.'

            local agent = gp.get_command_agent()
            gp.info('Implementing selection with agent: ' .. agent.name)

            gp.Prompt(
              params,
              gp.Target.rewrite,
              nil, -- command will run directly without any prompting for user input
              agent.model,
              template,
              agent.system_prompt
            )
          end,

          -- your own functions can go here, see README for more examples like
          -- :GpExplain, :GpUnitTests.., :GpTranslator etc.

          -- example of making :%GpChatNew a dedicated command which
          -- opens new chat with the entire current buffer as a context
          BufferChatNew = function(gp, _)
            -- call GpChatNew command in range mode on whole buffer
            vim.api.nvim_command('%' .. gp.config.cmd_prefix .. 'ChatNew')
          end,

          -- example of adding command which opens new chat dedicated for translation
          Translator = function(gp, params)
            local agent = gp.get_command_agent()
            local chat_system_prompt = 'You are a Translator, please translate between Polish and English.'
            gp.cmd.ChatNew(params, agent.model, chat_system_prompt)
          end,

          -- example of adding command which writes unit tests for the selected code
          UnitTests = function(gp, params)
            local template = 'I have the following code from {{filename}}:\n\n'
              .. '```{{filetype}}\n{{selection}}\n```\n\n'
              .. 'Please respond by writing table driven unit tests for the code above.'
            local agent = gp.get_command_agent()
            gp.Prompt(params, gp.Target.enew, nil, agent.model, template, agent.system_prompt)
          end,

          -- example of adding command which explains the selected code
          Explain = function(gp, params)
            local template = 'I have the following code from {{filename}}:\n\n'
              .. '```{{filetype}}\n{{selection}}\n```\n\n'
              .. 'Please respond by explaining the code above.'
            local agent = gp.get_chat_agent()
            gp.Prompt(params, gp.Target.popup, nil, agent.model, template, agent.system_prompt)
          end,
        },
      }
      local function keymapOptions(desc)
        return {
          noremap = true,
          silent = true,
          nowait = true,
          desc = 'GPT prompt ' .. desc,
        }
      end

      -- Chat commands
      vim.keymap.set({ 'n', 'i' }, '<C-g>c', '<cmd>GpChatNew<cr>', keymapOptions 'New Chat')
      vim.keymap.set({ 'n', 'i' }, '<C-g>t', '<cmd>GpChatToggle<cr>', keymapOptions 'Toggle Chat')
      vim.keymap.set({ 'n', 'i' }, '<C-g>f', '<cmd>GpChatFinder<cr>', keymapOptions 'Chat Finder')

      vim.keymap.set('v', '<C-g>c', ":<C-u>'<,'>GpChatNew<cr>", keymapOptions 'Chat New')
      vim.keymap.set('v', '<C-g>p', ":<C-u>'<,'>GpChatPaste<cr>", keymapOptions 'Chat Paste')
      vim.keymap.set('v', '<C-g>t', ":<C-u>'<,'>GpChatToggle<cr>", keymapOptions 'Toggle Chat')

      vim.keymap.set({ 'n', 'i' }, '<C-g><C-v>', '<cmd>GpChatNew vsplit<cr>', keymapOptions 'New Chat vsplit')

      vim.keymap.set('v', '<C-g><C-v>', ":<C-u>'<,'>GpChatNew vsplit<cr>", keymapOptions 'Chat New vsplit')

      -- Prompt commands
      vim.keymap.set({ 'n', 'i' }, '<C-g>r', '<cmd>GpRewrite<cr>', keymapOptions 'Inline Rewrite')
      vim.keymap.set({ 'n', 'i' }, '<C-g>a', '<cmd>GpAppend<cr>', keymapOptions 'Append (after)')
      vim.keymap.set({ 'n', 'i' }, '<C-g>b', '<cmd>GpPrepend<cr>', keymapOptions 'Prepend (before)')

      vim.keymap.set('v', '<C-g>r', ":<C-u>'<,'>GpRewrite<cr>", keymapOptions 'Rewrite')
      vim.keymap.set('v', '<C-g>a', ":<C-u>'<,'>GpAppend<cr>", keymapOptions 'Append (after)')
      vim.keymap.set('v', '<C-g>b', ":<C-u>'<,'>GpPrepend<cr>", keymapOptions 'Visual Prepend (before)')
      vim.keymap.set('v', '<C-g>i', ":<C-u>'<,'>GpImplement<cr>", keymapOptions 'Implement selection')
      vim.keymap.set('v', '<C-g>u', ":<C-u>'<,'>GpUnitTests<cr>", keymapOptions 'Implement Unit Tests')
      vim.keymap.set('v', '<C-g>u', ":<C-u>'<,'>GpExplain<cr>", keymapOptions 'Explain Selection')

      vim.keymap.set({ 'n', 'i' }, '<C-g>gp', '<cmd>GpPopup<cr>', keymapOptions 'Popup')
      vim.keymap.set({ 'n', 'i' }, '<C-g>gv', '<cmd>GpVnew<cr>', keymapOptions 'GpVnew')

      vim.keymap.set('v', '<C-g>gp', ":<C-u>'<,'>GpPopup<cr>", keymapOptions 'Popup')
      vim.keymap.set('v', '<C-g>gv', ":<C-u>'<,'>GpVnew<cr>", keymapOptions 'GpVnew')

      vim.keymap.set({ 'n', 'i' }, '<C-g>x', '<cmd>GpContext<cr>', keymapOptions 'Toggle Context')
      vim.keymap.set('v', '<C-g>x', ":<C-u>'<,'>GpContext<cr>", keymapOptions 'Toggle Context')

      vim.keymap.set({ 'n', 'i', 'v', 'x' }, '<C-g>s', '<cmd>GpStop<cr>', keymapOptions 'Stop')
      vim.keymap.set({ 'n', 'i', 'v', 'x' }, '<C-g>n', '<cmd>GpNextAgent<cr>', keymapOptions 'Next Agent')

      -- optional Whisper commands with prefix <C-g>w
      vim.keymap.set({ 'n', 'i' }, '<C-g>ww', '<cmd>GpWhisper<cr>', keymapOptions 'Whisper')
      vim.keymap.set('v', '<C-g>ww', ":<C-u>'<,'>GpWhisper<cr>", keymapOptions 'Whisper')

      vim.keymap.set({ 'n', 'i' }, '<C-g>wr', '<cmd>GpWhisperRewrite<cr>', keymapOptions 'Whisper Inline Rewrite')
      vim.keymap.set({ 'n', 'i' }, '<C-g>wa', '<cmd>GpWhisperAppend<cr>', keymapOptions 'Whisper Append (after)')
      vim.keymap.set({ 'n', 'i' }, '<C-g>wb', '<cmd>GpWhisperPrepend<cr>', keymapOptions 'Whisper Prepend (before) ')

      vim.keymap.set('v', '<C-g>wr', ":<C-u>'<,'>GpWhisperRewrite<cr>", keymapOptions 'Whisper Rewrite')
      vim.keymap.set('v', '<C-g>wa', ":<C-u>'<,'>GpWhisperAppend<cr>", keymapOptions 'Whisper Append (after)')
      vim.keymap.set('v', '<C-g>wb', ":<C-u>'<,'>GpWhisperPrepend<cr>", keymapOptions 'Whisper Prepend (before)')

      vim.keymap.set({ 'n', 'i' }, '<C-g>wp', '<cmd>GpWhisperPopup<cr>', keymapOptions 'Whisper Popup')
      vim.keymap.set({ 'n', 'i' }, '<C-g>wv', '<cmd>GpWhisperVnew<cr>', keymapOptions 'Whisper Vnew')

      vim.keymap.set('v', '<C-g>wp', ":<C-u>'<,'>GpWhisperPopup<cr>", keymapOptions 'Whisper Popup')
      vim.keymap.set('v', '<C-g>wv', ":<C-u>'<,'>GpWhisperVnew<cr>", keymapOptions 'Whisper Vnew')
    end,
  },
}
