return {
  name = 'Gradle Tasks',
  builder = function()
    return {
      cmd = { './gradlew' },
      args = { 'tasks' },
    }
  end,
  desc = './gradlew tasks',
}
