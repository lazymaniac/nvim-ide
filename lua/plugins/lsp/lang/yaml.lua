return {

  -- [SchemaStore.nvim] - Schema stores for nvim.
  -- see: `:h SchemaStore.nvim`
  -- link: link-to-repo
  {
    'b0o/SchemaStore.nvim',
    ft = { 'json', 'yaml', 'jsonc' },
  },

  {
    'neovim/nvim-lspconfig',
    dependencies = { 'b0o/SchemaStore.nvim' },
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.yamlls = vim.tbl_deep_extend('force', opts.servers.yamlls or {}, {
        capabilities = {
          textDocument = {
            foldingRange = {
              dynamicRegistration = false,
              lineFoldingOnly = true,
            },
          },
        },
        settings = {
          redhat = { telemetry = { enabled = false } },
          yaml = {
            keyOrdering = false,
            format = { enable = true },
            validate = true,
            schemaStore = {
              enable = false,
              url = '',
            },
            schemas = require('schemastore').yaml.schemas(),
          },
        },
      })
    end,
  },
}
