return {

  -- [[ AI ]] ---------------------------------------------------------------

  -- [codecompanion.nvim] - Integrates LLMs with neovim
  -- see: `:h codecompanion.txt`
  -- link: https://github.com/olimorris/codecompanion.nvim
  {
    'olimorris/codecompanion.nvim',
    event = 'VeryLazy',
    branch = 'main',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-treesitter/nvim-treesitter', 'nvim-telescope/telescope.nvim', 'stevearc/dressing.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>zi', '<cmd>CodeCompanion<cr>', mode = { 'n', 'v' }, desc = 'Inline Prompt [zi]' },
      { '<leader>zz', '<cmd>CodeCompanionChat<cr>', mode = { 'n', 'v' }, desc = 'Open Chat [zz]' },
      { '<leader>zt', '<cmd>CodeCompanionToggle<cr>', mode = { 'n', 'v' }, desc = 'Toggle Chat [zt]' },
      { '<leader>za', '<cmd>CodeCompanionActions<cr>', mode = { 'n', 'v' }, desc = 'Actions [za]' },
      { '<leader>zp', '<cmd>CodeCompanionAdd<cr>', mode = { 'v' }, desc = 'Paste Selected to the Chat [zp]' },
    },
    config = function()
      local wk = require 'which-key'
      local defaults = {
        { '<leader>z', group = '+[AI]' },
      }
      wk.add(defaults)
      require('codecompanion').setup {
        adapters = {
          anthropic = function()
            return require('codecompanion.adapters').extend('anthropic', {
              env = {
                api_key = 'cmd:echo $ANTHROPIC_API_KEY',
              },
            })
          end,
          ollama = function()
            return require('codecompanion.adapters').extend('ollama', {
              schema = {
                model = {
                  default = 'qwen2.5-coder:7b-instruct-q8_0',
                },
              },
            })
          end,
        },
        strategies = {
          -- CHAT STRATEGY ----------------------------------------------------------
          chat = {
            adapter = 'anthropic',
            roles = {
              llm = 'Agent', -- The markdown header content for the LLM's responses
              user = 'Me', -- The markdown header for your questions
            },
          },
          -- INLINE STRATEGY --------------------------------------------------------
          inline = {
            adapter = 'anthropic',
          },
          -- AGENT STRATEGY ---------------------------------------------------------
          agent = {
            adapter = 'anthropic',
          },
        },
        -- DISPLAY OPTIONS ----------------------------------------------------------
        display = {
          action_palette = {
            width = 95,
            height = 10,
          },
          chat = {
            window = {
              layout = 'vertical', -- float|vertical|horizontal|buffer
              border = 'single',
              height = 0.8,
              width = 0.4,
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
            intro_message = 'Welcome to CodeCompanion ✨! Press ? for options',
            messages_separator = '─', -- The separator between the different messages in the chat buffer
            show_separator = true, -- Show a separator between LLM responses?
            show_settings = true, -- Show LLM settings at the top of the chat buffer?
            show_token_count = true, -- Show the token count for each response?
          },
          inline = {
            -- If the inline prompt creates a new buffer, how should we display this?
            layout = 'vertical', -- vertical|horizontal|buffer
            diff = {
              enabled = true,
              priority = 130,
              highlights = {
                removed = 'DiffDelete',
              },
            },
          },
        },
        -- GENERAL OPTIONS ----------------------------------------------------------
        opts = {
          log_level = 'ERROR', -- TRACE|DEBUG|ERROR|INFO
          -- If this is false then any default prompt that is marked as containing code
          -- will not be sent to the LLM. Please note that whilst I have made every
          -- effort to ensure no code leakage, using this is at your own risk
          send_code = true,
          use_default_actions = true, -- Show the default actions in the action palette?
          use_default_prompts = true, -- Show the default prompts in the action palette?
        },
      }
    end,
  },
}
