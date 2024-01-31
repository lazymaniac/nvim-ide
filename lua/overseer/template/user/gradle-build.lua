return {
  name = 'Gradle Build',
  builder = function()
    return {
      cmd = { './gradlew' },
      args = { 'build' },
    }
  end,
  desc = './gradlew build',
}
