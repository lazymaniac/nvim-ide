return {
  {

    -- [[ TASK RUNNERS ]] ---------------------------------------------------------------

    -- [overseer.nvim] - Async task runner.
    -- see: `:h overseer.nvim`
    -- link: https://github.com/stevearc/overseer.nvim
    'stevearc/overseer.nvim',
    branch = 'master',
    -- stylua: ignore
    keys = {
      { '<leader>rb', '<cmd>OverseerBuild<cr>',        mode = { 'n' }, desc = 'Create Task [rb]' },
      { '<leader>rv', '<cmd>OverseerToggle!<cr>',      mode = { 'n' }, desc = 'Show Results [rv]' },
      { '<leader>rC', '<cmd>OverseerClearCache<cr>',   mode = { 'n' }, desc = 'Clear Cache [rC]' },
      { '<leader>rL', '<cmd>OverseerLoadBundle<cr>',   mode = { 'n' }, desc = 'Load Task Bundle [rL]' },
      { '<leader>rS', '<cmd>OverseerSaveBundle<cr>',   mode = { 'n' }, desc = 'Save Task Bundle [rS]' },
      { '<leader>rD', '<cmd>OverseerDeleteBundle<cr>', mode = { 'n' }, desc = 'Delete Task Bundle [rD]' },
      { '<leader>rq', '<cmd>OverseerQuickAction<cr>',  mode = { 'n' }, desc = 'Task Quick Action [rq]' },
      { '<leader>rr', '<cmd>OverseerRun<cr>',          mode = { 'n' }, desc = 'Run Task [rr]' },
      { '<leader>rc', '<cmd>OverseerRunCmd<cr>',       mode = { 'n' }, desc = 'Run Cmd [rc]' },
      { '<leader>rt', '<cmd>OverseerTaskAction<cr>',   mode = { 'n' }, desc = 'Task Action [rt]' },
      { '<leader>rI', '<cmd>OverseerInfo<cr>',         mode = { 'n' }, desc = 'Task Runner Info [rI]' },
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
          min_width = 90,
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
            type = 'notify',
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
        local function find_directories_with_pom_xml()
          -- Use Neovim's globpath function to find pom.xml files in the current working directory and subdirectories
          local pomFiles = vim.fn.globpath(vim.fn.getcwd(), '**/pom.xml', false, true)
          local directories = {}
          for _, filePath in ipairs(pomFiles) do
            -- Extract the directory part of each file path
            local dir = vim.fn.fnamemodify(filePath, ':h')
            -- Check if the directory should be excluded
            if not string.find(dir, '/src') and not string.find(dir, '/target') then
              directories[dir] = true
            end
          end
          local dirList = vim.tbl_keys(directories)
          -- Sort the list of directories
          table.sort(dirList)
          return dirList
        end
        local function parse_maven_phases(output)
          local phases = {}
          for line in output:gmatch '([^\n]+)' do
            local phase = line:match '^([^%s|]+)%s*|.*$'
            if phase and not phases[phase] and phase ~= 'PHASE' then
              phases[phase] = true
            end
          end
          return vim.tbl_keys(phases)
        end
        local function parse_maven_profiles(output)
          local profiles = {}
          for line in output:gmatch '([^\n]+)' do
            local profile_id, source = line:match 'Profile Id:%s+([^%s%(]+).-Source:%s+([^%s%)]+)'
            if profile_id and source == 'pom' then
              profiles[profile_id] = true
            end
          end
          return vim.tbl_keys(profiles)
        end
        local function create_file(file_path, content)
          vim.fn.writefile(vim.split(content, '\n'), file_path)
        end
        -- Function to run a shell command in the background
        local function run_command_in_background(cmd, callback)
          local output = {}
          local job_id
          local on_stdout = function(_, data)
            if data then
              for _, line in ipairs(data) do
                if line ~= '' then -- Ignore empty strings (last data event)
                  table.insert(output, line)
                end
              end
            end
          end
          local on_exit = function(_, code)
            if code == 0 then
              callback(table.concat(output, '\n'))
            else
              print('Command failed with exit code', code)
            end
          end
          -- Start the job
          job_id = vim.fn.jobstart(cmd, {
            on_stdout = on_stdout,
            on_exit = on_exit,
            stdout_buffered = true,
          })
          if job_id == 0 then
            print 'Failed to run mvn command: Not executable'
          elseif job_id == -1 then
            print 'Failed to run mvn command: Invalid arguments'
          end
        end
        local function load_goals(project_root)
          local goals_file_path = project_root .. '/.mvn_goals'
          local goals_file = path:new(goals_file_path)
          if not goals_file:exists() then
            run_command_in_background('mvn buildplan:list', function(buildplan_output)
              require 'notify' 'Loading available maven goals'
              local goals = parse_maven_phases(buildplan_output)
              local result = table.concat(goals, ',')
              create_file(goals_file_path, result)
              require 'notify' 'Finished loading maven goals'
            end)
          end
        end
        local function load_profles(project_root)
          local profiles_file_path = project_root .. '/.mvn_profiles'
          local profiles_file = path:new(profiles_file_path)
          if not profiles_file:exists() then
            run_command_in_background('mvn help:all-profiles', function(profiles_output)
              require 'notify' 'Loading available maven profiles'
              local profiles = parse_maven_profiles(profiles_output)
              local result = table.concat(profiles, ',')
              create_file(profiles_file_path, result)
              require 'notify' 'Finished loading maven profiles'
            end)
          end
        end
        local function load_maven_data(project_root)
          load_goals(project_root)
          load_profles(project_root)
        end
        local function is_pom_xml_in_cwd(project_root)
          return path:new(project_root .. '/pom.xml'):exists()
        end
        local cwd = vim.fn.getcwd()
        if is_pom_xml_in_cwd(cwd) then
          local pom_dirs = find_directories_with_pom_xml()
          for _, dir in ipairs(pom_dirs) do
            load_maven_data(dir)
          end
        end
      end)
    end,
  },
}
