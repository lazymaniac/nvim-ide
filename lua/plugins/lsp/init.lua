---@diagnostic disable: undefined-field
local Util = require 'util'

return {
  -- lspconfig
  {
    'neovim/nvim-lspconfig',
    event = 'VeryLazy',
    dependencies = {
      {
        'folke/neodev.nvim',
        event = 'VeryLazy',
        opts = {
          library = {
            enabled = true, -- when not enabled, neodev will not change any settings to the LSP server
            -- these settings will be used for your Neovim config directory
            runtime = true, -- runtime path
            types = true, -- full signature, docs and completion of vim.api, vim.treesitter, vim.lsp and others
            plugins = true, -- installed opt or start plugins in packpath
            -- you can also specify the list of plugins to make available as a workspace library
            -- plugins = { "nvim-treesitter", "plenary.nvim", "telescope.nvim" },
          },
          setup_jsonls = true, -- configures jsonls to provide completion for project specific .luarc.json files
          -- With lspconfig, Neodev will automatically setup your lua-language-server
          -- If you disable this, then you have to set {before_init=require("neodev.lsp").before_init}
          -- in your lsp start options
          lspconfig = true,
          -- much faster, but needs a recent built of lua-language-server
          -- needs lua-language-server >= 3.6.0
          pathStrict = true,
        },
      },
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      {
        'j-hui/fidget.nvim',
        event = 'VeryLazy',
        opts = {
          -- Options related to LSP progress subsystem
          progress = {
            poll_rate = 0, -- How and when to poll for progress messages
            suppress_on_insert = true, -- Suppress new messages while in insert mode
            ignore_done_already = true, -- Ignore new tasks that are already complete
            ignore_empty_message = true, -- Ignore new tasks that don't contain a message
            -- Clear notification group when LSP server detaches
            clear_on_detach = function(client_id)
              local client = vim.lsp.get_client_by_id(client_id)
              return client and client.name or nil
            end,
            -- How to get a progress message's notification group key
            notification_group = function(msg)
              return msg.lsp_client.name
            end,
            ignore = {}, -- List of LSP servers to ignore
            -- Options related to how LSP progress messages are displayed as notifications
            display = {
              render_limit = 5, -- How many LSP messages to show at once
              done_ttl = 1, -- How long a message should persist after completion
              done_icon = '✔', -- Icon shown when all LSP progress tasks are complete
              done_style = 'Constant', -- Highlight group for completed LSP tasks
              progress_ttl = math.huge, -- How long a message should persist when in progress
              -- Icon shown when LSP progress tasks are in progress
              progress_icon = { pattern = 'dots', period = 1 },
              -- Highlight group for in-progress LSP tasks
              progress_style = 'WarningMsg',
              group_style = 'Title', -- Highlight group for group name (LSP server name)
              icon_style = 'Question', -- Highlight group for group icons
              priority = 30, -- Ordering priority for LSP notification group
              -- How to format a progress annotation
              format_annote = function(msg)
                return msg.title
              end,
              -- How to format a progress notification group's name
              format_group_name = function(group)
                return tostring(group)
              end,
              overrides = { -- Override options from the default notification config
                rust_analyzer = { name = 'rust-analyzer' },
              },
            },
            -- Options related to Neovim's built-in LSP client
            lsp = {
              progress_ringbuf_size = 0, -- Configure the nvim's LSP progress ring buffer size
            },
          },
          -- Options related to notification subsystem
          notification = {
            poll_rate = 10, -- How frequently to update and render notifications
            filter = vim.log.levels.INFO, -- Minimum notifications level
            override_vim_notify = false, -- Automatically override vim.notify() with Fidget
            -- Options related to how notifications are rendered as text
            view = {
              stack_upwards = true, -- Display notification items from bottom to top
              icon_separator = ' ', -- Separator between group name and icon
              group_separator = '---', -- Separator between notification groups
              -- Highlight group used for group separator
              group_separator_hl = 'Comment',
            },
            -- Options related to the notification window and buffer
            window = {
              normal_hl = 'Comment', -- Base highlight group in the notification window
              winblend = 100, -- Background color opacity in the notification window
              border = 'none', -- Border around the notification window
              zindex = 45, -- Stacking priority of the notification window
              max_width = 0, -- Maximum width of the notification window
              max_height = 0, -- Maximum height of the notification window
              x_padding = 1, -- Padding from right edge of window boundary
              y_padding = 0, -- Padding from bottom edge of window boundary
              align = 'bottom', -- How to align the notification window
              relative = 'editor', -- What the notification window position is relative to
            },
          },
          -- Options related to logging
          logger = {
            level = vim.log.levels.WARN, -- Minimum logging level
            float_precision = 0.01, -- Limit the number of decimals displayed for floats
            -- Where Fidget writes its logs to
            path = string.format('%s/fidget.nvim.log', vim.fn.stdpath 'cache'),
          },
        },
      },
    },
    ---@class PluginLspOpts
    opts = {
      -- options for vim.diagnostic.config()
      diagnostics = {
        underline = true,
        update_in_insert = true,
        virtual_text = {
          spacing = 4,
          source = 'if_many',
          prefix = '●',
          -- this will set the prefix to a function that returns the diagnostics icon based on the severity
          -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
          -- prefix = "icons",
        },
        severity_sort = true,
      },
      -- Enable this to enable the builtin LSP inlay hints on Neovim >= 0.10.0
      -- Be aware that you also will need to properly configure your LSP server to
      -- provide the inlay hints.
      inlay_hints = {
        enabled = true,
      },
      -- add any global capabilities here
      capabilities = {},
      -- options for vim.lsp.buf.format
      -- `bufnr` and `filter` is handled by the LazyVim formatter,
      -- but can be also overridden when specified
      format = {
        formatting_options = nil,
        timeout_ms = nil,
      },
      -- LSP Server Settings
      servers = {
        lua_ls = {
          -- mason = false, -- set to false if you don't want this server to be installed with mason
          -- Use this to add any additional keymaps
          -- for specific lsp servers
          -- keys = {},
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
              completion = {
                callSnippet = 'Replace',
              },
            },
          },
        },
      },
      -- you can do any additional lsp server setup here
      -- return true if you don't want this server to be setup with lspconfig
      setup = {
        -- example to setup with typescript.nvim
        -- tsserver = function(_, opts)
        --   require("typescript").setup({ server = opts })
        --   return true
        -- end,
        -- Specify * to use this function as a fallback for any server
        -- ["*"] = function(server, opts) end,
      },
    },
    ---@param opts PluginLspOpts
    config = function(_, opts)
      -- setup autoformat
      Util.format.register(Util.lsp.formatter())
      -- deprectaed options
      ---@diagnostic disable-next-line: undefined-field
      if opts.autoformat ~= nil then
        vim.g.autoformat = opts.autoformat
        Util.deprecate('nvim-lspconfig.opts.autoformat', 'vim.g.autoformat')
      end
      -- setup keymaps
      Util.lsp.on_attach(function(client, buffer)
        require('plugins.lsp.keymaps').on_attach(client, buffer)
      end)
      local register_capability = vim.lsp.handlers['client/registerCapability']
      vim.lsp.handlers['client/registerCapability'] = function(err, res, ctx)
        local ret = register_capability(err, res, ctx)
        local client_id = ctx.client_id
        local client = vim.lsp.get_client_by_id(client_id)
        local buffer = vim.api.nvim_get_current_buf()
        require('plugins.lsp.keymaps').on_attach(client, buffer)
        return ret
      end
      -- diagnostics
      for name, icon in pairs(require('config').icons.diagnostics) do
        name = 'DiagnosticSign' .. name
        vim.fn.sign_define(name, { text = icon, texthl = name, numhl = '' })
      end
      if opts.inlay_hints.enabled then
        Util.lsp.on_attach(function(client, buffer)
          if client.supports_method 'textDocument/inlayHint' then
            Util.toggle.inlay_hints(buffer, true)
          end
        end)
      end
      if type(opts.diagnostics.virtual_text) == 'table' and opts.diagnostics.virtual_text.prefix == 'icons' then
        opts.diagnostics.virtual_text.prefix = vim.fn.has 'nvim-0.10.0' == 0 and '●'
          or function(diagnostic)
            local icons = require('config').icons.diagnostics
            for d, icon in pairs(icons) do
              if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
                return icon
              end
            end
          end
      end
      vim.diagnostic.config(vim.deepcopy(opts.diagnostics))
      local servers = opts.servers
      local has_cmp, cmp_nvim_lsp = pcall(require, 'cmp_nvim_lsp')
      local capabilities = vim.tbl_deep_extend(
        'force',
        {},
        vim.lsp.protocol.make_client_capabilities(),
        has_cmp and cmp_nvim_lsp.default_capabilities() or {},
        opts.capabilities or {}
      )
      local function setup(server)
        local server_opts = vim.tbl_deep_extend('force', {
          capabilities = vim.deepcopy(capabilities),
        }, servers[server] or {})
        if opts.setup[server] then
          if opts.setup[server](server, server_opts) then
            return
          end
        elseif opts.setup['*'] then
          if opts.setup['*'](server, server_opts) then
            return
          end
        end
        require('lspconfig')[server].setup(server_opts)
      end
      -- get all the servers that are available through mason-lspconfig
      local have_mason, mlsp = pcall(require, 'mason-lspconfig')
      local all_mslp_servers = {}
      if have_mason then
        all_mslp_servers = vim.tbl_keys(require('mason-lspconfig.mappings.server').lspconfig_to_package)
      end
      local ensure_installed = {} ---@type string[]
      for server, server_opts in pairs(servers) do
        if server_opts then
          server_opts = server_opts == true and {} or server_opts
          -- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
          if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
            setup(server)
          else
            ensure_installed[#ensure_installed + 1] = server
          end
        end
      end
      if have_mason then
        mlsp.setup { ensure_installed = ensure_installed, handlers = { setup } }
      end
      if Util.lsp.get_config 'denols' and Util.lsp.get_config 'tsserver' then
        local is_deno = require('util').root_pattern('deno.json', 'deno.jsonc')
        Util.lsp.disable('tsserver', is_deno)
        Util.lsp.disable('denols', function(root_dir)
          return not is_deno(root_dir)
        end)
      end
    end,
  },

  -- cmdline tools and lsp servers
  {
    'williamboman/mason.nvim',
    event = 'VeryLazy',
    cmd = 'Mason',
    build = ':MasonUpdate',
    opts = {
      ensure_installed = {
        'lua-language-server',
        'stylua',
      },
      ui = {
        border = 'rounded',
      },
    },
    config = function(_, opts)
      require('mason').setup(opts)
      local mr = require 'mason-registry'
      mr:on('package:install:success', function()
        vim.defer_fn(function()
          -- trigger FileType event to possibly load this newly installed LSP server
          require('lazy.core.handler.event').trigger {
            event = 'FileType',
            buf = vim.api.nvim_get_current_buf(),
          }
        end, 100)
      end)
      local function ensure_installed()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end
      if mr.refresh then
        mr.refresh(ensure_installed)
      else
        ensure_installed()
      end
    end,
  },
}
