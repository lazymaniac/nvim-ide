return {
  -- Add s-exp mappings
  { "PaterJason/nvim-treesitter-sexp", opts = {}, },

  -- Colorize the output of the log buffer
  {
    "m00qek/baleia.nvim",
    ft = { "clojure", "fennel" },
    opts = {
      line_starts_at = 3,
    },
    config = function(_, opts)
      vim.g.conjure_baleia = require("baleia").setup(opts)

      vim.api.nvim_create_user_command("BaleiaColorize", function()
        vim.g.conjure_baleia.once(vim.api.nvim_get_current_buf())
      end, { bang = true })

      vim.api.nvim_create_user_command("BaleiaLogs", vim.g.conjure_baleia.logger.show, { bang = true })
    end,
  },

  -- Use Clojure REPL
  {
    "Olical/conjure",
    ft = { "clojure", "fennel" },
    config = function(_, _)
      require("conjure.main").main()
      require("conjure.mapping")["on-filetype"]()
    end,
    init = function()
      -- print color codes if baleia.nvim is available
      local colorize = require("util").has("baleia.nvim")

      if colorize then
        vim.g["conjure#log#strip_ansi_escape_sequences_line_limit"] = 0
      else
        vim.g["conjure#log#strip_ansi_escape_sequences_line_limit"] = 1
      end

      -- disable diagnostics in log buffer and colorize it
      vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
        pattern = "conjure-log-*",
        callback = function()
          local buffer = vim.api.nvim_get_current_buf()
          vim.diagnostic.enable(false, { bufnr = buffer })

          if colorize and vim.g.conjure_baleia then
            vim.g.conjure_baleia.automatically(buffer)
          end

          vim.keymap.set(
            { "n", "v" },
            "[c",
            "<CMD>call search('^; -\\+$', 'bw')<CR>",
            { silent = true, buffer = true, desc = "Jumps to the beginning of previous evaluation output." }
          )
          vim.keymap.set(
            { "n", "v" },
            "]c",
            "<CMD>call search('^; -\\+$', 'w')<CR>",
            { silent = true, buffer = true, desc = "Jumps to the beginning of next evaluation output." }
          )
        end,
      })

      -- prefer LSP for jump-to-definition and symbol-doc, and use conjure
      -- alternatives with <localleader>K and <localleader>gd
      vim.g["conjure#mapping#doc_word"] = "K"
      vim.g["conjure#mapping#def_word"] = "gd"
    end,
  },
}
