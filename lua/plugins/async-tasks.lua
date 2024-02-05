return {
  {

    -- [[ TASK RUNNERS ]] ---------------------------------------------------------------

    -- [overseer.nvim] - Async task runner.
    -- see: `:h overseer.nvim`
    'stevearc/overseer.nvim',
    event = 'VeryLazy',
    dependencies = { 'akinsho/toggleterm.nvim' },
    -- stylua: ignore
    keys = {
      { '<leader>rb', '<cmd>OverseerBuild<cr>', mode = { 'n' }, desc = 'Create Task [rb]' },
      { '<leader>rv', '<cmd>OverseerToggle!<cr>', mode = { 'n' }, desc = 'Show Results [rv]' },
      { '<leader>rC', '<cmd>OverseerClearCache<cr>', mode = { 'n' }, desc = 'Clear Cache [rC]' },
      { '<leader>rL', '<cmd>OverseerLoadBundle<cr>', mode = { 'n' }, desc = 'Load Task Bundle [rL]' },
      { '<leader>rS', '<cmd>OverseerSaveBundle<cr>', mode = { 'n' }, desc = 'Save Task Bundle [rS]' },
      { '<leader>rD', '<cmd>OverseerDeleteBundle<cr>', mode = { 'n' }, desc = 'Delete Task Bundle [rD]' },
      { '<leader>rq', '<cmd>OverseerQuickAction<cr>', mode = { 'n' }, desc = 'Task Quick Action [rq]' },
      { '<leader>rr', '<cmd>OverseerRun<cr>', mode = { 'n' }, desc = 'Run Task [rr]' },
      { '<leader>rc', '<cmd>OverseerRunCmd<cr>', mode = { 'n' }, desc = 'Run Cmd [rc]' },
      { '<leader>rt', '<cmd>OverseerTaskAction<cr>', mode = { 'n' }, desc = 'Task Action [rt]' },
      { '<leader>rI', '<cmd>OverseerInfo<cr>', mode = { 'n' }, desc = 'Task Runner Info [rI]' },
    },
    config = function()
      require('overseer').setup {
        -- Default task strategy
        strategy = 'terminal',
        -- Template modules to load
        templates = { 'builtin', 'user' },
        -- When true, tries to detect a green color from your colorscheme to use for success highlight
        auto_detect_success_color = true,
        -- Patch nvim-dap to support preLaunchTask and postDebugTask
        dap = true,
        -- Configure the task list
        task_list = {
          -- Default detail level for tasks. Can be 1-3.
          default_detail = 1,
          -- Width dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
          -- min_width and max_width can be a single value or a list of mixed integer/float types.
          -- max_width = {100, 0.2} means "the lesser of 100 columns or 20% of total"
          max_width = { 100, 0.2 },
          -- min_width = {40, 0.1} means "the greater of 40 columns or 10% of total"
          min_width = { 40, 0.1 },
          -- optionally define an integer/float for the exact width of the task list
          width = nil,
          max_height = { 20, 0.1 },
          min_height = 14,
          height = nil,
          -- String that separates tasks
          separator = '────────────────────────────────────────',
          -- Default direction. Can be "left", "right", or "bottom"
          direction = 'bottom',
          -- Set keymap to false to remove default behavior
          -- You can add custom keymaps here as well (anything vim.keymap.set accepts)
          bindings = {
            ['?'] = 'ShowHelp',
            ['g?'] = 'ShowHelp',
            ['<CR>'] = 'RunAction',
            ['<C-e>'] = 'Edit',
            ['o'] = 'Open',
            ['<C-v>'] = 'OpenVsplit',
            ['<C-s>'] = 'OpenSplit',
            ['<C-f>'] = 'OpenFloat',
            ['<C-q>'] = 'OpenQuickFix',
            ['p'] = 'TogglePreview',
            ['<C-l>'] = 'IncreaseDetail',
            ['<C-h>'] = 'DecreaseDetail',
            ['L'] = 'IncreaseAllDetail',
            ['H'] = 'DecreaseAllDetail',
            ['['] = 'DecreaseWidth',
            [']'] = 'IncreaseWidth',
            ['{'] = 'PrevTask',
            ['}'] = 'NextTask',
            ['<C-k>'] = 'ScrollOutputUp',
            ['<C-j>'] = 'ScrollOutputDown',
            ['q'] = 'Close',
          },
        },
        -- See :help overseer-actions
        actions = {},
        -- Configure the floating window used for task templates that require input
        -- and the floating window used for editing tasks
        form = {
          border = 'rounded',
          zindex = 40,
          -- Dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
          -- min_X and max_X can be a single value or a list of mixed integer/float types.
          min_width = 80,
          max_width = 0.9,
          width = nil,
          min_height = 10,
          max_height = 0.9,
          height = nil,
          -- Set any window options here (e.g. winhighlight)
          win_opts = {
            winblend = 10,
          },
        },
        task_launcher = {
          -- Set keymap to false to remove default behavior
          -- You can add custom keymaps here as well (anything vim.keymap.set accepts)
          bindings = {
            i = {
              ['<C-s>'] = 'Submit',
              ['<C-c>'] = 'Cancel',
            },
            n = {
              ['<CR>'] = 'Submit',
              ['<C-s>'] = 'Submit',
              ['q'] = 'Cancel',
              ['?'] = 'ShowHelp',
            },
          },
        },
        task_editor = {
          -- Set keymap to false to remove default behavior
          -- You can add custom keymaps here as well (anything vim.keymap.set accepts)
          bindings = {
            i = {
              ['<CR>'] = 'NextOrSubmit',
              ['<C-s>'] = 'Submit',
              ['<Tab>'] = 'Next',
              ['<S-Tab>'] = 'Prev',
              ['<C-c>'] = 'Cancel',
            },
            n = {
              ['<CR>'] = 'NextOrSubmit',
              ['<C-s>'] = 'Submit',
              ['<Tab>'] = 'Next',
              ['<S-Tab>'] = 'Prev',
              ['q'] = 'Cancel',
              ['?'] = 'ShowHelp',
            },
          },
        },
        -- Configure the floating window used for confirmation prompts
        confirm = {
          border = 'rounded',
          zindex = 40,
          -- Dimensions can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
          -- min_X and max_X can be a single value or a list of mixed integer/float types.
          min_width = 20,
          max_width = 0.5,
          width = nil,
          min_height = 6,
          max_height = 0.9,
          height = nil,
          -- Set any window options here (e.g. winhighlight)
          win_opts = {
            winblend = 10,
          },
        },
        -- Configuration for task floating windows
        task_win = {
          -- How much space to leave around the floating window
          padding = 2,
          border = 'rounded',
          -- Set any window options here (e.g. winhighlight)
          win_opts = {
            winblend = 10,
          },
        },
        -- Configuration for mapping help floating windows
        help_win = {
          border = 'rounded',
          win_opts = {},
        },
        -- Aliases for bundles of components. Redefine the builtins, or create your own.
        component_aliases = {
          -- Most tasks are initialized with the default components
          default = {
            { 'display_duration', detail_level = 2 },
            'on_output_summarize',
            'on_exit_set_status',
            'on_complete_notify',
            'on_complete_dispose',
          },
          -- Tasks from tasks.json use these components
          default_vscode = {
            'default',
            'on_result_diagnostics',
            'on_result_diagnostics_quickfix',
          },
          default_neotest = {
            { 'display_duration', detail_level = 2 },
            'on_output_summarize',
            'on_exit_set_status',
            'on_complete_notify',
            'on_complete_dispose',
          },
        },
        bundles = {
          -- When saving a bundle with OverseerSaveBundle or save_task_bundle(), filter the tasks with
          -- these options (passed to list_tasks())
          save_task_opts = {
            bundleable = true,
          },
          autostart_on_load = false,
        },
        -- A list of components to preload on setup.
        -- Only matters if you want them to show up in the task editor.
        preload_components = {},
        -- Controls when the parameter prompt is shown when running a template
        --   always    Show when template has any params
        --   missing   Show when template has any params not explicitly passed in
        --   allow     Only show when a required param is missing
        --   avoid     Only show when a required param with no default value is missing
        --   never     Never show prompt (error if required param missing)
        default_template_prompt = 'allow',
        -- For template providers, how long to wait (in ms) before timing out.
        -- Set to 0 to disable timeouts.
        template_timeout = 0,
        -- Cache template provider results if the provider takes longer than this to run.
        -- Time is in ms. Set to 0 to disable caching.
        template_cache_threshold = 100,
        -- Configure where the logs go and what level to use
        -- Types are "echo", "notify", and "file"
        log = {
          {
            type = 'echo',
            level = vim.log.levels.WARN,
          },
          {
            type = 'file',
            filename = 'overseer.log',
            level = vim.log.levels.WARN,
          },
        },
      }
      require('overseer').on_setup(function()
        local path = require 'plenary.path'

        local function parse_maven_phases(output)
          local lines = vim.split(output, '\n')
          local phases = {}
          for _, line in ipairs(lines) do
            local phase = line:match '^([^%s|]+)%s*|.*$'
            if phase and not phases[phase] and phase ~= 'PHASE' then
              phases[phase] = true
            end
          end
          return vim.tbl_keys(phases)
        end

        local function parse_maven_profiles(output)
          local lines = vim.split(output, '\n')
          local profiles = {}
          for _, line in ipairs(lines) do
            local profile_id, source = line:match 'Profile Id:%s+([^%s%(]+).-Source:%s+([^%s%)]+)'
            if profile_id and source == 'pom' then
              table.insert(profiles, profile_id)
            end
          end
          return profiles
        end

        local function create_file(file_path, content)
          vim.fn.writefile(vim.split(content, '\n'), file_path)
        end

        local function load_maven_data(project_root)
          local goals_file_path = project_root .. '/.mvn_goals'
          local goals_file = path:new(goals_file_path)

          -- TODO: make it async
          if not goals_file:exists() then
            require 'notify' 'Loading available maven goals'
            local co = coroutine.create(function()
              local buildplan_output = vim.fn.system 'mvn buildplan:list'
              local goals = parse_maven_phases(buildplan_output)
              local result = table.concat(goals, ',')
              create_file(goals_file_path, result)
              require 'notify' 'Finished loading maven goals'
            end)
            coroutine.resume(co)
          end

          local profiles_file_path = project_root .. '/.mvn_profiles'
          local profiles_file = path:new(profiles_file_path)

          if not profiles_file:exists() then
            require 'notify' 'Loading available maven profiles'
            local co = coroutine.create(function()
              local profiles_output = vim.fn.system 'mvn help:all-profiles'
              local profiles = parse_maven_profiles(profiles_output)
              local result = table.concat(profiles, ',')
              create_file(profiles_file_path, result)
              require 'notify' 'Finished loading maven profiles'
            end)
            coroutine.resume(co)
          end
        end

        local function is_pom_xml_present(project_root)
          return path:new(project_root .. '/pom.xml'):exists()
        end

        -- Load Maven data if pom.xml is present in the project workspace
        local cwd = vim.fn.getcwd()
        if is_pom_xml_present(cwd) then
          load_maven_data(cwd)
        end
      end)
    end,
  },
}
