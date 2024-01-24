return {
  name = 'Compose Stop',
  builder = function()
    return {
      cmd = { 'docker-compose' },
      args = { 'stop' },
    }
  end,
  desc = 'docker-compose stop',
}
