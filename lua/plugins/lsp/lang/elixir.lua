if not require('mason-registry').is_installed 'hadolint' then
  vim.cmd 'masoninstall hadolint'
end

return {

  -- [elixir-tools] - Improves experience with Elixir in neovim.
  -- see: `:h elixir-tools`
  -- link: https://github.com/elixir-tools/elixir-tools.nvim
  {
    'elixir-tools/elixir-tools.nvim',
    branch = 'main',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local elixir = require 'elixir'
      local elixirls = require 'elixir.elixirls'
      elixir.setup {
        nextls = { enable = true },
        credo = {},
        elixirls = {
          enable = true,
          settings = elixirls.settings {
            dialyzerEnabled = false,
            enableTestLenses = false,
          },
          on_attach = function(_, bufnr)
            local wk = require 'which-key'
            wk.add {
              { '<leader>cm', ':ElixirFromPipe<cr>', desc = 'From Pipe [cm]', mode = 'n', buffer = bufnr },
              { '<leader>cO', ':ElixirToPipe<cr>', desc = 'To Pipe [co]', mode = 'n', buffer = bufnr },
              { '<leader>ce', ':ElixirExpandMacro<cr>', desc = 'Expand Macro [ce]', mode = 'n', buffer = bufnr },
            }
          end,
        },
      }
    end,
  },
}
