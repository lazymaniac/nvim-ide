return {

  -- [kube-utils-nvim] - Provides intehration with kubernetes and helm
  -- see: `:h kube-utils-nvim`
  -- link: https://github.com/h4ckm1n-dev/kube-utils-nvim
  {
    'h4ckm1n-dev/kube-utils-nvim',
    branch = 'main',
    event = 'VeryLazy',
    config = function()
      local helm_mappings = {
        { '<leader>lk', group = '[kubernetes]' },
        { '<leader>lkD', '<cmd>DeleteNamespace<CR>', desc = 'Kubectl Delete Namespace' },
        { '<leader>lkK', '<cmd>OpenK9sSplit<CR>', desc = 'Split View K9s' },
        { '<leader>lkT', '<cmd>HelmDryRun<CR>', desc = 'Helm DryRun Buffer' },
        { '<leader>lka', '<cmd>KubectlApplyFromBuffer<CR>', desc = 'Kubectl Apply From Buffer' },
        { '<leader>lkb', '<cmd>HelmDependencyBuildFromBuffer<CR>', desc = 'Helm Dependency Build' },
        { '<leader>lkd', '<cmd>HelmDeployFromBuffer<CR>', desc = 'Helm Deploy Buffer to Context' },
        { '<leader>lkk', '<cmd>OpenK9s<CR>', desc = 'Open K9s' },
        { '<leader>lkl', '<cmd>ToggleYamlHelm<CR>', desc = 'Toggle YAML/Helm' },
        { '<leader>lkr', '<cmd>RemoveDeployment<CR>', desc = 'Helm Remove Deployment From Buffer' },
        { '<leader>lkt', '<cmd>HelmTemplateFromBuffer<CR>', desc = 'Helm Template From Buffer' },
        { '<leader>lku', '<cmd>HelmDependencyUpdateFromBuffer<CR>', desc = 'Helm Dependency Update' },
      }
      local wk = require 'which-key'
      wk.add(helm_mappings)
    end,
  },

  -- [kubectl.nvim] - Manage kubernetes clusert from neovim
  -- see: `:h kubectl.nvim`
  -- link: link-to-repo
  {
    'ramilito/kubectl.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      {
        '<leader>lc',
        function()
          require('kubectl').open()
        end,
        desc = 'Kubectl [lc]',
      },
    },
    config = function()
      require('kubectl').setup()
    end,
  },
}
