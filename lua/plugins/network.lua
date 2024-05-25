return {

  -- [[ EDIT REMOTE AND IN DOCKER ]] ---------------------------------------------------------------
  -- [netman.nvim] - Edit files via SSH or in docker
  -- see: `:h netman`
  -- link: https://github.com/miversen33/netman.nvim
  {
    'miversen33/netman.nvim',
    branch = 'main',
    event = 'VeryLazy',
    -- Note, you do not need this if you plan on using Netman with any of the
    -- supported UI Tools such as Neo-tree
    -- config = true,
  },

  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      defaults = {
        ['<leader>lr'] = { name = '+[rest]' },
      },
    },
  },

  -- [rest.nvim] - Call rest calls defined in files
  -- see: `:h rest.nvim`
  -- link: https://github.com/rest-nvim/rest.nvim
  {
    'rest-nvim/rest.nvim',
    branch = 'main',
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      { '<leader>lrr', '<cmd>lua require("rest-nvim").run()<cr>',     mode = { 'n', 'v' }, desc = 'Call REST [lrr]' },
      { '<leader>lrp', '<cmd>lua require("rest-nvim").run(true)<cr>', mode = { 'n', 'v' }, desc = 'Call REST Preview [lrp]' },
      { '<leader>lrl', '<cmd>lua require("rest-nvim").last()<cr>',    mode = { 'n', 'v' }, desc = 'Call REST Last [lrl]' },
    },
    config = function()
      require('rest-nvim').setup {
        client = 'curl',
        env_file = '.env',
        env_pattern = '\\.env$',
        env_edit_command = 'tabedit',
        encode_url = true,
        skip_ssl_verification = false,
        custom_dynamic_variables = {},
        logs = {
          level = 'info',
          save = true,
        },
        result = {
          split = {
            horizontal = false,
            in_place = false,
            stay_in_current_window_after_split = true,
          },
          behavior = {
            decode_url = true,
            show_info = {
              url = true,
              headers = true,
              http_info = true,
              curl_command = true,
            },
            statistics = {
              enable = true,
              ---@see https://curl.se/libcurl/c/curl_easy_getinfo.html
              stats = {
                { 'total_time',      title = 'Time taken:' },
                { 'size_download_t', title = 'Download size:' },
              },
            },
            formatters = {
              json = 'jq',
              html = function(body)
                if vim.fn.executable 'tidy' == 0 then
                  return body, { found = false, name = 'tidy' }
                end
                local fmt_body = vim.fn
                    .system({
                      'tidy',
                      '-i',
                      '-q',
                      '--tidy-mark',
                      'no',
                      '--show-body-only',
                      'auto',
                      '--show-errors',
                      '0',
                      '--show-warnings',
                      '0',
                      '-',
                    }, body)
                    :gsub('\n$', '')

                return fmt_body, { found = true, name = 'tidy' }
              end,
            },
          },
          keybinds = {
            buffer_local = true,
            prev = 'H',
            next = 'L',
          },
        },
        highlight = {
          enable = true,
          timeout = 750,
        },
      }
    end,
  },
}
