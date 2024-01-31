return {
  name = 'Gradle Run',
  builder = function()
    return {
      cmd = { './gradlew' },
      args = { 'run' },
    }
  end,
  desc = './gradlew run',
}
