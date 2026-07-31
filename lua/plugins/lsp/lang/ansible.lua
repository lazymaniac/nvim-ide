return {
  {
    'mfussenegger/nvim-ansible',
    ft = { 'ansible' },
    branch = 'main',
    keys = {
      {
        "<leader>ra",
        function()
          require("ansible").run()
        end,
        desc = "Ansible Run Playbook/Role",
        silent = true,
      },
    },
  },
}
