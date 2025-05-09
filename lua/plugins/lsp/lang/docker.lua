if not require('mason-registry').is_installed('hadolint') then
  vim.cmd('masoninstall hadolint')
end

return {

  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'dockerfile' })
      end
    end,
  },

}
