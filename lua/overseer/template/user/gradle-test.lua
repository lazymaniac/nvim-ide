return {
  name = 'Gradle Test',
  builder = function()
    return {
      cmd = { 'gradle' },
      args = { 'test' },
    }
  end,
  desc = 'gradle test',
}
