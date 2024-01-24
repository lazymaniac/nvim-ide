return {
  name = 'Gradle Build',
  builder = function()
    return {
      cmd = { 'gradle' },
      args = { 'build' },
    }
  end,
  desc = 'gradle build',
}
