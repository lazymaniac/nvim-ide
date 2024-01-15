return {
  name = 'Maven Clean Install Skip Tests',
  builder = function()
    return {
      cmd = { 'mvn' },
      args = { 'clean', 'install', '-Ddisable.tests=true', '-Dskip.tests' },
    }
  end,
  condition = {
    filetype = { "java" },
  },
}
