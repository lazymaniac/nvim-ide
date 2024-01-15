return {
  name = 'Maven Clean Install',
  builder = function()
    return {
      cmd = { 'mvn' },
      args = { 'clean', 'install' },
    }
  end,
  condition = {
    filetype = { "java" },
  },
}
