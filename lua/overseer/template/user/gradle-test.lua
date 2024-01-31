return {
  name = 'Gradle Test',
  builder = function()
    return {
      cmd = { './gradlew' },
      args = { 'test' },
    }
  end,
  desc = './gradle test',
}
