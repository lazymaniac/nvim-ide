return {
  {
    'telescope.nvim',
    dependencies = {
      -- project management
      {
        'ahmedkhalf/project.nvim',
        opts = {
          manual_mode = false,
        },
        event = 'VeryLazy',
        config = function(_, opts)
          require('project_nvim').setup(opts)
          require('util').on_load('telescope.nvim', function()
            require('telescope').load_extension 'projects'
          end)
        end,
        keys = {
          { '<leader>fP', '<Cmd>Telescope projects<CR>', desc = 'Projects' },
        },
      },
    },
  },
}
