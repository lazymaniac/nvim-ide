return {

  -- [[ CODE COMMENTS ]] ---------------------------------------------------------------

  -- [ts-comments] - Imrovide comments
  -- see: `:h ts-comments`
  -- link: https://github.com/folke/ts-comments.nvim
  {
    "folke/ts-comments.nvim",
    event = "BufReadPost",
    opts = {},
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
