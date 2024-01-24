return {
  name = 'Gradle Run',
  builder = function()
    return {
      cmd = { 'gradle' },
      args = { 'run' },
    }
  end,
  desc = 'gradle run',
}
