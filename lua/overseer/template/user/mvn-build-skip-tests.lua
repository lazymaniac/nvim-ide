return {
  name = 'Maven Build No Tests',
  builder = function()
    return {
      cmd = { 'mvn' },
      args = { 'clean', 'install', '-Ddisable.tests=true', '-Dskip.tests' },
    }
  end,
  desc = 'clean install -Ddisable.tests=true -Dskip.tests',
}
