return {
  name = 'Docker Compose',
  params = {
    file = {
      type = 'string',
      desc = 'Name of docker-compose file. Empty means docker-compose.yml',
      order = 1,
    },
    task = {
      type = 'string',
      desc = 'Action',
      subtype = {
        type = 'enum',
        choices = { 'build', 'create', 'down', 'images', 'kill', 'logs', 'pause', 'ps', 'pull', 'restart', 'rm', 'start', 'stop', 'top', 'unpause', 'up' },
      },
      order = 2,
    },
    detached = {
      type = 'boolean',
      desc = 'Run as detached?',
      default = true,
      order = 3,
    },
    extra_params = {
      type = 'string',
      desc = 'Add extra parameter(s)',
      optional = true,
      order = 4,
    },
  },
  builder = function(params)
    local args = {}

    if params.file then
      table.insert(args, '-f')
      table.insert(args, params.file)
    end

    if params.task then
      table.insert(args, params.task)
    end

    if params.detached and params.task == 'up' and params.task == 'start' then
      table.insert(args, '-d')
    end

    if params.extra_params then
      table.insert(args, params.extra_params)
    end

    return {
      cmd = 'docker-compose',
      args = args,
    }
  end,
  priority = 40,
}
