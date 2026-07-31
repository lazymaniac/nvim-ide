return {
  {
    'suketa/nvim-dap-ruby',
    dependencies = { 'mfussenegger/nvim-dap' },
    ft = { 'ruby' },
    config = function()
      require('dap-ruby').setup()
    end,
  },
}
