return {
  name = 'Maven Clean Install',
  builder = function()
    -- Full path to current file (see :help expand())
    return {
      cmd = { 'mvn' },
      args = { 'clean', 'install' },
    }
  end,
  condition = {
    filetype = { "java" },
  },
}
