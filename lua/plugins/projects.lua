return {
  -- [[ PROJECT MANAGEMENT ]] ---------------------------------------------------------------
  -- [project.nvim] - Active projects selection with Telescope
  -- see: `:h project.nvim`
  --
  -- Normal mode Insert mode Action
  -- f           <c-f>       find_project_files
  -- b           <c-b>       browse_project_files
  -- d           <c-d>       delete_project
  -- s           <c-s>       search_in_project_files
  -- r           <c-r>       recent_project_files
  -- w           <c-w>       change_working_directory
  {
    'ahmedkhalf/project.nvim',
    event = 'VeryLazy',
    keys = {
      { '<leader>fP', '<Cmd>Telescope projects<CR>', desc = 'Projects [fP]' },
    },
    config = function()
      require('project_nvim').setup {
        manual_mode = false,
      }
      require('util').on_load('telescope.nvim', function()
        ---@diagnostic disable-next-line: undefined-field
        require('telescope').load_extension 'projects'
      end)
    end,
  },
}
