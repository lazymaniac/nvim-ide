-- automatically import output chunks from a jupyter notebook
-- tries to find a kernel that matches the kernel in the jupyter notebook
-- falls back to a kernel that matches the name of the active venv (if any)
local imb = function(e) -- init molten buffer
  vim.schedule(function()
    local kernels = vim.fn.MoltenAvailableKernels()
    local try_kernel_name = function()
      local metadata = vim.json.decode(io.open(e.file, 'r'):read 'a')['metadata']
      return metadata.kernelspec.name
    end
    local ok, kernel_name = pcall(try_kernel_name)
    if not ok or not vim.tbl_contains(kernels, kernel_name) then
      kernel_name = nil
      local venv = os.getenv 'VIRTUAL_ENV'
      if venv ~= nil then
        kernel_name = string.match(venv, '/.+/(.+)')
      end
    end
    if kernel_name ~= nil and vim.tbl_contains(kernels, kernel_name) then
      vim.cmd(('MoltenInit %s'):format(kernel_name))
    end
    vim.cmd 'MoltenImportOutput'
  end)
end

-- automatically import output chunks from a jupyter notebook
vim.api.nvim_create_autocmd('BufAdd', {
  pattern = { '*.ipynb' },
  callback = imb,
})

-- we have to do this as well so that we catch files opened like nvim ./hi.ipynb
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = { '*.ipynb' },
  callback = function(e)
    if vim.api.nvim_get_vvar 'vim_did_enter' ~= 1 then
      imb(e)
    end
  end,
})

-- automatically export output chunks to a jupyter notebook on write
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = { '*.ipynb' },
  callback = function()
    if require('molten.status').initialized() == 'Molten' then
      vim.cmd 'MoltenExportOutput!'
    end
  end,
})

return {

  -- [[ CODE RUNNERS ]] ---------------------------------------------------------------

  -- Add which-key group for code runners
  {
    'folke/which-key.nvim',
    opts = {
      defaults = {
        ['<leader>r'] = { name = '+[run]' },
        ['<leader>j'] = { name = '+[jupyter]' },
      },
    },
  },

  -- [sniprun] - Run lines or part of code without running whole program
  -- see: `:h sniprun`
  {
    'michaelb/sniprun',
    event = 'VeryLazy',
    -- do 'sh install.sh 1' if you want to force compile locally
    -- (instead of fetching a binary from the github release). Requires Rust >= 1.65
    build = 'sh install.sh',
    -- stylua: ignore
    keys = {
      { '<leader>rl', '<cmd>SnipRun<cr>', mode = { 'n' }, desc = 'Run line of code [rl]' },
      { '<leader>rs', '<cmd>SnipRun<cr>', mode = { 'v' }, desc = 'Run selected code [rs]' },
      { '<leader>rf', '<cmd>%SnipRun<cr>', mode = { 'n', 'v' }, desc = 'Run current file [rf]' },
    },
    config = function()
      require('sniprun').setup {
        selected_interpreters = {}, --# use those instead of the default for the current filetype
        repl_enable = {}, --# enable REPL-like behavior for the given interpreters
        repl_disable = {}, --# disable REPL-like behavior for the given interpreters
        interpreter_options = { --# interpreter-specific options, see doc / :SnipInfo <name>
          --# use the interpreter name as key
          GFM_original = {
            use_on_filetypes = { 'markdown.pandoc' }, --# the 'use_on_filetypes' configuration key is
            --# available for every interpreter
          },
          Python3_original = {
            error_truncate = 'auto', --# Truncate runtime errors 'long', 'short' or 'auto'
            --# the hint is available for every interpreter
            --# but may not be always respected
          },
        },
        --# you can combo different display modes as desired and with the 'Ok' or 'Err' suffix
        --# to filter only successful runs (or errored-out runs respectively)
        display = {
          -- 'Classic', --# display results in the command-line  area
          -- 'VirtualTextOk', --# display ok results as virtual text (multiline is shortened)
          'VirtualText', --# display results as virtual text
          -- "TempFloatingWindow",      --# display results in a floating window
          -- "LongTempFloatingWindow",  --# same as above, but only long results. To use with VirtualText[Ok/Err]
          -- "Terminal",                --# display results in a vertical split
          -- "TerminalWithCode",        --# display results and code history in a vertical split
          'NvimNotify', --# display with the nvim-notify plugin
          -- "Api"                      --# return output to a programming interface
        },
        live_display = { 'VirtualTextOk' }, --# display mode used in live_mode
        display_options = {
          terminal_scrollback = vim.o.scrollback, --# change terminal display scrollback lines
          terminal_line_number = false, --# whether show line number in terminal window
          terminal_signcolumn = false, --# whether show signcolumn in terminal window
          terminal_persistence = true, --# always keep the terminal open (true) or close it at every occasion (false)
          terminal_position = 'vertical', --# or "horizontal", to open as horizontal split instead of vertical split
          terminal_width = 45, --# change the terminal display option width (if vertical)
          terminal_height = 20, --# change the terminal display option height (if horizontal)
          notification_timeout = 5, --# timeout for nvim_notify output
        },
        --# You can use the same keys to customize whether a sniprun producing
        --# no output should display nothing or '(no output)'
        show_no_output = {
          'Classic',
          'TempFloatingWindow', --# implies LongTempFloatingWindow, which has no effect on its own
        },
        --# customize highlight groups (setting this overrides colorscheme)
        live_mode_toggle = 'off', --# live mode toggle, see Usage - Running for more info
        --# miscellaneous compatibility/adjustement settings
        inline_messages = false, --# boolean toggle for a one-line way to display messages
        --# to workaround sniprun not being able to display anything
        borders = 'single', --# display borders around floating windows
        --# possible values are 'none', 'single', 'double', or 'shadow'
      }
    end,
  },

  -- [jupytext.nvim] - Automatically convert Jopyter notebooks to python files.
  -- see: `:h jupytext.nvim`
  {
    'GCBallesteros/jupytext.nvim',
    event = 'VeryLazy',
    config = function()
      require('jupytext').setup {
        style = 'markdown',
        output_extension = 'md',
        force_ft = 'markdown',
      }
    end,
  },

  -- Use mini.hipatterns for Jupyter cells
  {
    'echasnovski/mini.hipatterns',
    event = 'VeryLazy',
    dependencies = { 'GCBallesteros/NotebookNavigator.nvim' },
    opts = function()
      local nn = require 'notebook-navigator'
      local opts = { highlighters = { cells = nn.minihipatterns_spec } }
      return opts
    end,
  },

  -- [molten-nvim] - REPL for jupyter notebook
  -- see: `:h molten-nvim`
  {
    'benlubas/molten-nvim',
    event = 'VeryLazy',
    dependencies = { '3rd/image.nvim' },
    build = ':UpdateRemotePlugins',
    -- stylua: ignore
    keys = {
      { '<leader>je', '<cmd>MoltenEvaluateOperator<cr>', mode = { 'n' }, desc = 'Evaluate Operator [je]' },
      { '<leader>jo', '<cmd>noautocmd MoltenEnterOutput<cr>', mode = { 'n' }, desc = 'Open Output Window [jo]' },
      { '<leader>jr', '<cmd>MoltenReevaluateCell<cr>', mode = { 'n' }, desc = 'Reevaluta Cell [jr]' },
      { '<leader>jr', '<cmd><C-u>MoltenEvaluateVisual<cr>', mode = { 'v' }, desc = 'Edxecute Selected Code [jr]' },
      { '<leader>jh', '<cmd>MoltenHideOutput<cr>', mode = { 'n' }, desc = 'Hide Output [jh]' },
      { '<leader>jd', '<cmd>MoltenDelete<cr>', mode = { 'n' }, desc = 'Delete Cell [jd]' },
      { '<leader>jb', '<cmd>MoltenOpenInBrowser<cr>', mode = { 'n' }, desc = 'Open in Browser [jb]' },
    },
    init = function()
      vim.g.molten_image_provider = 'image.nvim'
      vim.g.molten_use_border_highlights = true
      -- I find auto open annoying, keep in mind setting this option will require setting
      -- a keybind for `:noautocmd MoltenEnterOutput` to open the output again
      vim.g.molten_auto_open_output = false
      -- optional, I like wrapping. works for virt text and the output window
      vim.g.molten_wrap_output = true
      -- Output as virtual text. Allows outputs to always be shown, works with images, but can
      -- be buggy with longer images
      vim.g.molten_virt_text_output = true
      -- this will make it so the output shows up below the \`\`\` cell delimiter
      vim.g.molten_virt_lines_off_by_1 = true
      -- add a few new things
    end,
  },

  {
    'quarto-dev/quarto-nvim',
    ft = { 'quarto', 'markdown' },
    -- stylua: ignore
    keys = {
      { '<leader>jc', '<cmd>lua require("quarto.runner").run_cell()<cr>', mode = { 'n' }, desc = 'Run Cell [jc]' },
      { '<leader>ja', '<cmd>lua require("quarto.runner").run_above()<cr>', mode = { 'n' }, desc = 'Run Cell and Above [ja]' },
      { '<leader>jA', '<cmd>lua require("quarto.runner").run_all()<cr>', mode = { 'n' }, desc = 'Run All Cells [jA]' },
      { '<leader>jl', '<cmd>lua require("quarto.runner").run_line()<cr>', mode = { 'n' }, desc = 'Run Line [jl]' },
      { '<leader>jR', '<cmd>lua require("quarto.runner").run_range()<cr>', mode = { 'v' }, desc = 'Run Selected Cells [jR]' },
      { '<leader>jx', '<cmd>lua require("quarto.runner").run_all(true)<cr>', mode = { 'n' }, desc = 'Run All Cells of All Languages [jx]' },
    },
    dependencies = { 'jmbuhr/otter.nvim' },
    config = function()
      require('quatro').config {
        lspFeatures = {
          languages = { 'r', 'python', 'rust', 'java', 'kotlin', 'scala', 'go' },
          chunks = 'all',
          diagnostics = {
            enabled = true,
            triggers = { 'BufWritePost' },
          },
          completion = {
            enabled = true,
          },
        },
        keymap = {
          hover = 'K',
          definition = 'gd',
          rename = '<leader>cr',
          references = 'gr',
          format = '<leader>cf',
        },
        codeRunner = {
          enabled = true,
          default_method = 'molten',
        },
      }
    end,
  },

  {
    'jmbuhr/otter.nvim',
    dependencies = { 'neovim/nvim-lspconfig' },
    opts = {
      buffers = {
        -- if set to true, the filetype of the otterbuffers will be set.
        -- otherwise only the autocommand of lspconfig that attaches
        -- the language server will be executed without setting the filetype
        set_filetype = true,
      },
    },
  },
}
