return {
  name = 'Gradle Tasks',
  builder = function()
    return {
      cmd = { 'gradle' },
      args = { 'tasks' },
    }
  end,
  desc = 'gradle tasks',
}
