return {

  -- [kube-utils-nvim] - Provides intehration with kubernetes and help
  -- see: `:h kube-utils-nvim`
  -- link: https://github.com/h4ckm1n-dev/kube-utils-nvim
  {
    'h4ckm1n-dev/kube-utils-nvim',
    branch = 'main',
    event = 'VeryLazy',
    config = function()
      local helm_mappings = {
        l = {
          k = {
            name = '+[kubernetes]',
            d = { '<cmd>HelmDeployFromBuffer<CR>', 'Helm Deploy Buffer to Context' },
            r = { '<cmd>RemoveDeployment<CR>', 'Helm Remove Deployment From Buffer' },
            T = { '<cmd>HelmDryRun<CR>', 'Helm DryRun Buffer' },
            a = { '<cmd>KubectlApplyFromBuffer<CR>', 'Kubectl Apply From Buffer' },
            D = { '<cmd>DeleteNamespace<CR>', 'Kubectl Delete Namespace' },
            u = { '<cmd>HelmDependencyUpdateFromBuffer<CR>', 'Helm Dependency Update' },
            b = { '<cmd>HelmDependencyBuildFromBuffer<CR>', 'Helm Dependency Build' },
            t = { '<cmd>HelmTemplateFromBuffer<CR>', 'Helm Template From Buffer' },
            K = { '<cmd>OpenK9sSplit<CR>', 'Split View K9s' },
            k = { '<cmd>OpenK9s<CR>', 'Open K9s' },
            l = { '<cmd>ToggleYamlHelm<CR>', 'Toggle YAML/Helm' },
          },
        },
      }
      local wk = require 'which-key'
      wk.register(helm_mappings, { prefix = '<leader>' })
    end,
  },
}
