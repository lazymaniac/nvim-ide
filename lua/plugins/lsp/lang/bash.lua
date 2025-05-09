if not require('mason-registry').is_installed('shellcheck') then
  vim.cmd('MasonInstall shellcheck shellharden beautysh bash-debug-adapter')
end

return {

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'bash' })
      end
    end,
  },

}
