if not require('mason-registry').is_installed('ansible-lint') then
  vim.cmd('MasonInstall ansible-lint')
end

return {
  {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      if type(opts.ensure_installed) == 'table' then
        vim.list_extend(opts.ensure_installed, { 'yaml' })
      end
    end,
  },

  {
    'mfussenegger/nvim-ansible',
    ft = { 'ansible' },
    branch = 'main',
    keys = {
      {
        "<leader>ta",
        function()
          require("ansible").run()
        end,
        desc = "Ansible Run Playbook/Role",
        silent = true,
      },
    },
  },
}
