return {
  name = 'Compose Up',
  builder = function()
    return {
      cmd = { 'docker-compose' },
      args = { 'up', '-d' },
    }
  end,
  desc = 'docker-compose up -d',
}
