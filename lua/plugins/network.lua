return {

  -- [[ EDIT REMOTE AND IN DOCKER ]] ---------------------------------------------------------------
  -- [netman.nvim] - Edit files via SSH or in docker
  -- see: `:h netman`
  {
    'miversen33/netman.nvim',
    event = 'VeryLazy',
    branch = 'v1.15',
    -- Note, you do not need this if you plan on using Netman with any of the
    -- supported UI Tools such as Neo-tree
    -- config = true,
  },

  -- [rest.nvim] - Call rest calls defined in files
  -- see: `:h rest.nvim`
  {
    'rest-nvim/rest.nvim',
    dependencies = { { 'nvim-lua/plenary.nvim' } },
    keys = {
      { '<leader>Ur', '<cmd>lua require("rest-nvim").run()<cr>', mode = { 'n', 'v' }, desc = 'Call REST [Ur]' },
      { '<leader>Up', '<cmd>lua require("rest-nvim").run(true)<cr>', mode = { 'n', 'v' }, desc = 'Call REST Preview [Up]' },
      { '<leader>Ul', '<cmd>lua require("rest-nvim").last()<cr>', mode = { 'n', 'v' }, desc = 'Call REST Last [Ul]' },
    },
    config = function()
      require('rest-nvim').setup {
        -- Open request results in a horizontal split
        result_split_horizontal = false,
        -- Keep the http file buffer above|left when split horizontal|vertical
        result_split_in_place = false,
        -- stay in current windows (.http file) or change to results window (default)
        stay_in_current_window_after_split = false,
        -- Skip SSL verification, useful for unknown certificates
        skip_ssl_verification = false,
        -- Encode URL before making request
        encode_url = true,
        -- Highlight request on run
        highlight = {
          enabled = true,
          timeout = 150,
        },
        result = {
          -- toggle showing URL, HTTP info, headers at top the of result window
          show_url = true,
          -- show the generated curl command in case you want to launch
          -- the same request via the terminal (can be verbose)
          show_curl_command = false,
          show_http_info = true,
          show_headers = true,
          -- table of curl `--write-out` variables or false if disabled
          -- for more granular control see Statistics Spec
          show_statistics = false,
          -- executables or functions for formatting response body [optional]
          -- set them to false if you want to disable them
          formatters = {
            json = 'jq',
            html = function(body)
              return vim.fn.system({ 'tidy', '-i', '-q', '-' }, body)
            end,
          },
        },
        -- Jump to request line on run
        jump_to_request = false,
        env_file = '.env',
        custom_dynamic_variables = {},
        yank_dry_run = true,
        search_back = true,
      }
    end,
  },
}
