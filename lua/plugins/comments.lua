return {

  -- [[ CODE COMMENTS ]] ---------------------------------------------------------------

  -- [nvim-ts-context-commentstring] - Automatically selects type of comment based on cursor location.
  -- see: `:h nvim-ts-context-commentstring`
  -- link: https://github.com/JoosepAlviste/nvim-ts-context-commentstring
  {
    'JoosepAlviste/nvim-ts-context-commentstring',
    branch = 'main',
    event = 'VeryLazy',
    config = function()
      require('ts_context_commentstring').setup {
        enable_autocmd = false,
      }
    end,
  },

  -- [comment.nvim] - Provides option to add comments in code
  -- see: `:h comment-nvim`
  -- link: https://github.com/numToStr/Comment.nvim
  {
    'numToStr/Comment.nvim',
    branch = 'master',
    event = 'VeryLazy',
    config = function()
      require('Comment').setup {
        padding = true, ---Add a space b/w comment and the line
        sticky = true, ---Whether the cursor should stay at its position
        ignore = '^$', -- ignore empty lines. Lines to be ignored while (un)comment
        toggler = { ---LHS of toggle mappings in NORMAL mode
          line = 'gcc', ---Line-comment toggle keymap
          block = 'gbc', ---Block-comment toggle keymap
        },
        opleader = { ---LHS of operator-pending mappings in NORMAL and VISUAL mode
          line = 'gc', ---Line-comment keymap
          block = 'gb', ---Block-comment keymap
        },
        extra = { ---LHS of extra mappings
          above = 'gcO', ---Add comment on the line above
          below = 'gco', ---Add comment on the line below
          eol = 'gcA', ---Add comment at the end of line
        },
        mappings = { ---Enable keybindings
          basic = true, ---Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
          extra = true, ---Extra mapping; `gco`, `gcO`, `gcA`
        },
        ---Function to call before (un)comment
        pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
      }
    end,
  },

  -- [todo-comments.nvim] - Finds and lists all of the TODO, HACK, BUG, etc comment
  -- in your project and loads them into a browsable list.
  -- see: `:h todo-comments`
  -- link: https://github.com/folke/todo-comments.nvim
  {
    'folke/todo-comments.nvim',
    optional = true,
    -- stylua: ignore
    keys = {
      { "<leader>st", function() Snacks.picker.todo_comments() end, desc = "Todo" },
      { "<leader>sT", function () Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end, desc = "Todo/Fix/Fixme" },
    },
  },
}
