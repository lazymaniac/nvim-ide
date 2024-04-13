local openai_model = 'gpt-4-turbo'
-- local ollama_chat_model = 'openhermes' -- 7B model
local ollama_general_model = 'mixtral' -- 30B model
-- local ollama_coder_model = 'deepseek-coder:6.7b-instruct' -- 7B model
local ollama_coder_model = 'deepseek-coder:33b-instruct-q5_K_M' -- 30B model

local function system_prompt_expert_coder(filetype)
  return 'You’re going to act as an expert '
    .. filetype
    .. [[ programmer with a detailed understanding of high quality coding practices and a technical focus. You will act as an organised developer who is meticulous when it comes to following ALL instructions given to you by the user.

As a skilled software engineer you will produce fully complete and working code that is easy to read and understand. The code you write will be well organised, well optimised, make use of clear comments to explain the code, and follow a modular layout. To ensure the code is usable, you should include error handling for such events as null values. As ]]
    .. filetype
    .. [[ Your code will be extremely well formatted, clean, robust, stable, efficient, well designed and maintainable. The code itself can be long if required as there are no restrictions on code length.
]]
end

local function get_ollama_models()
  local handle = io.popen 'ollama list'
  local result = {}

  if handle then
    for line in handle:lines() do
      local first_word = line:match '%S+'
      if first_word ~= nil and first_word ~= 'NAME' then
        table.insert(result, first_word)
      end
    end

    handle:close()
  end
  return result
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

  -- [codecompanion.nvim] - Integrates LLMs with neovim
  -- see: `:h codecompanion.nvim`
  {
    'olimorris/codecompanion.nvim',
    enabled = true,
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter', 'nvim-telescope/telescope.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>zi', '<cmd>CodeCompanion<cr>', mode = { 'n', 'v' }, desc = 'Inline Prompt [zi]' },
      { '<leader>zz', '<cmd>CodeCompanionChat ollama<cr>', mode = { 'n', 'v' }, desc = 'Chat Ollama [zz]' },
      { '<leader>zo', '<cmd>CodeCompanionChat openai<cr>', mode = { 'n', 'v' }, desc = 'Chat OpenAI [zz]' },
      { '<leader>zt', '<cmd>CodeCompanionToggle<cr>', mode = { 'n', 'v' }, desc = 'Toggle [zt]' },
      { '<leader>za', '<cmd>CodeCompanionActions<cr>', mode = { 'n', 'v' }, desc = 'Actions [za]' },
      { '<leader>zp', '<cmd>CodeCompanionAdd<cr>', mode = { 'v' }, desc = 'Paste Selected to Chat [zp]' },
    },
    config = function()
      require('codecompanion').setup {
        adapters = {
          openai = require('codecompanion.adapters').use('openai', {
            schema = {
              model = {
                default = openai_model,
              },
              temperature = {
                default = 0.8,
              },
            },
            env = {
              api_key = 'cmd:cat ' .. vim.fn.expand '~/.gpt',
            },
          }),
          ollama = require('codecompanion.adapters').use('ollama', {
            schema = {
              model = {
                default = ollama_coder_model,
                choices = get_ollama_models(),
              },
              temperature = {
                default = 0.8,
              },
            },
          }),
        },
        strategies = {
          chat = 'ollama',
          inline = 'ollama',
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
            name = 'Coding Expert Chat',
            strategy = 'chat',
            description = 'Open/restore a chat buffer to converse with Coding Expert',
            prompts = {
              n = function()
                return require('codecompanion').chat()
              end,
              v = {
                {
                  role = 'system',
                  content = function(context)
                    return system_prompt_expert_coder(context.filetype)
                  end,
                },
                {
                  role = 'user',
                  contains_code = false,
                },
              },
            },
          },
        },
      }
    end,
  },
}
