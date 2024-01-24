return {
  name = 'Compose Kill',
  builder = function()
    return {
      cmd = { 'docker-compose' },
      args = { 'kill' },
    }
  end,
  desc = 'docker-compose kill',
}
