if not require('mason-registry').is_installed('cmakelint') then
  vim.cmd('MasonInstall cmakelint')
end

if not require('mason-registry').is_installed('cmakelang') then
  vim.cmd('MasonInstall cmakelang')
end

return {

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "cmake" })
      end
    end,
  },

  -- [cmake-tools.nvim] - Tools for cmake projects.
  -- see: `:h cmake-tools.nvim`
  -- link: https://github.com/Civitasv/cmake-tools.nvim
  {
    "Civitasv/cmake-tools.nvim",
    branch = 'master',
    lazy = true,
    init = function()
      local loaded = false
      local function check()
        local cwd = vim.uv.cwd()
        if vim.fn.filereadable(cwd .. "/CMakeLists.txt") == 1 then
          require("lazy").load({ plugins = { "cmake-tools.nvim" } })
          loaded = true
        end
      end
      check()
      vim.api.nvim_create_autocmd("DirChanged", {
        callback = function()
          if not loaded then
            check()
          end
        end,
      })
    end,
    opts = {},
  },
}
