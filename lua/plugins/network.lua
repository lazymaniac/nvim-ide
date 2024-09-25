return {

  -- [kulala.nvim] - REST Client interface
  -- see: `:h kulala.nvim`
  -- link: https://github.com/mistweaverco/kulala.nvim
  {
    'mistweaverco/kulala.nvim',
    event = 'VeryLazy',
    -- stylua: ignore
    keys = {
      { '<leader>lrr', '<cmd>lua require("kulala").run()<cr>', mode = { 'n' }, desc = 'Execute the request', },
      { '<leader>lri', '<cmd>lua require("kulala").inspect()<cr>', mode = { 'n' }, desc = 'Inspect current request', },
      { '<leader>lrt', '<cmd>lua require("kulala").toggle_view()<cr>', mode = { 'n' }, desc = 'Toggle between body and headers', },
      { '<leader>lrc', '<cmd>lua require("kulala").copy()<cr>', mode = { 'n' }, desc = 'Copy current request as cURL command', },
      { '<leader>lrp', '<cmd>lua require("kulala").from_curl()<cr>', mode = { 'n' }, desc = 'Paste cURL command as request', },
      { '<leader>lra', '<cmd>lua require("kulala").run_all()<cr>', mode = { 'n' }, desc = 'Run all requests in the buffer', },
      { '<leader>lre', '<cmd>lua require("kulala").replay()<cr>', mode = { 'n' }, desc = 'Replay last request', },
      { '<leader>lrE', '<cmd>lua require("kulala").set_selected_env()<cr>', mode = { 'n' }, desc = 'Select environment', },
      { '<leader>lrS', '<cmd>lua require("kulala").show_stats()<cr>', mode = { 'n' }, desc = 'Show statistics of last request', },
      { '<leader>lrs', '<cmd>lua require("kulala").scratchpad()<cr>', mode = { 'n' }, desc = 'Open scratchpad buffer', },
      { '<leader>lrq', '<cmd>lua require("kulala").close()<cr>', mode = { 'n' }, desc = 'Close view', },
      { '<leader>lrf', '<cmd>lua require("kulala").search()<cr>', mode = { 'n' }, desc = 'Look for http or rest files', },
      { '<leader>lrg', '<cmd>lua require("kulala").download_graphql_schema()<cr>', mode = { 'n' }, desc = 'Download GraphQL schema', },
      { '<leader>lrC', ':vsplit ~/.config/nvim/help/kulala-cheat-sheet.md<cr>:setlocal nomodifiable<CR>', mode = { 'n' }, desc = 'Cheat sheet', },
    },
    opts = {
      curl_path = 'curl',
      split_direction = 'vertical',
      -- default_view, body or headers or headers_body
      default_view = 'headers_body',
      -- dev, test, prod, can be anything
      -- see: https://learn.microsoft.com/en-us/aspnet/core/test/http-files?view=aspnetcore-8.0#environment-files
      default_env = 'dev',
      -- enable/disable debug mode
      debug = false,
      -- default formatters/pathresolver for different content types
      contenttypes = {
        ['application/json'] = {
          ft = 'json',
          formatter = { 'jq', '.' },
        },
        ['application/xml'] = {
          ft = 'xml',
          formatter = { 'xmllint', '--format', '-' },
          pathresolver = { 'xmllint', '--xpath', '{{path}}', '-' },
        },
        ['text/html'] = {
          ft = 'html',
          formatter = { 'xmllint', '--format', '--html', '-' },
          pathresolver = {},
        },
      },
      -- can be used to show loading, done and error icons in inlay hints
      -- possible values: "on_request", "above_request", "below_request", or nil to disable
      -- If "above_request" or "below_request" is used, the icons will be shown above or below the request line
      -- Make sure to have a line above or below the request line to show the icons
      show_icons = 'on_request',
      -- default icons
      icons = {
        inlay = {
          loading = '⏳',
          done = '✅',
          error = '❌',
        },
        lualine = '🐼',
      },
      -- additional cURL options
      -- see: https://curl.se/docs/manpage.html
      additional_curl_options = {},
      -- scratchpad default contents
      scratchpad_default_contents = {
        '@MY_TOKEN_NAME=my_token_value',
        '',
        '# @name scratchpad',
        'POST https://httpbin.org/post HTTP/1.1',
        'accept: application/json',
        'content-type: application/json',
        '',
        '{',
        '  "foo": "bar"',
        '}',
      },
      -- enable winbar
      winbar = true,
      -- Specify the panes to be displayed by default
      -- Current available pane contains { "body", "headers", "headers_body", "script_output" },
      default_winbar_panes = { 'body', 'headers', 'headers_body' },
      -- enable reading vscode rest client environment variables
      vscode_rest_client_environmentvars = false,
      -- disable the vim.print output of the scripts
      -- they will be still written to disk, but not printed immediately
      disable_script_print_output = false,
      -- set scope for environment and request variables
      -- possible values: b = buffer, g = global
      environment_scope = 'b',
    },
    config = function()
      local wk = require 'which-key'
      local defaults = {
        { '<leader>lr', group = '+[rest]' },
      }
      wk.add(defaults)
      vim.filetype.add {
        extension = {
          ['http'] = 'http',
        },
      }
    end,
  },
}
