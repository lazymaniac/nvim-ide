return {
  {
    'robitx/gp.nvim',
    config = function()
      require('gp').setup {
        -- shortcuts might be setup here (see Usage > Shortcuts in Readme)
        -- Please start with minimal config possible.
        -- Just openai_api_key if you don't have OPENAI_API_KEY env set up.
        -- Defaults change over time to improve things, options might get deprecated.
        -- It's better to change only things where the default doesn't fit your needs.

        -- required openai api key (string or table with command and arguments)
        -- openai_api_key = { "cat", "path_to/openai_api_key" },
        -- openai_api_key = { "bw", "get", "password", "OPENAI_API_KEY" },
        -- openai_api_key: "sk-...",
        -- openai_api_key = os.getenv("env_name.."),
        openai_api_key = { 'cat', vim.fn.expand '~/.gpt' },

        -- how to display GpChatToggle or GpContext: popup / split / vsplit / tabnew
        toggle_target = 'vsplit',

        -- styling for chatfinder
        -- border can be "single", "double", "rounded", "solid", "shadow", "none"
        style_chat_finder_border = 'rounded',

        -- styling for popup
        -- border can be "single", "double", "rounded", "solid", "shadow", "none"
        style_popup_border = 'rounded',
      }
      require('which-key').register({
        -- VISUAL mode
        ['<leader>z'] = {
          name = '+[AI]',
          c = { ":<C-u>'<,'>GpChatNew popup<cr>", 'Chat New' },
          p = { ":<C-u>'<,'>GpChatPaste popup<cr>", 'Chat Paste' },
          t = { ":<C-u>'<,'>GpChatToggle popup<cr>", 'Toggle Chat' },

          ['|'] = { ":<C-u>'<,'>GpChatNew split<cr>", 'Chat New split' },

          r = { ":<C-u>'<,'>GpRewrite<cr>", 'Rewrite' },
          a = { ":<C-u>'<,'>GpAppend<cr>", 'Append (after)' },
          b = { ":<C-u>'<,'>GpPrepend<cr>", 'Prepend (before)' },
          i = { ":<C-u>'<,'>GpImplement<cr>", 'Implement selection' },

          g = {
            name = 'generate into new ..',
            p = { ":<C-u>'<,'>GpPopup<cr>", 'Popup' },
            e = { ":<C-u>'<,'>GpEnew<cr>", 'GpEnew' },
            n = { ":<C-u>'<,'>GpNew<cr>", 'GpNew' },
            v = { ":<C-u>'<,'>GpVnew<cr>", 'GpVnew' },
            t = { ":<C-u>'<,'>GpTabnew<cr>", 'GpTabnew' },
          },

          n = { '<cmd>GpNextAgent<cr>', 'Next Agent' },
          s = { '<cmd>GpStop<cr>', 'GpStop' },
          x = { ":<C-u>'<,'>GpContext<cr>", 'GpContext' },

          w = {
            name = 'Whisper',
            w = { ":<C-u>'<,'>GpWhisper<cr>", 'Whisper' },
            r = { ":<C-u>'<,'>GpWhisperRewrite<cr>", 'Whisper Rewrite' },
            a = { ":<C-u>'<,'>GpWhisperAppend<cr>", 'Whisper Append (after)' },
            b = { ":<C-u>'<,'>GpWhisperPrepend<cr>", 'Whisper Prepend (before)' },
            p = { ":<C-u>'<,'>GpWhisperPopup<cr>", 'Whisper Popup' },
            e = { ":<C-u>'<,'>GpWhisperEnew<cr>", 'Whisper Enew' },
            n = { ":<C-u>'<,'>GpWhisperNew<cr>", 'Whisper New' },
            v = { ":<C-u>'<,'>GpWhisperVnew<cr>", 'Whisper Vnew' },
            t = { ":<C-u>'<,'>GpWhisperTabnew<cr>", 'Whisper Tabnew' },
          },
        },
      }, {
        mode = 'v', -- VISUAL mode
        prefix = '',
        buffer = nil,
        silent = true,
        noremap = true,
        nowait = true,
      })

      -- NORMAL mode mappings
      require('which-key').register({
        ['<leader>z'] = {
          name = '+[AI]',
          c = { '<cmd>GpChatNew popup<cr>', 'New Chat' },
          t = { '<cmd>GpChatToggle popup<cr>', 'Toggle Chat' },
          f = { '<cmd>GpChatFinder popup<cr>', 'Chat Finder' },

          ['|'] = { '<cmd>GpChatNew split<cr>', 'New Chat split' },

          r = { '<cmd>GpRewrite<cr>', 'Inline Rewrite' },
          a = { '<cmd>GpAppend<cr>', 'Append (after)' },
          b = { '<cmd>GpPrepend<cr>', 'Prepend (before)' },

          g = {
            name = 'generate into new ..',
            p = { '<cmd>GpPopup<cr>', 'Popup' },
            e = { '<cmd>GpEnew<cr>', 'GpEnew' },
            n = { '<cmd>GpNew<cr>', 'GpNew' },
            v = { '<cmd>GpVnew<cr>', 'GpVnew' },
            t = { '<cmd>GpTabnew<cr>', 'GpTabnew' },
          },

          n = { '<cmd>GpNextAgent<cr>', 'Next Agent' },
          s = { '<cmd>GpStop<cr>', 'GpStop' },
          x = { '<cmd>GpContext<cr>', 'Toggle GpContext' },

          w = {
            name = 'Whisper',
            w = { '<cmd>GpWhisper<cr>', 'Whisper' },
            r = { '<cmd>GpWhisperRewrite<cr>', 'Whisper Inline Rewrite' },
            a = { '<cmd>GpWhisperAppend<cr>', 'Whisper Append (after)' },
            b = { '<cmd>GpWhisperPrepend<cr>', 'Whisper Prepend (before)' },
            p = { '<cmd>GpWhisperPopup<cr>', 'Whisper Popup' },
            e = { '<cmd>GpWhisperEnew<cr>', 'Whisper Enew' },
            n = { '<cmd>GpWhisperNew<cr>', 'Whisper New' },
            v = { '<cmd>GpWhisperVnew<cr>', 'Whisper Vnew' },
            t = { '<cmd>GpWhisperTabnew<cr>', 'Whisper Tabnew' },
          },
        },
      }, {
        mode = 'n', -- NORMAL mode
        prefix = '',
        buffer = nil,
        silent = true,
        noremap = true,
        nowait = true,
      })

      -- INSERT mode mappings
      require('which-key').register({
        ['<C-g>'] = {
          name = '+[AI]',
          c = { '<cmd>GpChatNew popup<cr>', 'New Chat' },
          t = { '<cmd>GpChatToggle<cr>', 'Toggle Chat' },
          f = { '<cmd>GpChatFinder<cr>', 'Chat Finder' },

          ['<C-x>'] = { '<cmd>GpChatNew split<cr>', 'New Chat split' },
          ['<C-v>'] = { '<cmd>GpChatNew vsplit<cr>', 'New Chat vsplit' },
          ['<C-t>'] = { '<cmd>GpChatNew tabnew<cr>', 'New Chat tabnew' },

          r = { '<cmd>GpRewrite<cr>', 'Inline Rewrite' },
          a = { '<cmd>GpAppend<cr>', 'Append (after)' },
          b = { '<cmd>GpPrepend<cr>', 'Prepend (before)' },

          g = {
            name = 'generate into new ..',
            p = { '<cmd>GpPopup<cr>', 'Popup' },
            e = { '<cmd>GpEnew<cr>', 'GpEnew' },
            n = { '<cmd>GpNew<cr>', 'GpNew' },
            v = { '<cmd>GpVnew<cr>', 'GpVnew' },
            t = { '<cmd>GpTabnew<cr>', 'GpTabnew' },
          },

          x = { '<cmd>GpContext<cr>', 'Toggle GpContext' },
          s = { '<cmd>GpStop<cr>', 'GpStop' },
          n = { '<cmd>GpNextAgent<cr>', 'Next Agent' },

          w = {
            name = 'Whisper',
            w = { '<cmd>GpWhisper<cr>', 'Whisper' },
            r = { '<cmd>GpWhisperRewrite<cr>', 'Whisper Inline Rewrite' },
            a = { '<cmd>GpWhisperAppend<cr>', 'Whisper Append (after)' },
            b = { '<cmd>GpWhisperPrepend<cr>', 'Whisper Prepend (before)' },
            p = { '<cmd>GpWhisperPopup<cr>', 'Whisper Popup' },
            e = { '<cmd>GpWhisperEnew<cr>', 'Whisper Enew' },
            n = { '<cmd>GpWhisperNew<cr>', 'Whisper New' },
            v = { '<cmd>GpWhisperVnew<cr>', 'Whisper Vnew' },
            t = { '<cmd>GpWhisperTabnew<cr>', 'Whisper Tabnew' },
          },
        },
        -- ...
      }, {
        mode = 'i', -- INSERT mode
        prefix = '',
        buffer = nil,
        silent = true,
        noremap = true,
        nowait = true,
      })
    end,
  },
}
